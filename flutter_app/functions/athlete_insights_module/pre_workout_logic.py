# functions/athlete_insights_module/pre_workout_logic.py
#
# Geração de insights PRÉ-TREINO para todos os atletas elegíveis quando o
# coach publica/atualiza um treino em exercises/{workoutId}.
#
# Disparada por trigger Firestore. Usa hash do conteúdo relevante para
# evitar regeneração desnecessária — só roda se a estrutura do treino
# realmente mudou em relação ao último processamento.

from __future__ import annotations

import hashlib
import json
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore

from .prompt_builder import create_pre_workout_insights_prompt
from .models import get_pre_workout_parser

_TZ_BRAZIL = ZoneInfo("America/Sao_Paulo")

# Quantos treinos do mesmo tipo o atleta precisa ter para receber insights
# baseados em padrão histórico (abaixo disso, IA deve evitar generalizações).
_MIN_HISTORY_FOR_PATTERN = 5

# Limite superior de quantos treinos do mesmo tipo entram no prompt.
_MAX_HISTORY_ITEMS = 10

# Janela de PRs recentes considerada (semanas).
_RECENT_PR_WEEKS = 8

# Campos do treino cuja alteração JUSTIFICA regerar insights.
_HASH_FIELDS = ('partes', 'modalidade', 'wodType', 'keyMetrics', 'dataTreinoIso')


def _compute_workout_hash(workout: dict) -> str:
    """Hash determinístico dos campos relevantes do treino."""
    relevant = {k: workout.get(k) for k in _HASH_FIELDS}
    serialized = json.dumps(relevant, sort_keys=True, default=str, ensure_ascii=False)
    return hashlib.md5(serialized.encode('utf-8')).hexdigest()


def _extract_workout_summary(workout: dict) -> dict:
    """Extrai os campos do treino que vão para o prompt (sem ruído)."""
    partes = workout.get('partes') or {}
    return {
        'workoutId':     workout.get('id') or workout.get('workoutId'),
        'wodType':       workout.get('wodType'),
        'modalidade':    workout.get('modalidade'),
        'duracaoMinutos': workout.get('duracaoMinutos'),
        'keyMetrics':    workout.get('keyMetrics') or [],
        'dataTreinoIso': workout.get('dataTreinoIso'),
        'partes':        partes,
        'titulo':        workout.get('titulo') or workout.get('title'),
    }


def _is_athlete_user(user_doc, db) -> bool:
    """
    Atleta é usuário com doc em users/{uid}/profiles/athlete.
    """
    try:
        prof_ref = db.collection('users').document(user_doc.id) \
                     .collection('profiles').document('athlete')
        return prof_ref.get().exists
    except Exception:
        return False


def _fetch_athlete_history_same_type(
    db, uid: str, workout_summary: dict
) -> list:
    """
    Retorna até _MAX_HISTORY_ITEMS resultados do atleta no MESMO
    wodType OU mesma modalidade, ordenados desc por data.
    """
    target_wod_type   = (workout_summary.get('wodType') or '').strip().upper()
    target_modalidade = (workout_summary.get('modalidade') or '').strip().upper()

    if not target_wod_type and not target_modalidade:
        return []

    try:
        results_ref = db.collection('users').document(uid).collection('results')
        # Não dá pra fazer OR no Firestore — busca os mais recentes e filtra.
        recent = list(
            results_ref.order_by('date', direction=firestore.Query.DESCENDING)
                       .limit(60)
                       .stream()
        )
        matches = []
        for doc in recent:
            data = doc.to_dict() or {}
            wt   = (data.get('wodType')    or '').strip().upper()
            md   = (data.get('modalidade') or '').strip().upper()
            if (target_wod_type   and wt == target_wod_type) or \
               (target_modalidade and md == target_modalidade):
                matches.append({
                    'date':         data.get('date'),
                    'effort':       data.get('effort'),
                    'modalidade':   data.get('modalidade'),
                    'wodType':      data.get('wodType'),
                    'completed':    data.get('completed'),
                    'forTimeSec':   data.get('forTimeSec'),
                    'amrapRounds':  data.get('amrapRounds'),
                    'amrapReps':    data.get('amrapReps'),
                    'keyMetrics':   data.get('keyMetrics'),
                    'trainingTime': data.get('trainingTime'),
                })
                if len(matches) >= _MAX_HISTORY_ITEMS:
                    break
        return matches
    except Exception as e:
        logging.warning(f'[pre-workout] {uid} — falha ao buscar histórico: {e}')
        return []


