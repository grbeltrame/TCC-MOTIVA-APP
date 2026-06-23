# functions/ia_module/logic.py

import os
import json
import logging
import statistics
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore
from google.cloud import secretmanager
from langchain_google_genai import ChatGoogleGenerativeAI

# Imports dos módulos locais
from .prompt_builder import create_evaluation_prompt, create_cycle_prompt
from .models import get_parser, get_cycle_parser

SECRET_ID = 'GEMINI_API_KEY'
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")

_TZ_BRAZIL = ZoneInfo('America/Sao_Paulo')


def _current_week_label() -> str:
    """
    Gera o label 'YYYY-Www' da semana atual seguindo a MESMA convenção
    usada em athlete_stats_module.logic (semana domingo→sábado).
    """
    now = datetime.now(tz=_TZ_BRAZIL)
    days_since_sunday = (now.weekday() + 1) % 7
    week_start = (now - timedelta(days=days_since_sunday)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    year = week_start.year
    jan1 = datetime(year, 1, 1, tzinfo=week_start.tzinfo)
    days_to_first_sunday = (6 - jan1.weekday()) % 7
    first_sunday = jan1 + timedelta(days=days_to_first_sunday)
    if week_start < first_sunday:
        # pertence ao ano anterior
        prev_year = year - 1
        jan1_prev = datetime(prev_year, 1, 1, tzinfo=week_start.tzinfo)
        days_prev = (6 - jan1_prev.weekday()) % 7
        first_sunday_prev = jan1_prev + timedelta(days=days_prev)
        week_num = ((week_start - first_sunday_prev).days // 7) + 1
        return f'{prev_year}-W{week_num:02d}'
    week_num = ((week_start - first_sunday).days // 7) + 1
    return f'{year}-W{week_num:02d}'


def _compute_class_context(db) -> dict:
    """
    Agrega as médias da turma (todos os atletas registrados) para a semana
    corrente, usando os documentos users/{uid}/weekly_load/{currentWeekLabel}.

    Retorna um dict no formato:
        {
          'weekLabel': '2026-W16',
          'athletesCount': int,
          'averageEffortCurrentWeek': float,   # média de avgRpeAll
          'averageMonotony': float,
          'averageIcnAll': float,
          'wodVsAlternativeRatio': float,      # wodDays / (wodDays+otherDays+restDays)
        }

    Se não há dados, retorna dict vazio — o prompt trata como "sem contexto".
    """
    try:
        week_label = _current_week_label()
        # collection_group permite varrer todos users/*/weekly_load/{label}
        docs = list(
            db.collection_group('weekly_load')
              .where('weekLabel', '==', week_label)
              .stream()
        )
        if not docs:
            return {}

        efforts = []
        monotonies = []
        icns = []
        wod_days = 0
        other_days = 0
        rest_days = 0

        for d in docs:
            data = d.to_dict() or {}
            if data.get('avgRpeAll'):
                efforts.append(float(data['avgRpeAll']))
            mono = data.get('monotony')
            if mono is not None and mono > 0:
                monotonies.append(float(mono))
            icn = data.get('icnAll')
            if icn is not None:
                icns.append(float(icn))
            wod_days += int(data.get('wodDays', 0) or 0)
            other_days += int(data.get('otherDays', 0) or 0)
            rest_days += int(data.get('restDays', 0) or 0)

        total_days = wod_days + other_days + rest_days
        ratio = round(wod_days / total_days, 2) if total_days > 0 else None

        return {
            'weekLabel': week_label,
            'athletesCount': len(docs),
            'averageEffortCurrentWeek': round(statistics.mean(efforts), 2) if efforts else None,
            'averageMonotony': round(statistics.mean(monotonies), 2) if monotonies else None,
            'averageIcnAll': round(statistics.mean(icns), 1) if icns else None,
            'wodVsAlternativeRatio': ratio,
            'totals': {
                'wodDays': wod_days,
                'otherDays': other_days,
                'restDays': rest_days,
            },
        }
    except Exception as e:
        logging.warning(f"Falha ao calcular class_context: {e}")
        return {}

def get_gemini_api_key() -> str:
    """Busca a API Key no Secret Manager."""
    try:
        if not PROJECT_ID:
            config = os.environ.get("FIREBASE_CONFIG")
            if config:
                proj_id = json.loads(config).get("projectId")
                if proj_id:
                    name = f"projects/{proj_id}/secrets/{SECRET_ID}/versions/latest"
            else:
                raise ValueError("PROJECT_ID não encontrado.")
        else:
            name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"

        client = secretmanager.SecretManagerServiceClient()
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        logging.error(f"Erro ao buscar API Key: {e}")
        raise e


def run_cycle_analysis(db, current_workout, api_key, class_context=None):
    """
    Executa a análise Macro (Ciclo Mensal) e salva no Firestore.
    """
    try:
        # 1. Configurar datas
        date_iso = current_workout.get('dataTreinoIso')

        if not date_iso:
            date_iso = datetime.now().isoformat()

        # Converte string ISO para objeto datetime
        try:
            # Remove o Z se existir para facilitar o parse
            date_obj = datetime.fromisoformat(date_iso.replace("Z", "+00:00"))
        except ValueError:
            # Fallback para YYYY-MM-DD
            date_obj = datetime.strptime(date_iso[:10], "%Y-%m-%d")

        # Identificadores (Keys)
        current_month_key = f"{date_obj.month:02d}-{date_obj.year}" # Ex: 02-2026

        # Calcular Mês Anterior
        first_day_current = date_obj.replace(day=1)
        last_day_prev = first_day_current - timedelta(days=1)
        prev_month_key = f"{last_day_prev.month:02d}-{last_day_prev.year}" # Ex: 01-2026

        # Calcular Limites para Query (Inicio do mes atual até inicio do proximo)
        start_date_str = first_day_current.strftime("%Y-%m-%d")
        next_month_date = (first_day_current + timedelta(days=32)).replace(day=1)
        end_date_str = next_month_date.strftime("%Y-%m-%d")

        # 2. Buscar Treinos do Mês Atual
        exercises_ref = db.collection("exercises")

        # Filtro por data apenas; status é filtrado em memória para evitar
        # exigir índice composto na Cloud Function.
        docs = exercises_ref.where("dataTreinoIso", ">=", start_date_str)\
                            .where("dataTreinoIso", "<", end_date_str)\
                            .stream()

        month_workouts = []
        current_id = current_workout.get('id')

        for doc in docs:
            # Proteção contra duplicidade
            if current_id and doc.id == current_id:
                continue
            data = doc.to_dict()
            if data.get("status") == "publicado":
                month_workouts.append(data)

        # Adiciona o treino atual (garantido na memória)
        month_workouts.append(current_workout)

        # -----------------------------------------------------------------
        # 3. NOVA LÓGICA: MATEMÁTICA EM PYTHON (ESTATÍSTICAS DO CICLO)
        # -----------------------------------------------------------------
        trainings_count = len(month_workouts)
        type_counts = {}
        stimulus_counts = {}

        for w in month_workouts:
            # A. Contagem de Tipos de Treino (WOD, LPO, GINÁSTICA, etc)
            partes = w.get("partes", {})
            for key in partes.keys():
                k_upper = key.upper()
                if "WOD" in k_upper:
                    type_counts["WODs"] = type_counts.get("WODs", 0) + 1
                elif "LPO" in k_upper:
                    type_counts["LPO"] = type_counts.get("LPO", 0) + 1
                elif "GYM" in k_upper or "GINASTICA" in k_upper or "GINÁSTICA" in k_upper:
                    type_counts["Ginástica"] = type_counts.get("Ginástica", 0) + 1
                elif "ENDURANCE" in k_upper or "CARDIO" in k_upper:
                    type_counts["Endurance"] = type_counts.get("Endurance", 0) + 1

            # B. Contagem de Estímulos (puxando as key_metrics da análise diária já gerada pela IA)
            analise = w.get("analise", {})
            summary = analise.get("summary", {})
            key_metrics = summary.get("key_metrics", [])

            for metric in key_metrics:
                m_cap = str(metric).strip().title() # Formata bonitinho: Ex: "Força", "Potência"
                stimulus_counts[m_cap] = stimulus_counts.get(m_cap, 0) + 1

        # Prepara a lista de tipos de treino no formato exato que o Flutter espera
        training_types_list = []
        for t_label, count in type_counts.items():
            training_types_list.append({
                "typeLabel": t_label,
                "typeKey": t_label.lower(), # ex: "wods", "lpo"
                "count": count
            })

        # Prepara a lista do Gráfico de Pizza (Estímulos) para o Flutter
        stimulus_list = []
        biggest_stimulus_label = "Equilibrado"
        max_stim_count = 0

        for s_label, count in stimulus_counts.items():
            stimulus_list.append({
                "stimulus": s_label,
                "count": count
            })
            if count > max_stim_count:
                max_stim_count = count
                biggest_stimulus_label = s_label # Descobre qual foi o estímulo mais frequente

        # -----------------------------------------------------------------
        # 4. Buscar Análise do Ciclo Anterior
        # -----------------------------------------------------------------
        prev_cycle_ref = db.collection("cycles").document(prev_month_key)
        prev_cycle_doc = prev_cycle_ref.get()
        prev_cycle_data = prev_cycle_doc.to_dict() if prev_cycle_doc.exists else None

        # -----------------------------------------------------------------
        # 5. Gerar Prompt e Chamar IA
        # -----------------------------------------------------------------
        logging.info(f"Gerando análise de ciclo ({current_month_key}) com {trainings_count} treinos.")

        prompt_text = create_cycle_prompt(
            month_workouts=month_workouts,
            previous_cycle_data=prev_cycle_data,
            month_name=current_month_key,
            class_context=class_context or {},
        )

        # Usando a API Key passada como argumento
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.2
        )

        cycle_parser = get_cycle_parser()
        chain = llm | cycle_parser

        result = chain.invoke(prompt_text)
        cycle_ai_data = result.dict() # Converte a resposta estruturada em dicionário

        # -----------------------------------------------------------------
        # 6. Mesclar Dados (Python + IA) e Salvar no Firestore
        # -----------------------------------------------------------------
        final_document = {
            **cycle_ai_data, # Espalha todos os dados gerados pela IA (overview, quick_alerts, etc)

            # Dados processados pelo Python, mastigados para o Dashboard no Flutter
            "overview_stats": {
                "updatedAt": datetime.now().isoformat(),
                "trainingsCount": trainings_count,
                "registrosCount": 0,      # WIP (Em breve)
                "activeStudentsPct": 0    # WIP (Em breve)
            },
            "trainingTypes": training_types_list,
            "stimulus": stimulus_list,
            "biggestStimulusLabel": biggest_stimulus_label
        }

        cycle_ref = db.collection("cycles").document(current_month_key)
        cycle_ref.set(final_document)

        try:
            from notification_module import notify_all_coaches
            notify_all_coaches(
                db=db,
                type_="coach_cycle_analysis_ready",
                title="Análise de ciclo pronta",
                body="A análise inteligente do ciclo foi atualizada.",
                dedupe_key=f"coach-cycle-analysis:{current_month_key}",
                route_name="/coach_training_insights",
                route_args={"monthKey": current_month_key},
                source_id=current_month_key,
            )
        except Exception as notify_error:
            logging.warning(
                f"Falha ao notificar coaches sobre ciclo {current_month_key}: "
                f"{notify_error}"
            )

        return final_document

    except Exception as e:
        logging.error(f"Erro CRÍTICO na análise de ciclo: {e}")
        # Retorna erro mas não para a execução principal
        return {"error": str(e)}


def run_ai_analysis_logic(event):
    """
    Função principal orquestradora.
    """
    firestore_client = firestore.client()

    # 1. Obter o documento atual
    document_snapshot = event.data.after
    if not document_snapshot:
        logging.info("Documento foi deletado. Nada a fazer.")
        return

    workout_id = event.params.get('workoutId')
    if not workout_id:
        workout_id = event.document.split("/")[-1]

    logging.info(f"Iniciando checagem para treino: {workout_id}")

    current_data = document_snapshot.to_dict() or {}

    if current_data.get('status') != 'publicado':
        logging.info(f"Treino {workout_id} ignorado (não publicado).")
        return

    # 2. Validações iniciais
    status = current_data.get('statusAnalise')
    if status in ['concluida', 'processando', 'erro']:
        logging.info(f"Treino {workout_id} ignorado (Status: {status})")
        return

    if not current_data.get('partes'):
        logging.info("Aguardando o processamento do PDF terminar.")
        return

    # Referência para atualizar o status
    workout_ref = firestore_client.collection("exercises").document(workout_id)

    try:
        # Marca como processando
        workout_ref.update({
            "statusAnalise": "processando",
            "erroMsg": firestore.DELETE_FIELD,
        })

        # Busca histórico (últimos 15) para a análise diária
        history_docs = (
            firestore_client.collection("exercises")
            .order_by("dataTreinoIso", direction=firestore.Query.DESCENDING)
            .limit(30)
            .stream()
        )
        past_workouts = []
        for d in history_docs:
            if d.id == workout_id:
                continue
            data = d.to_dict()
            if data.get("status") == "publicado":
                past_workouts.append(data)
            if len(past_workouts) >= 15:
                break

        # 3. Base de exercícios (Movimentos)
        exercises_ref = firestore_client.collection("movimentos")
        all_exercises_docs = exercises_ref.stream()

        exercise_db = []
        for doc in all_exercises_docs:
            d = doc.to_dict()
            exercise_db.append({
                "nome": d.get("displayName", d.get("name", "Sem Nome")),
                "equipamento": d.get("equipment", []),
                "musculos": d.get("primaryMuscles", []),
                "categoria": d.get("categories", [])
            })

        logging.info(f"Base de conhecimento: {len(exercise_db)} exercícios carregados.")

        # 4. Análise DIÁRIA (Micro)
        # Calcula o contexto da turma (médias da semana corrente em todos os atletas)
        class_context = _compute_class_context(firestore_client)
        logging.info(f"class_context: {class_context}")

        prompt_text = create_evaluation_prompt(
            current_data,
            past_workouts,
            exercise_db,
            class_context=class_context,
        )

        # Pega a API Key uma única vez
        api_key = get_gemini_api_key()

        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.2
        )

        logging.info("Enviando prompt diário para o Gemini...")
        ai_message = llm.invoke(prompt_text)
        raw_output = ai_message.content

        # Limpeza do JSON
        clean_output = raw_output
        if "```json" in raw_output:
            clean_output = raw_output.split("```json")[1].split("```")[0].strip()
        elif "```" in raw_output:
            clean_output = raw_output.split("```")[1].strip()

        parser = get_parser()
        structured_analysis = parser.parse(clean_output).dict()

        # Salva Análise Diária
        workout_ref.update({
            "analise": structured_analysis,
            "statusAnalise": "concluida",
            "analisadoEm": firestore.SERVER_TIMESTAMP,
            "erroMsg": firestore.DELETE_FIELD,
        })
        logging.info(f"Sucesso! Treino {workout_id} analisado (Micro).")

        try:
            from notification_module import notify_all_coaches
            notify_all_coaches(
                db=firestore_client,
                type_="coach_daily_analysis_ready",
                title="Análise do treino pronta",
                body="A análise inteligente do treino cadastrado foi finalizada.",
                dedupe_key=f"coach-daily-analysis:{workout_id}",
                route_name="/coach_insights",
                route_args={
                    "trainingId": workout_id,
                    "dateIso": current_data.get("dataTreinoIso"),
                },
                source_id=workout_id,
            )
        except Exception as notify_error:
            logging.warning(
                f"Falha ao notificar coaches sobre treino {workout_id}: "
                f"{notify_error}"
            )

        # -------------------------------------------------------------
        # 5. Análise de CICLO (Macro) - CHAMADA DA NOVA FUNÇÃO
        # -------------------------------------------------------------
        logging.info("Iniciando atualização do Ciclo Mensal...")

        # Injetamos o ID no objeto para garantir que a proteção de duplicidade funcione
        # (caso o doc do firestore ainda não tenha o ID salvo dentro dos campos)
        current_data_for_cycle = current_data.copy()
        current_data_for_cycle['id'] = workout_id

        # Passamos a API Key que já pegamos lá em cima + reaproveitamos o class_context
        run_cycle_analysis(
            firestore_client,
            current_data_for_cycle,
            api_key,
            class_context=class_context,
        )

        logging.info("Ciclo Mensal atualizado com sucesso.")
        # -------------------------------------------------------------

    except Exception as e:
        logging.error(f"Erro na análise do treino {workout_id}: {e}")
        workout_ref.update({
            "statusAnalise": "erro",
            "erroMsg": str(e)
        })
