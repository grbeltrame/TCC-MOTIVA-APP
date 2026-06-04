# functions/cohort_module/aggregation.py
#
# Job de agregação de coortes. Roda 1x/dia (Cloud Scheduler 3h da manhã).
#
# Para cada atleta com perfil completo (category + gender), calcula a chave
# de coorte (level3 e level2) e agrega métricas da semana corrente sobre os
# atletas do mesmo grupo. Persiste em cohorts/{cohort_key}/snapshot.
#
# Coortes com < _MIN_COHORT_SIZE atletas NÃO são persistidas — privacidade
# e significância estatística.

from __future__ import annotations

import logging
import statistics
from collections import defaultdict
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore

from .bucketization import build_cohort_keys


_TZ_BRAZIL = ZoneInfo('America/Sao_Paulo')

# Mínimo de atletas em uma coorte para que ela seja publicada. Coortes
# menores não geram doc — atleta cai no fallback ou não recebe insight
# comparativo. Garante privacidade e significância.
_MIN_COHORT_SIZE = 5

# Considera o atleta "ativo" se tem weekly_load atualizado nas últimas
# 4 semanas. Filtro evita inflar coortes com perfis abandonados.
_ACTIVITY_WINDOW_WEEKS = 4


def _current_week_label(now: datetime) -> str:
    """Mesma convenção de athlete_stats_module: domingo→sábado."""
    days_since_sunday = (now.weekday() + 1) % 7
    week_start = (now - timedelta(days=days_since_sunday)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    year = week_start.year
    jan1 = datetime(year, 1, 1, tzinfo=week_start.tzinfo)
    days_to_first_sunday = (6 - jan1.weekday()) % 7
    first_sunday = jan1 + timedelta(days=days_to_first_sunday)
    if week_start < first_sunday:
        prev_year = year - 1
        jan1_prev = datetime(prev_year, 1, 1, tzinfo=week_start.tzinfo)
        days_prev = (6 - jan1_prev.weekday()) % 7
        first_sunday_prev = jan1_prev + timedelta(days=days_prev)
        week_num = ((week_start - first_sunday_prev).days // 7) + 1
        return f'{prev_year}-W{week_num:02d}'
    week_num = ((week_start - first_sunday).days // 7) + 1
    return f'{year}-W{week_num:02d}'


def _safe_mean(values: list, ndigits: int = 2):
    if not values:
        return None
    return round(statistics.mean(values), ndigits)


def _safe_median(values: list, ndigits: int = 2):
    if not values:
        return None
    return round(statistics.median(values), ndigits)


def _aggregate_metrics(athlete_loads: list) -> dict:
    """
    Recebe lista de docs weekly_load (dicts) de atletas da coorte.
    Retorna dicionário de métricas agregadas (médias/medianas).
    """
    icns           = []
    monotonias     = []
    rpes           = []
    completion     = []  # placeholder — sem dado direto, deixamos para futuras iterações
    prs            = []
    estimulos      = defaultdict(int)
    cargas_cronica = []

    for wl in athlete_loads:
        if wl.get('icnAll') is not None:
            icns.append(float(wl['icnAll']))
        if wl.get('monotony') is not None and wl.get('monotony') > 0:
            monotonias.append(float(wl['monotony']))
        if wl.get('avgRpeAll') is not None:
            rpes.append(float(wl['avgRpeAll']))
        if wl.get('prsCount') is not None:
            prs.append(int(wl['prsCount']))
        if wl.get('cargaCronica') is not None:
            cargas_cronica.append(float(wl['cargaCronica']))
        for stim, n in (wl.get('stimuli') or {}).items():
            try:
                estimulos[str(stim)] += int(n)
            except (TypeError, ValueError):
                continue

    top_stimuli = [
        s for s, _ in sorted(estimulos.items(), key=lambda x: -x[1])[:5]
    ]

    return {
        'avgWeeklyICN':    _safe_mean(icns, 1),
        'medianWeeklyICN': _safe_median(icns, 1),
        'avgMonotony':     _safe_mean(monotonias, 2),
        'avgRpeAll':       _safe_mean(rpes, 2),
        'avgPrsPerWeek':   _safe_mean(prs, 2),
        'avgCargaCronica': _safe_mean(cargas_cronica, 1),
        'topStimuli':      top_stimuli,
    }


def _is_athlete_active(uid: str, db, current_week_label: str) -> bool:
    """
    Atleta é considerado ativo se tem weekly_load registrado em
    qualquer uma das últimas _ACTIVITY_WINDOW_WEEKS semanas.

    Faz uma única leitura ordenada — barata.
    """
    try:
        docs = list(
            db.collection('users').document(uid).collection('weekly_load')
              .order_by('weekLabel', direction=firestore.Query.DESCENDING)
              .limit(_ACTIVITY_WINDOW_WEEKS)
              .stream()
        )
        return len(docs) > 0
    except Exception:
        return False


def update_cohort_snapshots_logic() -> dict:
    """
    Entry point chamado pelo Cloud Scheduler / endpoint HTTP.

    1. Itera atletas em users/{uid}/profiles/athlete.
    2. Calcula cohort_keys (level 3 e level 2). Skip se faltar campo
       essencial (cobre 'Outro' gender, perfil incompleto).
    3. Filtra atletas ativos (weekly_load nas últimas 4 semanas).
    4. Lê o weekly_load da SEMANA ATUAL de cada atleta.
    5. Agrupa por cohort_key (level3 e level2 separadamente — atleta
       pode contar nas duas coortes).
    6. Para cada coorte com >= _MIN_COHORT_SIZE atletas, persiste em
       cohorts/{cohort_key}.

    Retorna stats da execução (para o response do endpoint HTTP).
    """
    db = firestore.client()

    now = datetime.now(tz=_TZ_BRAZIL)
    week_label = _current_week_label(now)

    cohorts_l3: dict[str, list] = defaultdict(list)
    cohorts_l2: dict[str, list] = defaultdict(list)
    cohort_meta: dict[str, dict] = {}  # key -> {category, gender, bucket?, level}

    athletes_total      = 0
    athletes_eligible   = 0
    athletes_active     = 0

    for user_doc in db.collection('users').stream():
        athletes_total += 1
        uid = user_doc.id

        # 1) Lê perfil de atleta
        try:
            prof = db.collection('users').document(uid) \
                     .collection('profiles').document('athlete').get()
        except Exception:
            continue
        if not prof.exists:
            continue
        profile = prof.to_dict() or {}

        # 2) Calcula chaves
        l3, l2 = build_cohort_keys(profile)
        if l2 is None:
            # Sem chave válida em nenhum nível — sem coorte.
            continue
        athletes_eligible += 1

        # 3) Atividade recente
        if not _is_athlete_active(uid, db, week_label):
            continue
        athletes_active += 1

        # 4) Lê weekly_load da semana atual
        try:
            wl_doc = db.collection('users').document(uid) \
                       .collection('weekly_load').document(week_label).get()
        except Exception:
            continue
        if not wl_doc.exists:
            continue
        weekly_load = wl_doc.to_dict() or {}

        # 5) Agrupa em level 3 (se houver) e level 2
        if l3 is not None:
            cohorts_l3[l3].append(weekly_load)
            if l3 not in cohort_meta:
                parts = l3.split('_')
                cohort_meta[l3] = {
                    'cohortKey':         l3,
                    'level':             3,
                    'category':          parts[0] if len(parts) > 0 else None,
                    'gender':            parts[1] if len(parts) > 1 else None,
                    'experienceBucket':  parts[2] if len(parts) > 2 else None,
                }

        cohorts_l2[l2].append(weekly_load)
        if l2 not in cohort_meta:
            parts = l2.split('_')
            cohort_meta[l2] = {
                'cohortKey':        l2,
                'level':            2,
                'category':         parts[0] if len(parts) > 0 else None,
                'gender':           parts[1] if len(parts) > 1 else None,
                'experienceBucket': None,
            }

    # 6) Persiste coortes >= mínimo
    cohorts_ref = db.collection('cohorts')
    persisted: list = []
    skipped_too_small: list = []

    def _persist(key: str, loads: list):
        if len(loads) < _MIN_COHORT_SIZE:
            skipped_too_small.append({'cohortKey': key, 'size': len(loads)})
            return
        meta = cohort_meta.get(key, {})
        snapshot = {
            **meta,
            'athleteCount':  len(loads),
            'weekLabel':     week_label,
            'metrics':       _aggregate_metrics(loads),
            'updatedAt':     firestore.SERVER_TIMESTAMP,
            'minCohortSize': _MIN_COHORT_SIZE,
        }
        try:
            cohorts_ref.document(key).set(snapshot)
            persisted.append({'cohortKey': key, 'size': len(loads)})
        except Exception as e:
            logging.error(f'[cohorts] falha ao persistir {key}: {e}')

    # Persiste TODOS os level 3 antes dos level 2 — ajuda o matching a
    # priorizar level 3 quando ambos existem.
    for key, loads in cohorts_l3.items():
        _persist(key, loads)
    for key, loads in cohorts_l2.items():
        _persist(key, loads)

    # 7) Limpa coortes que existiam antes mas não devem mais (sem atletas
    # ativos suficientes essa semana). Evita acúmulo de docs estagnados.
    try:
        existing = {d.id for d in cohorts_ref.stream()}
        active_keys = {p['cohortKey'] for p in persisted}
        stale = existing - active_keys
        for s in stale:
            cohorts_ref.document(s).delete()
    except Exception as e:
        logging.warning(f'[cohorts] falha ao limpar coortes estagnadas: {e}')

    summary = {
        'weekLabel':         week_label,
        'athletesTotal':     athletes_total,
        'athletesEligible':  athletes_eligible,
        'athletesActive':    athletes_active,
        'cohortsPersisted':  len(persisted),
        'cohortsTooSmall':   len(skipped_too_small),
        'persisted':         persisted,
        'skippedTooSmall':   skipped_too_small,
    }

    # Telemetria — falha não derruba o job.
    try:
        from telemetry_module import record_cohort_job
        record_cohort_job(
            cohorts_persisted=len(persisted),
            cohorts_too_small=len(skipped_too_small),
            athletes_active=athletes_active,
        )
    except Exception:
        pass

    logging.info(f'[cohorts] {summary}')
    return summary
