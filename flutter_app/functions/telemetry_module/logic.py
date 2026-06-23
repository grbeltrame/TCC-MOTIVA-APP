# functions/telemetry_module/logic.py
#
# Telemetria leve para acompanhamento de consumo da IA.
# Persistida em telemetry/{YYYY-MM-DD} com FieldValue.increment para
# evitar conflitos em escritas concorrentes (várias triggers podem
# atualizar o mesmo doc no mesmo dia).
#
# Não levanta exceção: se a escrita falhar, registra warning e segue.
# Telemetria não pode quebrar o fluxo principal da IA.

from __future__ import annotations

import logging
from datetime import datetime
from zoneinfo import ZoneInfo


_TZ_BRAZIL = ZoneInfo('America/Sao_Paulo')

# Estimativa rough de tokens — Gemini PT-BR usa ~3.5-4 chars/token em média.
_CHARS_PER_TOKEN = 4


def estimate_tokens(text: str) -> int:
    """Estimativa rough de quantos tokens um texto consome."""
    if not text:
        return 0
    return max(1, len(text) // _CHARS_PER_TOKEN)


def _today_doc_id() -> str:
    return datetime.now(tz=_TZ_BRAZIL).strftime('%Y-%m-%d')


def record_insight_generated(
    kind: str,
    *,
    with_cohort: bool = False,
    prompt_chars: int = 0,
    response_chars: int = 0,
    skipped: bool = False,
    reason: str | None = None,
) -> None:
    status = 'skipped' if skipped else 'generated'
    record_insight_event(
        kind,
        status=status,
        reason=reason,
        with_cohort=with_cohort,
        prompt_chars=prompt_chars,
        response_chars=response_chars,
    )


def record_insight_event(
    kind: str,
    *,
    status: str,
    reason: str | None = None,
    with_cohort: bool = False,
    prompt_chars: int = 0,
    response_chars: int = 0,
) -> None:
    """
    Atualiza atomicamente o contador diário em telemetry/{YYYY-MM-DD}.

    kind ∈ {'weekly', 'evolution', 'preWorkout'}.
    status ∈ {'generated', 'skipped', 'failed', 'from_cache'}.

    Use FieldValue.increment para que múltiplas execuções concorrentes
    no mesmo dia não derrubem updates umas das outras.
    """
    try:
        # Import dentro da função: permite que testes stubem firebase_admin
        # antes de qualquer import do módulo de telemetria.
        from firebase_admin import firestore

        db = firestore.client()
        ts_doc_id = _today_doc_id()
        prompt_tok = estimate_tokens('x' * prompt_chars) if prompt_chars else 0
        response_tok = estimate_tokens('x' * response_chars) if response_chars else 0

        updates: dict = {
            'date': ts_doc_id,
            f'insights.{kind}.total':         firestore.Increment(1),
            f'insights.{kind}.{status}':      firestore.Increment(1),
            'estimatedTokens.prompt':         firestore.Increment(prompt_tok),
            'estimatedTokens.response':       firestore.Increment(response_tok),
            'updatedAt':                      firestore.SERVER_TIMESTAMP,
        }
        if reason:
            safe_reason = ''.join(
                c if c.isalnum() or c == '_' else '_' for c in str(reason)
            ).strip('_') or 'unknown'
            updates[f'insights.{kind}.reasons.{safe_reason}'] = firestore.Increment(1)
        if with_cohort:
            updates[f'insights.{kind}.withCohort'] = firestore.Increment(1)
        else:
            updates[f'insights.{kind}.withoutCohort'] = firestore.Increment(1)

        db.collection('telemetry').document(ts_doc_id).set(updates, merge=True)

        logging.info(
            f'[telemetry] {kind} status={status} reason={reason} '
            f'cohort={with_cohort} prompt_tok≈{prompt_tok} '
            f'resp_tok≈{response_tok}'
        )
    except Exception as e:
        # Telemetria nunca derruba o fluxo principal.
        logging.warning(f'[telemetry] falha ao registrar {kind}: {e}')


def record_cohort_job(
    *,
    cohorts_persisted: int,
    cohorts_too_small: int,
    athletes_active: int,
) -> None:
    """Registra a execução do job de agregação de coortes."""
    try:
        from firebase_admin import firestore

        db = firestore.client()
        ts_doc_id = _today_doc_id()
        updates = {
            'date': ts_doc_id,
            'cohortJobs.runs':                firestore.Increment(1),
            'cohortJobs.cohortsPersistedSum': firestore.Increment(cohorts_persisted),
            'cohortJobs.cohortsTooSmallSum':  firestore.Increment(cohorts_too_small),
            'cohortJobs.athletesActiveSum':   firestore.Increment(athletes_active),
            'updatedAt':                      firestore.SERVER_TIMESTAMP,
        }
        db.collection('telemetry').document(ts_doc_id).set(updates, merge=True)
        logging.info(
            f'[telemetry] cohort-job persisted={cohorts_persisted} '
            f'too_small={cohorts_too_small} active={athletes_active}'
        )
    except Exception as e:
        logging.warning(f'[telemetry] falha ao registrar cohort-job: {e}')
