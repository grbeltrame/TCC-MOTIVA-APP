# functions/athlete_stats_module/logic.py

import logging
import statistics
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

_TZ_BRAZIL = ZoneInfo('America/Sao_Paulo')

# ==============================================================================
# CONSTANTES
# ==============================================================================

_REST_PREFIX  = '_REST'
_OTHER_PREFIX = '_OTHER'

# Dia de início da semana: domingo (mantém consistência com todo o app Flutter)
_WEEK_START_WEEKDAY = 6  # domingo

# Fallback quando não conseguir ler duracaoMinutos do WOD
_DEFAULT_WOD_DURATION_MIN = 20.0

# Janela do ACWR (Gabbett, 2016): 4 semanas para a Carga Crônica.
_ACWR_CHRONIC_WINDOW = 4
_ICN_CLAMP_MIN = 0.0
_ICN_CLAMP_MAX = 150.0

# Partes do treino que NÃO são o treino principal (quando precisamos do cap)
_SUPPORT_PARTS = {
    'WARM UP', 'WARMUP',
    'EXTRA TRAINING', 'EXTRA',
    'MOBILIDADE', 'MOBILITY',
    'SKILL',
}


# ==============================================================================
# HELPERS DE DATA
# ==============================================================================

def _date_key(dt: datetime) -> str:
    return dt.strftime('%Y-%m-%d')


def _week_bounds(ref: datetime) -> tuple:
    """
    Retorna (start, end) da semana que contém `ref`.
    Semana: domingo → sábado.

    Python weekday(): seg=0, ter=1, qua=2, qui=3, sex=4, sáb=5, dom=6
    Fórmula: (weekday() + 1) % 7
      dom(6) → 0 dias antes do início
      seg(0) → 1 dia  antes do início
      sáb(5) → 6 dias antes do início
    """
    days_since_sunday = (ref.weekday() + 1) % 7
    start = ref - timedelta(days=days_since_sunday)
    end   = start + timedelta(days=6)
    return (
        start.replace(hour=0,  minute=0,  second=0,  microsecond=0),
        end.replace(  hour=23, minute=59, second=59, microsecond=999999),
    )


