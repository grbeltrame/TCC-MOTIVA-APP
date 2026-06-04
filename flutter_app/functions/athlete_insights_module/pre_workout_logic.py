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
from .context_builder import build_pre_workout_context
from .llm_parser import parse_llm_response
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

_ATHLETE_PROFILES = {'athlete', 'athleteCoach', 'athleteIntern'}


def _record_insight_event(
    status: str,
    *,
    reason: str | None = None,
    with_cohort: bool = False,
    prompt_chars: int = 0,
    response_chars: int = 0,
) -> None:
    try:
        from telemetry_module import record_insight_event
        record_insight_event(
            'preWorkout',
            status=status,
            reason=reason,
            with_cohort=with_cohort,
            prompt_chars=prompt_chars,
            response_chars=response_chars,
        )
    except Exception:
        pass


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
    Atleta é usuário cujo perfil raiz é atleta ou híbrido.

    O doc users/{uid}/profiles/athlete é complementar: ele melhora o
    contexto da IA, mas não deve bloquear a geração dos insights.
    """
    try:
        data = user_doc.to_dict() or {}
        return data.get('profile') in _ATHLETE_PROFILES
    except Exception:
        return False


def _fetch_athlete_history_same_type(
    db, uid: str, workout_summary: dict
) -> list:
    """
    Retorna até _MAX_HISTORY_ITEMS WODs OFICIAIS do atleta no MESMO
    wodType OU mesma modalidade, ordenados desc por data.
    Apenas results com `trainingDocId` (vinculados a treino do coach).
    """
    target_wod_type   = (workout_summary.get('wodType') or '').strip().upper()
    target_modalidade = (workout_summary.get('modalidade') or '').strip().upper()

    if not target_wod_type and not target_modalidade:
        return []

    try:
        results_ref = db.collection('users').document(uid).collection('results')
        recent = list(
            results_ref.order_by('date', direction=firestore.Query.DESCENDING)
                       .limit(60)
                       .stream()
        )
        matches = []
        for doc in recent:
            data = doc.to_dict() or {}
            if not data.get('trainingDocId'):  # pular extras/pessoais
                continue
            wt = (data.get('wodType')    or '').strip().upper()
            md = (data.get('modalidade') or '').strip().upper()
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
                    'category':     data.get('category'),
                })
                if len(matches) >= _MAX_HISTORY_ITEMS:
                    break
        return matches
    except Exception as e:
        logging.warning(f'[pre-workout] {uid} — falha ao buscar histórico: {e}')
        return []


def _fetch_athlete_complementary_load_recent(db, uid: str) -> list:
    """
    Retorna extras/treinos pessoais dos últimos 7 dias (results SEM
    trainingDocId). Usado apenas para informar carga acumulada — nunca
    como histórico de comparação de formato.
    """
    cutoff = (
        datetime.now(tz=_TZ_BRAZIL) - timedelta(days=7)
    ).strftime('%Y-%m-%d')
    try:
        results_ref = db.collection('users').document(uid).collection('results')
        docs = list(
            results_ref.where('date', '>=', cutoff).limit(30).stream()
        )
        return [
            {
                'date':       data.get('date'),
                'effort':     data.get('effort'),
                'modalidade': data.get('modalidade'),
            }
            for doc in docs
            if (data := doc.to_dict() or {}) and not data.get('trainingDocId')
        ]
    except Exception as e:
        logging.warning(
            f'[pre-workout] {uid} — falha ao buscar carga complementar: {e}'
        )
        return []


def _fetch_athlete_history_for_time_of_day(
    db, uid: str
) -> list:
    """
    Retorna até 90 results recentes do atleta para alimentar o cálculo de
    período do dia. Não filtra por modalidade — o padrão de horário é
    transversal ao tipo de treino.
    """
    try:
        results_ref = db.collection('users').document(uid).collection('results')
        recent = list(
            results_ref.order_by('date', direction=firestore.Query.DESCENDING)
                       .limit(90)
                       .stream()
        )
        return [
            {
                'date':         data.get('date'),
                'effort':       data.get('effort'),
                'trainingTime': data.get('trainingTime'),
                'completed':    data.get('completed'),
            }
            for doc in recent
            if (data := doc.to_dict() or {})
            and data.get('trainingTime')
            and data.get('trainingDocId')  # apenas WODs oficiais
        ]
    except Exception as e:
        logging.warning(
            f'[pre-workout] {uid} — falha ao buscar histórico por período: {e}'
        )
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
    """Lê users/{uid}/profiles/athlete como contexto opcional."""
    try:
        prof_ref = db.collection('users').document(uid) \
                     .collection('profiles').document('athlete')
        prof_doc = prof_ref.get()
        if not prof_doc.exists:
            return {'hasDetailedProfile': False}
        data = prof_doc.to_dict() or {}
        return {
            'hasDetailedProfile': True,
            'category':      data.get('category'),
            'gender':        data.get('gender'),
            'practiceYears': data.get('practiceYears'),
            'weight':        data.get('weight'),
            'height':        data.get('height'),
        }
    except Exception:
        return {'hasDetailedProfile': False}


def _pre_workout_insight_exists(db, uid: str, workout_id: str) -> bool:
    try:
        doc = db.collection('users').document(uid) \
                .collection('insights').document('pre_workout') \
                .collection('items').document(workout_id).get()
        return doc.exists
    except Exception as e:
        logging.warning(
            f'[pre-workout] {uid}: falha ao verificar insight existente: {e}'
        )
        return False


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
        _record_insight_event('skipped', reason='no_data')
        return {}

    profile               = _fetch_athlete_profile(db, uid)
    recent_prs            = _fetch_athlete_recent_prs(db, uid)
    time_of_day_hist      = _fetch_athlete_history_for_time_of_day(db, uid)
    complementary_load    = _fetch_athlete_complementary_load_recent(db, uid)

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
        pre_workout_context=build_pre_workout_context(
            workout=workout_summary,
            athlete_history_same_type=history,
            athlete_current_load=current_load,
            athlete_recent_prs=recent_prs,
            time_of_day_history=time_of_day_hist,
            complementary_load_recent=complementary_load,
        ),
        now=datetime.now(tz=_TZ_BRAZIL),
        cohort=cohort,
    )

    parser = get_pre_workout_parser()

    try:
        ai_message = llm.invoke(prompt)
        parsed = parse_llm_response(
            ai_message.content,
            parser,
            flow='pre-workout',
            uid=uid,
        )
    except Exception as e:
        _record_insight_event(
            'failed',
            reason='llm_or_parse_error',
            with_cohort=cohort is not None,
            prompt_chars=len(prompt),
            response_chars=len(
                getattr(locals().get('ai_message', None), 'content', '') or ''
            ),
        )
        logging.error(f'[pre-workout] {uid}: falha do LLM: {e}')
        return {}

    _record_insight_event(
        'generated',
        with_cohort=cohort is not None,
        prompt_chars=len(prompt),
        response_chars=len(ai_message.content or ''),
    )

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
    2. Compara com `_preWorkoutInsightsHash` no doc.
       - Se mudou: regenera para todos os atletas elegíveis.
       - Se está igual: gera apenas para atletas elegíveis ainda sem insight.
    3. Para cada atleta elegível:
       - Busca histórico, carga atual, PRs.
       - Chama LLM.
       - Persiste em users/{uid}/insights/pre_workout/{workoutId}.
    4. Atualiza o hash em exercises/{workoutId}._preWorkoutInsightsHash.

    Retorna stats da execução para log.
    """
    db = firestore.client()

    if workout_data.get('status') != 'publicado':
        logging.info(f'[pre-workout] {workout_id}: treino não publicado — skip.')
        _record_insight_event('skipped', reason='not_published')
        return {'skipped': 'not_published'}

    workout_hash = _compute_workout_hash(workout_data)
    last_hash = workout_data.get('_preWorkoutInsightsHash')
    hash_unchanged = last_hash == workout_hash

    workout_summary = _extract_workout_summary(workout_data)
    workout_summary['workoutId'] = workout_id  # garante o id

    llm = None

    # Itera atletas. users/ tem todos os usuários — filtramos pelos que
    # têm perfil raiz de atleta ou híbrido.
    users_ref = db.collection('users')
    athlete_count = 0
    generated     = 0
    existing      = 0
    failed        = 0

    for user_doc in users_ref.stream():
        if not _is_athlete_user(user_doc, db):
            continue
        from user_settings_module import athlete_ai_enabled
        if not athlete_ai_enabled(db, user_doc.id):
            continue
        athlete_count += 1

        if hash_unchanged and _pre_workout_insight_exists(
            db, user_doc.id, workout_id
        ):
            existing += 1
            continue

        # LLM compartilhado entre os atletas — instanciado somente se houver
        # alguém realmente precisando de geração nesta execução.
        if llm is None:
            from .logic import _get_gemini_api_key, _build_llm
            api_key = _get_gemini_api_key()
            llm = _build_llm(api_key)

        result = _generate_insights_for_athlete(
            db, user_doc.id, workout_summary, workout_hash, llm,
        )
        if not result:
            failed += 1
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
            failed += 1
            logging.error(
                f'[pre-workout] {user_doc.id}: falha ao persistir: {e}'
            )

    # Atualiza o hash no doc do treino para evitar reprocessamento.
    if generated > 0 or not hash_unchanged:
        try:
            db.collection('exercises').document(workout_id).update({
                '_preWorkoutInsightsHash': workout_hash,
                '_preWorkoutInsightsGeneratedAt': firestore.SERVER_TIMESTAMP,
            })
        except Exception as e:
            logging.warning(f'[pre-workout] falha ao atualizar hash: {e}')

    logging.info(
        f'[pre-workout] {workout_id}: hash={workout_hash[:8]} '
        f'atletas_visitados={athlete_count} '
        f'insights_existentes={existing} insights_gerados={generated} '
        f'insights_falhos={failed}'
    )
    return {
        'workoutId':       workout_id,
        'hash':            workout_hash,
        'athletesVisited': athlete_count,
        'insightsExisting': existing,
        'insightsGenerated': generated,
        'insightsFailed':   failed,
        'hashUnchanged':    hash_unchanged,
    }