def _fetch_athlete_current_load(db, uid: str) -> dict:
    """Lê o weekly_load atual do atleta via stats/summary.weeklyLoadLabel."""
    try:
        stats_ref = db.collection('users').document(uid) \
                      .collection('stats').document('summary')
        stats_doc = stats_ref.get()
        if not stats_doc.exists:
            return {}
        summary = stats_doc.to_dict() or {}
        label = summary.get('weeklyLoadLabel')
        if not label:
            return {}
        wl_doc = db.collection('users').document(uid) \
                   .collection('weekly_load').document(label).get()
        return wl_doc.to_dict() or {} if wl_doc.exists else {}
    except Exception as e:
        logging.warning(f'[pre-workout] {uid} — falha ao buscar carga atual: {e}')
        return {}


def _fetch_athlete_recent_prs(db, uid: str) -> list:
    """PRs do atleta nas últimas _RECENT_PR_WEEKS semanas."""
    try:
        cutoff = datetime.now(tz=_TZ_BRAZIL) - timedelta(weeks=_RECENT_PR_WEEKS)
        prs_ref = db.collection('users').document(uid).collection('prs')
        all_prs = list(prs_ref.stream())
        recent = []
        for d in all_prs:
            data = d.to_dict() or {}
            pr_date = data.get('date')
            if pr_date is None:
                continue
            # date pode ser Timestamp ou string ISO
            if isinstance(pr_date, str):
                try:
                    pr_dt = datetime.strptime(pr_date[:10], '%Y-%m-%d') \
                                    .replace(tzinfo=_TZ_BRAZIL)
                except ValueError:
                    continue
            else:
                pr_dt = pr_date
                if pr_dt.tzinfo is None:
                    pr_dt = pr_dt.replace(tzinfo=_TZ_BRAZIL)
            if pr_dt >= cutoff:
                recent.append({
                    'date':         data.get('date'),
                    'movementName': data.get('movementName'),
                    'value':        data.get('value'),
                    'unit':         data.get('unit'),
                    'prType':       data.get('prType'),
                })
        # Mais recente primeiro
        recent.sort(key=lambda x: str(x.get('date') or ''), reverse=True)
        return recent[:10]
    except Exception as e:
        logging.warning(f'[pre-workout] {uid} — falha ao buscar PRs: {e}')
        return []


def _fetch_athlete_profile(db, uid: str) -> dict:
    """Lê users/{uid}/profiles/athlete (campos que não revelam identidade)."""
    try:
        prof_ref = db.collection('users').document(uid) \
                     .collection('profiles').document('athlete')
        prof_doc = prof_ref.get()
        if not prof_doc.exists:
            return {}
        data = prof_doc.to_dict() or {}
        return {
            'category':      data.get('category'),
            'gender':        data.get('gender'),
            'practiceYears': data.get('practiceYears'),
            'weight':        data.get('weight'),
            'height':        data.get('height'),
        }
    except Exception:
        return {}


def _generate_insights_for_athlete(
    db, uid: str, workout_summary: dict, workout_hash: str, llm,
) -> dict:
    """
    Gera o doc de insights pré-treino para um atleta. Retorna o resultado
    final (dict que vai para o Firestore) ou {} se falhou.
    """
    history = _fetch_athlete_history_same_type(db, uid, workout_summary)

    # Skip se atleta não tem dados próprios suficientes — sem histórico no
    # tipo e sem carga atual, IA só faria insights genéricos sem valor.
    current_load = _fetch_athlete_current_load(db, uid)
    if not history and not current_load:
        logging.info(f'[pre-workout] {uid}: sem dados — pulando.')
        return {}

    profile     = _fetch_athlete_profile(db, uid)
    recent_prs  = _fetch_athlete_recent_prs(db, uid)

    # Coorte (se elegível) — pode estar None pra atletas sem perfil completo.
    cohort = None
    try:
        from cohort_module import find_athlete_cohort
        cohort = find_athlete_cohort(uid, db)
    except Exception as e:
        logging.warning(f'[pre-workout] {uid}: cohort lookup falhou: {e}')

    prompt = create_pre_workout_insights_prompt(
        workout=workout_summary,
        athlete_profile=profile,
        athlete_history_same_type=history,
        athlete_current_load=current_load,
        athlete_recent_prs=recent_prs,
        now=datetime.now(tz=_TZ_BRAZIL),
        cohort=cohort,
    )

    parser = get_pre_workout_parser()

    try:
        ai_message = llm.invoke(prompt)
        raw = ai_message.content
        if "```json" in raw:
            raw = raw.split("```json")[1].split("```")[0].strip()
        elif "```" in raw:
            raw = raw.split("```")[1].strip()
        parsed = parser.parse(raw).dict()
    except Exception as e:
        logging.error(f'[pre-workout] {uid}: falha do LLM: {e}')
        return {}

    # Telemetria por atleta gerado.
    try:
        from telemetry_module import record_insight_generated
        record_insight_generated(
            'preWorkout',
            with_cohort=cohort is not None,
            prompt_chars=len(prompt),
            response_chars=len(ai_message.content or ''),
        )
    except Exception:
        pass

    return {
        **parsed,
        'workoutId':       workout_summary.get('workoutId'),
        'workoutHash':     workout_hash,
        'historySize':     len(history),
        'hasPattern':      len(history) >= _MIN_HISTORY_FOR_PATTERN,
        'generatedAt':     firestore.SERVER_TIMESTAMP,
    }