def _week_label_sunday(week_start: datetime) -> str:
    """
    Label 'YYYY-Www' baseado em semanas dom→sáb (nossa própria convenção,
    não o padrão ISO 8601 que usa seg→dom).

    week_start DEVE ser o domingo inicial da semana.
    Semana 01 do ano = semana que contém o primeiro domingo.
    Domingos anteriores ao primeiro domingo do ano pertencem à última semana
    do ano anterior (ex: 28/12/2025 → 2025-W52).
    """
    year = week_start.year
    jan1 = datetime(year, 1, 1, tzinfo=week_start.tzinfo)
    days_to_first_sunday = (6 - jan1.weekday()) % 7
    first_sunday = jan1 + timedelta(days=days_to_first_sunday)

    if week_start < first_sunday:
        # Ainda no ano passado em termos de label de semana
        prev_year_last_day = datetime(year - 1, 12, 31, tzinfo=week_start.tzinfo)
        return _week_label_sunday(_week_bounds(prev_year_last_day)[0])

    week_num = ((week_start - first_sunday).days // 7) + 1
    return f'{year}-W{week_num:02d}'


def _month_bounds(ref: datetime) -> tuple:
    """Retorna (start, end) do mês que contém `ref`."""
    start = ref.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if ref.month == 12:
        end = ref.replace(year=ref.year + 1, month=1, day=1,
                          hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
    else:
        end = ref.replace(month=ref.month + 1, day=1,
                          hour=0, minute=0, second=0, microsecond=0) - timedelta(seconds=1)
    return start, end


def _classify_doc(doc_id: str) -> str:
    """Retorna: 'rest' | 'other' | 'training'."""
    upper = doc_id.upper()
    if upper.endswith(_REST_PREFIX):
        return 'rest'
    if _OTHER_PREFIX in upper:
        return 'other'
    return 'training'


def _date_from_doc_id(doc_id: str) -> str | None:
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
# HELPERS DE MODALIDADE E CARGA
# ==============================================================================

def _normalize_modalidade(raw) -> str:
    if not raw:
        return ''
    return str(raw).strip().upper()


def _is_for_time(modalidade: str) -> bool:
    """Pega 'FOR TIME', '3 ROUNDS FOR TIME', '5 ROUNDS FOR TIME', etc."""
    return 'FOR TIME' in modalidade


def _is_amrap(modalidade: str) -> bool:
    return modalidade == 'AMRAP'


def _is_emom(modalidade: str) -> bool:
    return modalidade == 'EMOM'


def _compute_icn(
    current_load: float, chronic_load: float | None
) -> float | None:
    """ICN = (carga_aguda / carga_crônica) × 50, clampado em [0, 150].

    Retorna None se não houver carga crônica (cold start semana 1).
    """
    if chronic_load is None or chronic_load <= 0:
        return None
    raw = (current_load / chronic_load) * 50.0
    clamped = min(max(raw, _ICN_CLAMP_MIN), _ICN_CLAMP_MAX)
    return round(clamped, 1)


def _fetch_main_part_duration_minutes(db, training_doc_id: str) -> float:
    """
    Busca a duração (em minutos) da parte principal do treino em
    exercises/{trainingDocId}.

    A parte principal é a primeira chave de `partes` que NÃO está em
    _SUPPORT_PARTS (WARM UP, SKILL, EXTRA TRAINING, MOBILIDADE).
    Replica a mesma lógica de register_result_bottom_sheet.dart.
    """
    if not training_doc_id:
        return _DEFAULT_WOD_DURATION_MIN

    try:
        doc = db.collection('exercises').document(training_doc_id).get()
        if not doc.exists:
            logging.warning(
                f'Cap não encontrado — exercises/{training_doc_id} não existe.'
                f' Usando padrão {_DEFAULT_WOD_DURATION_MIN}min.'
            )
            return _DEFAULT_WOD_DURATION_MIN

        data = doc.to_dict() or {}
        partes = data.get('partes', {}) or {}
        if not isinstance(partes, dict) or not partes:
            return _DEFAULT_WOD_DURATION_MIN

        main_part = None
        for key, value in partes.items():
            if key.strip().upper() not in _SUPPORT_PARTS:
                main_part = value
                break
        if main_part is None:
            # Todo o treino é suporte (caso raro) → pega a primeira parte
            main_part = next(iter(partes.values()))

        if not isinstance(main_part, dict):
            return _DEFAULT_WOD_DURATION_MIN

        duracao = main_part.get('duracaoMinutos')
        if duracao is not None and float(duracao) > 0:
            return float(duracao)

        return _DEFAULT_WOD_DURATION_MIN
    except Exception as e:
        logging.warning(
            f'Falha ao buscar cap de {training_doc_id}: {e}. '
            f'Usando padrão {_DEFAULT_WOD_DURATION_MIN}min.'
        )
        return _DEFAULT_WOD_DURATION_MIN


def _training_duration_minutes(data: dict, db) -> float:
    """
    Duração real (tempo sob esforço) de um resultado de treino, em minutos.
    Segue a mesma lógica do register_result_bottom_sheet.dart.
    """
    modalidade     = _normalize_modalidade(data.get('modalidade'))
    completed      = bool(data.get('completed', False))
    training_doc_id = data.get('trainingDocId')

    # FOR TIME (inclusive "3 ROUNDS FOR TIME", "5 ROUNDS FOR TIME", etc.)
    if _is_for_time(modalidade):
        if completed:
            for_time_sec = data.get('forTimeSec')
            if for_time_sec is not None and for_time_sec > 0:
                return float(for_time_sec) / 60.0
            # completed=True mas sem tempo registrado → usa o cap como fallback
        return _fetch_main_part_duration_minutes(db, training_doc_id)

    # AMRAP: sempre usa o cap
    if _is_amrap(modalidade):
        return _fetch_main_part_duration_minutes(db, training_doc_id)

    # EMOM
    if _is_emom(modalidade):
        if completed:
            return _fetch_main_part_duration_minutes(db, training_doc_id)
        rounds = data.get('emomCompletedRounds')
        if rounds is not None and rounds > 0:
            return float(rounds)
        return _fetch_main_part_duration_minutes(db, training_doc_id)

    # Modalidade desconhecida → assume que durou o cap do treino
    return _fetch_main_part_duration_minutes(db, training_doc_id)


# ==============================================================================
# LÓGICA PRINCIPAL
# ==============================================================================

def update_athlete_stats_logic(event):
    """
    Disparada quando:
      - users/{uid}/results/{resultId} é criado/atualizado/deletado
      - users/{uid}/prs/{prId} é criado/atualizado/deletado

    Recalcula e persiste:
      - users/{uid}/stats/summary (all-time, mês, semana, estímulos, calendário)
      - users/{uid}/weekly_load/{weekLabel} (carga Session-RPE, monotonia, strain, ICN)
    """
    db = firestore.client()

    uid = event.params.get('uid')
    if not uid:
        logging.error('update_athlete_stats: uid não encontrado nos params.')
        return

    logging.info(f'Atualizando stats do atleta: {uid}')

    # ── Carrega todos os results (necessário para all-time + mês + semana) ──
    results_ref = db.collection('users').document(uid).collection('results')
    all_docs    = list(results_ref.stream())

    # ── Referências de tempo ────────────────────────────────────────────────
    now                    = datetime.now(tz=_TZ_BRAZIL)
    week_start, week_end   = _week_bounds(now)
    month_start, month_end = _month_bounds(now)
    week_label             = _week_label_sunday(week_start)

    # ── Acumuladores: stats gerais ──────────────────────────────────────────
    all_efforts         = []
    month_efforts       = []
    month_training_days = set()
    week_efforts        = []
    week_training_days  = set()
    week_stimuli        = {}
    week_calendar       = {}

    # ── Acumuladores: carga semanal ─────────────────────────────────────────
    week_daily_loads_crossfit = {}
    week_daily_loads_other    = {}
    week_rpes_crossfit        = []
    week_rpes_all             = []
    week_wod_days             = set()
    week_other_days           = set()
    week_rest_days            = set()

    # Pré-popula 7 dias da semana com carga 0.0 (monotonia precisa dos zeros)
    for i in range(7):
        day_key = _date_key(week_start + timedelta(days=i))
        week_daily_loads_crossfit[day_key] = 0.0
        week_daily_loads_other[day_key]    = 0.0

    # ── Processa cada documento ─────────────────────────────────────────────
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

        # ── Calendário semanal ──────────────────────────────────────────────
        if in_week:
            existing = week_calendar.get(date_str)
            if existing != 'wod':
                week_calendar[date_str] = kind if kind in ('rest', 'other') else 'wod'

        # ── REST: carga = 0, conta no restDays, sem RPE ─────────────────────
        if kind == 'rest':
            if in_week:
                week_rest_days.add(date_str)
            continue

        # ── Effort é obrigatório (OTHER e training) ─────────────────────────
        effort = data.get('effort')
        if effort is None or effort == 0:
            logging.warning(
                f'Resultado {doc_id} sem effort — pulando do cálculo de carga.'
            )
            continue

        all_efforts.append(effort)
        if in_month:
            month_efforts.append(effort)
            month_training_days.add(date_str)
        if in_week:
            week_efforts.append(effort)
            week_training_days.add(date_str)

        # ── Carga semanal (só calcula para registros da semana atual) ───────
        # Fórmula Session-RPE pura (Foster, 2001): carga = RPE × duração_min.
        # Sem fator de categoria: RPE já é carga INTERNA relativa à capacidade
        # do atleta (Haddad et al., 2017).
        if in_week:
            if kind == 'other':
                duration = data.get('durationMinutes')
                if duration is not None and duration > 0:
                    carga = float(effort) * float(duration)
                    week_daily_loads_other[date_str] = \
                        week_daily_loads_other.get(date_str, 0.0) + carga
                    week_rpes_all.append(effort)
                    week_other_days.add(date_str)
                else:
                    logging.warning(
                        f'OTHER {doc_id} sem durationMinutes válido — pulando carga.'
                    )
            else:  # training (WOD, LPO, Ginástica, etc.)
                duration_min = _training_duration_minutes(data, db)
                carga        = float(effort) * duration_min
                week_daily_loads_crossfit[date_str] = \
                    week_daily_loads_crossfit.get(date_str, 0.0) + carga
                week_rpes_crossfit.append(effort)
                week_rpes_all.append(effort)
                week_wod_days.add(date_str)

                # Estímulos (só para treinos)
                for metric in data.get('keyMetrics', []) or []:
                    if isinstance(metric, str) and metric.strip():
                        label = metric.strip()
                        week_stimuli[label] = week_stimuli.get(label, 0) + 1

    # ── Médias e totais ─────────────────────────────────────────────────────
    def avg(lst):
        return round(sum(lst) / len(lst), 1) if lst else 0.0

    total_load_crossfit = round(sum(week_daily_loads_crossfit.values()), 1)
    total_load_other    = round(sum(week_daily_loads_other.values()), 1)
    total_load_all      = round(total_load_crossfit + total_load_other, 1)

    avg_rpe_crossfit = avg(week_rpes_crossfit)
    avg_rpe_all      = avg(week_rpes_all)

    # ── Monotonia, strain e rest ratio ──────────────────────────────────────
    daily_loads_all = {
        k: week_daily_loads_crossfit.get(k, 0.0) + week_daily_loads_other.get(k, 0.0)
        for k in week_daily_loads_crossfit.keys()
    }
    valores = list(daily_loads_all.values())  # 7 valores
    media   = statistics.mean(valores)
    desvio  = statistics.pstdev(valores)
    monotony = round(media / desvio, 3) if desvio > 0 else 0.0
    strain   = round(total_load_all * monotony, 1)
    rest_ratio = round(len(week_rest_days) / 7.0, 2)

    # ── PRs da semana (users/{uid}/prs, field 'date' é Timestamp) ───────────
    prs_count = 0
    try:
        prs_ref = db.collection('users').document(uid).collection('prs')
        prs_snap = prs_ref \
            .where(filter=FieldFilter('date', '>=', week_start)) \
            .where(filter=FieldFilter('date', '<=', week_end)) \
            .stream()
        prs_count = sum(1 for _ in prs_snap)
    except Exception as e:
        logging.warning(f'Falha ao contar PRs da semana: {e}')

    # ── ICN — Índice de Carga Normalizado via ACWR (Gabbett, 2016) ──────────
    # ICN = (Carga Aguda / Carga Crônica) × 50
    #   Carga Aguda  = totalLoadAll da semana atual
    #   Carga Crônica = média de totalLoadAll das últimas N≤4 semanas completas
    #                   ANTERIORES à semana atual (sem incluir a atual).
    #
    # Interpretação:
    #   ICN = 50            → Na média histórica (manutenção)
    #   ICN entre 50–75     → Acima da média — zona de evolução segura
    #   ICN > 75            → Alerta — aumento abrupto de carga, risco de lesão
    #   ICN < 50            → Abaixo da média — recuperação ou destreinamento
    #
    # Cold start:
    #   - semana 1 (sem histórico)    → ICN = 50 e baselineType = 'cold_start'
    #   - semanas 2–4 (≤3 completas)  → média do que houver (partial_N_weeks)
    #   - semana 5+ (4 completas)     → média das 4 últimas (historical_4_weeks)
    icn_all        = None
    icn_crossfit   = None
    carga_cronica  = None
    acwr_raw       = None
    baseline_type  = 'cold_start'
    try:
        weekly_load_ref = db.collection('users').document(uid).collection('weekly_load')
        hist_docs = list(
            weekly_load_ref
                .order_by('weekLabel', direction=firestore.Query.DESCENDING)
                .limit(_ACWR_CHRONIC_WINDOW + 1)  # +1 para poder descartar atual
                .stream()
        )
        prev_weeks_loads = [
            float((d.to_dict() or {}).get('totalLoadAll') or 0.0)
            for d in hist_docs
            if d.id != week_label
        ][:_ACWR_CHRONIC_WINDOW]

        completed_count = len(prev_weeks_loads)

        if completed_count == 0:
            # Semana 1 — sem histórico. ICN neutro = 50.
            icn_all       = 50.0
            icn_crossfit  = 50.0
            baseline_type = 'cold_start'
        else:
            carga_cronica = round(statistics.mean(prev_weeks_loads), 1)
            if completed_count < _ACWR_CHRONIC_WINDOW:
                baseline_type = f'partial_{completed_count}_weeks'
            else:
                baseline_type = 'historical_4_weeks'

            if carga_cronica > 0:
                acwr_raw_val = total_load_all / carga_cronica
                acwr_raw     = round(acwr_raw_val, 3)
                icn_all      = _compute_icn(total_load_all, carga_cronica)
                icn_crossfit = _compute_icn(total_load_crossfit, carga_cronica)
            else:
                # Todas as semanas anteriores com carga zerada — tratamos como cold start.
                icn_all       = 50.0
                icn_crossfit  = 50.0
                carga_cronica = None
                acwr_raw      = None
    except Exception as e:
        logging.warning(f'Falha ao calcular ICN: {e}')

    # ── Validações matemáticas (log-only; nunca derruba a função) ───────────
    if round(total_load_all - (total_load_crossfit + total_load_other), 2) != 0:
        logging.warning(
            f'[{uid}|{week_label}] inconsistência: total_load_all={total_load_all} '
            f'≠ crossfit({total_load_crossfit}) + other({total_load_other})'
        )
    if icn_all is not None and not (_ICN_CLAMP_MIN <= icn_all <= _ICN_CLAMP_MAX):
        logging.warning(
            f'[{uid}|{week_label}] ICN fora do clamp: {icn_all}'
        )
    if icn_all is not None and baseline_type != 'cold_start' and \
            (carga_cronica is None or carga_cronica <= 0):
        logging.warning(
            f'[{uid}|{week_label}] ICN calculado sem carga crônica válida.'
        )

    # ── Persiste weekly_load/{weekLabel} ────────────────────────────────────
    weekly_load_doc = {
        # Identificação
        'weekLabel': week_label,
        'weekStart': _date_key(week_start),
        'weekEnd':   _date_key(week_end),

        # Cargas brutas (AU) — Session-RPE sem fator de categoria
        'totalLoadCrossfit': total_load_crossfit,
        'totalLoadOther':    total_load_other,
        'totalLoadAll':      total_load_all,

        # ICN via ACWR (Gabbett, 2016)
        'icnAll':       icn_all,        # float ou None (cold start, ~nunca)
        'icnCrossfit':  icn_crossfit,   # float ou None
        'cargaCronica': carga_cronica,  # float ou None
        'acwrRaw':      acwr_raw,       # float ou None (razão antes do ×50)
        'baselineType': baseline_type,  # cold_start | partial_N_weeks | historical_4_weeks

        # RPE médio
        'avgRpeCrossfit': avg_rpe_crossfit,
        'avgRpeAll':      avg_rpe_all,

        # Frequência
        'wodDays':   len(week_wod_days),
        'otherDays': len(week_other_days),
        'restDays':  len(week_rest_days),

        # Saúde do treino
        'monotony':  monotony,
        'strain':    strain,
        'restRatio': rest_ratio,

        # PRs
        'prsCount': prs_count,

        # Cargas diárias (para gráfico de barras no app)
        'dailyLoadsCrossfit': week_daily_loads_crossfit,
        'dailyLoadsOther':    week_daily_loads_other,

        # Metadado
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }
    db.collection('users').document(uid) \
      .collection('weekly_load').document(week_label) \
      .set(weekly_load_doc)

    # ── Atualiza stats/summary (preserva campos existentes + adiciona carga)
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

        # Novos campos de carga (expostos para o app ler sem precisar
        # abrir weekly_load — lookup rápido)
        'weeklyLoadCrossfit':   total_load_crossfit,
        'weeklyLoadAll':        total_load_all,
        'weeklyLoadLabel':      week_label,
        'weeklyICN':            icn_all,        # float ou None
        'weeklyBaselineType':   baseline_type,  # string
        'weeklyCargaCronica':   carga_cronica,  # float ou None — base individual

        # Metadados
        'weekStart':  _date_key(week_start),
        'weekEnd':    _date_key(week_end),
        'monthStart': _date_key(month_start),
        'updatedAt':  firestore.SERVER_TIMESTAMP,
    }

    stats_ref = db.collection('users').document(uid) \
                  .collection('stats').document('summary')
    stats_ref.set(summary)

    logging.info(
        f'✅ {uid} | {week_label} | '
        f'loadAll={total_load_all} loadCrossfit={total_load_crossfit} '
        f'icnAll={icn_all} baseline={baseline_type} cronica={carga_cronica} '
        f'monotony={monotony} strain={strain} prs={prs_count}'
    )
