# functions/ia_module/logic.py

import os
import json
import logging
from datetime import datetime, timedelta
from firebase_admin import firestore
from google.cloud import secretmanager
from langchain_google_genai import ChatGoogleGenerativeAI

# Imports dos módulos locais
from .prompt_builder import create_evaluation_prompt, create_cycle_prompt
from .models import get_parser, get_cycle_parser

SECRET_ID = 'GEMINI_API_KEY'
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")

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


def run_cycle_analysis(db, current_workout, api_key):
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
        
        # Filtro: >= 01/Mês E < 01/Próximo Mês
        docs = exercises_ref.where("dataTreinoIso", ">=", start_date_str)\
                            .where("dataTreinoIso", "<", end_date_str)\
                            .stream()
        
        month_workouts = []
        current_id = current_workout.get('id') 

        for doc in docs:
            # Proteção contra duplicidade
            if current_id and doc.id == current_id:
                continue
            month_workouts.append(doc.to_dict())

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
            month_name=current_month_key
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
        workout_ref.update({"statusAnalise": "processando"})
        
        # Busca histórico (últimos 15) para a análise diária
        history_docs = (
            firestore_client.collection("exercises")
            .order_by("dataTreinoIso", direction=firestore.Query.DESCENDING)
            .limit(15)
            .stream()
        )
        past_workouts = [d.to_dict() for d in history_docs if d.id != workout_id]

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
        prompt_text = create_evaluation_prompt(current_data, past_workouts, exercise_db)
        
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
            "analisadoEm": firestore.SERVER_TIMESTAMP
        })
        logging.info(f"Sucesso! Treino {workout_id} analisado (Micro).")

        # -------------------------------------------------------------
        # 5. Análise de CICLO (Macro) - CHAMADA DA NOVA FUNÇÃO
        # -------------------------------------------------------------
        logging.info("Iniciando atualização do Ciclo Mensal...")
        
        # Injetamos o ID no objeto para garantir que a proteção de duplicidade funcione
        # (caso o doc do firestore ainda não tenha o ID salvo dentro dos campos)
        current_data_for_cycle = current_data.copy()
        current_data_for_cycle['id'] = workout_id
        
        # Passamos a API Key que já pegamos lá em cima
        run_cycle_analysis(firestore_client, current_data_for_cycle, api_key)
        
        logging.info("Ciclo Mensal atualizado com sucesso.")
        # -------------------------------------------------------------

    except Exception as e:
        logging.error(f"Erro na análise do treino {workout_id}: {e}")
        workout_ref.update({
            "statusAnalise": "erro", 
            "erroMsg": str(e)
        })