def run_pre_workout_insights_logic(workout_id: str, workout_data: dict) -> dict:
    """
    Entry point chamado pela trigger.

    1. Computa hash dos campos relevantes do treino.
    2. Compara com `_preWorkoutInsightsHash` no doc — se igual, skip.
    3. Para cada atleta com perfil:
       - Busca histórico, carga atual, PRs.
       - Chama LLM.
       - Persiste em users/{uid}/insights/pre_workout/{workoutId}.
    4. Atualiza o hash em exercises/{workoutId}._preWorkoutInsightsHash.

    Retorna stats da execução para log.
    """
    db = firestore.client()

    workout_hash = _compute_workout_hash(workout_data)
    last_hash = workout_data.get('_preWorkoutInsightsHash')

    if last_hash == workout_hash:
        logging.info(
            f'[pre-workout] {workout_id}: hash inalterado — skip.'
        )
        return {'skipped': 'hash_unchanged'}

    workout_summary = _extract_workout_summary(workout_data)
    workout_summary['workoutId'] = workout_id  # garante o id

    # LLM compartilhado entre os atletas — uma única instância.
    from .logic import _get_gemini_api_key, _build_llm
    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)

    # Itera atletas. users/ tem todos os usuários — filtramos pelos que
    # têm doc em profiles/athlete.
    users_ref = db.collection('users')
    athlete_count = 0
    generated     = 0

    for user_doc in users_ref.stream():
        if not _is_athlete_user(user_doc, db):
            continue
        athlete_count += 1

        result = _generate_insights_for_athlete(
            db, user_doc.id, workout_summary, workout_hash, llm,
        )
        if not result:
            continue

        try:
            db.collection('users').document(user_doc.id) \
              .collection('insights').document('pre_workout') \
              .collection('items').document(workout_id) \
              .set(result)
            generated += 1

            try:
                from notification_module import create_user_notification
                create_user_notification(
                    db=db,
                    uid=user_doc.id,
                    role="athlete",
                    type_="athlete_pre_workout_insights_ready",
                    title="Treino novo publicado",
                    body=(
                        "Seu coach acabou de publicar um treino. "
                        "Venha dar uma olhada nas informações que geramos para você."
                    ),
                    dedupe_key=(
                        f"athlete-pre-workout-insights:{user_doc.id}:"
                        f"{workout_id}"
                    ),
                    route_name="/athlete_pre_workout_insights_detail",
                    route_args={"workoutId": workout_id},
                    source_id=workout_id,
                )
            except Exception as notify_error:
                logging.warning(
                    f'[pre-workout] {user_doc.id}: falha ao notificar: '
                    f'{notify_error}'
                )
        except Exception as e:
            logging.error(
                f'[pre-workout] {user_doc.id}: falha ao persistir: {e}'
            )

    # Atualiza o hash no doc do treino para evitar reprocessamento.
    try:
        db.collection('exercises').document(workout_id).update({
            '_preWorkoutInsightsHash': workout_hash,
            '_preWorkoutInsightsGeneratedAt': firestore.SERVER_TIMESTAMP,
        })
    except Exception as e:
        logging.warning(f'[pre-workout] falha ao atualizar hash: {e}')

    logging.info(
        f'[pre-workout] {workout_id}: hash={workout_hash[:8]} '
        f'atletas_visitados={athlete_count} insights_gerados={generated}'
    )
    return {
        'workoutId':       workout_id,
        'hash':            workout_hash,
        'athletesVisited': athlete_count,
        'insightsGenerated': generated,
    }
