# functions/athlete_stats_module/logic.py

import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore

_TZ_BRAZIL = ZoneInfo('America/Sao_Paulo')

# ==============================================================================
# CONSTANTES
# ==============================================================================

# Tipos que NÃO contam como treino (apenas atividade ou descanso)
_REST_PREFIX   = '_REST'
_OTHER_PREFIX  = '_OTHER'

# Dia de início da semana: domingo (0 = segunda, 6 = domingo em Python weekday())
_WEEK_START_WEEKDAY = 6  # domingo


# ==============================================================================
# HELPERS
# ==============================================================================

def _date_key(dt: datetime) -> str:
    return dt.strftime('%Y-%m-%d')


def _week_bounds(ref: datetime) -> tuple:
    """
    Retorna (start, end) da semana que contém `ref`.
    Semana: domingo → sábado.

    Python weekday(): seg=0, ter=1, qua=2, qui=3, sex=4, sáb=5, dom=6
    Fórmula: (weekday() + 1) % 7
      dom(6) → (6+1)%7 = 0  → 0 dias antes do início  ✓
      seg(0) → (0+1)%7 = 1  → 1 dia  antes do início  ✓
      sáb(5) → (5+1)%7 = 6  → 6 dias antes do início  ✓
    """
    days_since_sunday = (ref.weekday() + 1) % 7
    start = ref - timedelta(days=days_since_sunday)
    end   = start + timedelta(days=6)
    return (
        start.replace(hour=0,  minute=0,  second=0,  microsecond=0),
        end.replace(  hour=23, minute=59, second=59, microsecond=999999),
    )


def _month_bounds(ref: datetime) -> tuple:
    """Retorna (start, end) do mês que contém `ref`."""
    start = ref.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    # Primeiro dia do próximo mês − 1 segundo
    if ref.month == 12:
        end = ref.replace(year=ref.year + 1, month=1, day=1,
                          hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
    else:
        end = ref.replace(month=ref.month + 1, day=1,
                          hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
    return start, end


def _classify_doc(doc_id: str) -> str:
    """
    Classifica o documento pelo sufixo do ID.
    Retorna: 'rest' | 'other' | 'training'
    """
    upper = doc_id.upper()
    if upper.endswith(_REST_PREFIX):
        return 'rest'
    if _OTHER_PREFIX in upper:
        return 'other'
    return 'training'


def _date_from_doc_id(doc_id: str) -> str | None:
    """
    Extrai a data 'YYYY-MM-DD' do início do ID do documento.
    Ex: '2026-03-16_WOD' → '2026-03-16'
    """
    parts = doc_id.split('_')
    if len(parts) >= 1:
        candidate = parts[0]
        try:
            datetime.strptime(candidate, '%Y-%m-%d')
            return candidate
        except ValueError:
            pass
    return None


# ==============================================================================
# LÓGICA PRINCIPAL
# ==============================================================================

def update_athlete_stats_logic(event):
    """
    Ponto de entrada chamado pelo main.py quando um documento em
    users/{uid}/results/{resultId} é criado ou atualizado.

    Recalcula e salva users/{uid}/stats/summary com:
      - Estatísticas all-time
      - Estatísticas do mês atual
      - Estatísticas da semana atual
      - Calendário da semana (tipo de atividade por dia)
    """
    db = firestore.client()

    # ── Extrai o uid dos parâmetros da rota ──────────────────────────────────
    uid = event.params.get('uid')
    if not uid:
        logging.error('update_athlete_stats: uid não encontrado nos params.')
        return

    logging.info(f'Atualizando stats do atleta: {uid}')

    # ── Busca todos os results do atleta ─────────────────────────────────────
    results_ref = db.collection('users').document(uid).collection('results')
    all_docs = list(results_ref.stream())

    if not all_docs:
        logging.info(f'Nenhum result encontrado para {uid}. Abortando.')
        return

    # ── Referência de tempo ───────────────────────────────────────────────────
    now            = datetime.now(tz=_TZ_BRAZIL)
    week_start, week_end   = _week_bounds(now)
    month_start, month_end = _month_bounds(now)

    # ── Acumuladores ─────────────────────────────────────────────────────────
    all_efforts          = []
    month_efforts        = []
    month_training_days  = set()
    week_efforts         = []
    week_training_days   = set()
    week_stimuli         = {}   # { "Força": 3, "Potência": 2, ... }
    week_calendar        = {}   # { "2026-04-07": "wod", ... }

    for doc in all_docs:
        doc_id   = doc.id
        data     = doc.to_dict() or {}
        kind     = _classify_doc(doc_id)
        date_str = data.get('date') or _date_from_doc_id(doc_id)

        if not date_str:
            continue

        try:
            doc_date = datetime.strptime(date_str, '%Y-%m-%d').replace(tzinfo=_TZ_BRAZIL)
        except ValueError:
            continue

        in_week  = week_start  <= doc_date <= week_end
        in_month = month_start <= doc_date <= month_end

        # ── Calendário semanal ────────────────────────────────────────────
        if in_week:
            # Se já existe uma entrada para esse dia, só promove training
            existing = week_calendar.get(date_str)
            if existing != 'wod':
                week_calendar[date_str] = kind if kind in ('rest', 'other') else 'wod'

        # ── Métricas de atividade (exclui apenas descanso) ───────────────
        if kind == 'rest':
            continue

        effort = data.get('effort')

        if effort is not None:
            all_efforts.append(effort)
            if in_month:
                month_efforts.append(effort)
            if in_week:
                week_efforts.append(effort)

        if in_month:
            month_training_days.add(date_str)

        if in_week:
            week_training_days.add(date_str)

            # Estímulos — agrega key_metrics do registro
            key_metrics = data.get('keyMetrics', [])
            for metric in key_metrics:
                if isinstance(metric, str) and metric.strip():
                    label = metric.strip()
                    week_stimuli[label] = week_stimuli.get(label, 0) + 1

    # ── Calcula médias ────────────────────────────────────────────────────────
    def avg(lst):
        return round(sum(lst) / len(lst), 1) if lst else 0.0

    # ── Monta o documento final ───────────────────────────────────────────────
    summary = {
        # All-time
        'totalTrainingDays':      len({
            _date_from_doc_id(d.id)
            for d in all_docs
            if _classify_doc(d.id) != 'rest'
        }),
        'averageEffortAllTime':   avg(all_efforts),

        # Mês atual
        'currentMonthTrainingDays':    len(month_training_days),
        'averageEffortCurrentMonth':   avg(month_efforts),

        # Semana atual
        'currentWeekTrainingDays':     len(week_training_days),
        'averageEffortCurrentWeek':    avg(week_efforts),
        'currentWeekStimuli':          week_stimuli,
        'currentWeekCalendar':         week_calendar,

        # Metadados
        'weekStart':  _date_key(week_start),
        'weekEnd':    _date_key(week_end),
        'monthStart': _date_key(month_start),
        'updatedAt':  firestore.SERVER_TIMESTAMP,
    }

    # ── Salva em users/{uid}/stats/summary ────────────────────────────────────
    stats_ref = db.collection('users').document(uid) \
                  .collection('stats').document('summary')
    stats_ref.set(summary)

    logging.info(
        f'✅ Stats atualizados para {uid} | '
        f'semana: {len(week_training_days)} treinos | '
        f'esforço médio semana: {avg(week_efforts)}'
    )
