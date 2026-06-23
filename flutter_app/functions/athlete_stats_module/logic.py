# functions/athlete_stats_module/logic.py

import logging
import statistics
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from firebase_admin import firestore

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
# CÁLCULO DE UMA SEMANA
# ==============================================================================

def _compute_week_load_doc(
    *,
    week_label: str,
    week_start: datetime,
    week_end: datetime,
    week_docs: list,
    prev_weeks_loads: list,
    prs_count: int,
    db,
):
    """
    Calcula o documento de weekly_load/{week_label} a partir dos resultados
    daquela semana e da carga das semanas ANTERIORES (já calculadas).

    week_docs:
        Lista de tuplas (doc_id, data_dict, kind) de resultados que pertencem
        a esta semana. kind ∈ {'rest', 'other', 'training'}.

    prev_weeks_loads:
        Lista de até _ACWR_CHRONIC_WINDOW totalLoadAll das semanas COMPLETAS
        anteriores a esta (em qualquer ordem). Usada para a Carga Crônica.

    prs_count:
        Quantidade de PRs registrados nesta semana.
    """
    # Pré-popula os 7 dias da semana com 0.0 (monotonia precisa dos zeros)
    daily_loads_crossfit = {
        _date_key(week_start + timedelta(days=i)): 0.0 for i in range(7)
    }
    daily_loads_other = {
        _date_key(week_start + timedelta(days=i)): 0.0 for i in range(7)
    }

    rpes_crossfit = []
    rpes_all      = []
    wod_days      = set()
    other_days    = set()
    rest_days     = set()
    stimuli       = {}

    for doc_id, data, kind in week_docs:
        date_str = data.get('date') or _date_from_doc_id(doc_id)
        if not date_str:
            continue

        if kind == 'rest':
            rest_days.add(date_str)
            continue

        effort = data.get('effort')
        if effort is None or effort == 0:
            logging.warning(
                f'Resultado {doc_id} sem effort — pulando do cálculo de carga.'
            )
            continue

        if kind == 'other':
            duration = data.get('durationMinutes')
            if duration is not None and duration > 0:
                carga = float(effort) * float(duration)
                daily_loads_other[date_str] = \
                    daily_loads_other.get(date_str, 0.0) + carga
                rpes_all.append(effort)
                other_days.add(date_str)
            else:
                logging.warning(
                    f'OTHER {doc_id} sem durationMinutes válido — pulando carga.'
                )
        else:  # training
            duration_min = _training_duration_minutes(data, db)
            carga        = float(effort) * duration_min
            daily_loads_crossfit[date_str] = \
                daily_loads_crossfit.get(date_str, 0.0) + carga
            rpes_crossfit.append(effort)
            rpes_all.append(effort)
            wod_days.add(date_str)

            for metric in data.get('keyMetrics', []) or []:
                if isinstance(metric, str) and metric.strip():
                    stimuli[metric.strip()] = stimuli.get(metric.strip(), 0) + 1

    # ── Totais e médias ────────────────────────────────────────────────────
    total_load_crossfit = round(sum(daily_loads_crossfit.values()), 1)
    total_load_other    = round(sum(daily_loads_other.values()), 1)
    total_load_all      = round(total_load_crossfit + total_load_other, 1)

    def _avg(lst):
        return round(sum(lst) / len(lst), 1) if lst else 0.0

    avg_rpe_crossfit = _avg(rpes_crossfit)
    avg_rpe_all      = _avg(rpes_all)

    # ── Monotonia, strain, rest ratio ──────────────────────────────────────
    daily_all = {
        k: daily_loads_crossfit.get(k, 0.0) + daily_loads_other.get(k, 0.0)
        for k in daily_loads_crossfit.keys()
    }
    valores  = list(daily_all.values())
    media    = statistics.mean(valores)
    desvio   = statistics.pstdev(valores)
    monotony = round(media / desvio, 3) if desvio > 0 else 0.0
    strain   = round(total_load_all * monotony, 1)
    rest_ratio = round(len(rest_days) / 7.0, 2)

    # ── ICN via ACWR (Gabbett, 2016) ───────────────────────────────────────
    # ICN = (Carga Aguda / Carga Crônica) × 50
    #   Carga Aguda  = totalLoadAll desta semana
    #   Carga Crônica = média de totalLoadAll das últimas N≤4 semanas anteriores
    #
    # Cold start:
    #   - sem histórico (0 semanas anteriores)    → ICN = 50, baselineType = 'cold_start'
    #   - 1–3 semanas anteriores                  → 'partial_N_weeks'
    #   - ≥4 semanas anteriores                   → 'historical_4_weeks'
    icn_all       = None
    icn_crossfit  = None
    carga_cronica = None
    acwr_raw      = None
    baseline_type = 'cold_start'

    completed_count = len(prev_weeks_loads)
    if completed_count == 0:
        icn_all       = 50.0
        icn_crossfit  = 50.0
        baseline_type = 'cold_start'
    else:
        carga_cronica = round(statistics.mean(prev_weeks_loads), 1)
        baseline_type = (
            f'partial_{completed_count}_weeks'
            if completed_count < _ACWR_CHRONIC_WINDOW
            else 'historical_4_weeks'
        )
        if carga_cronica > 0:
            acwr_raw     = round(total_load_all / carga_cronica, 3)
            icn_all      = _compute_icn(total_load_all, carga_cronica)
            icn_crossfit = _compute_icn(total_load_crossfit, carga_cronica)
        else:
            # Todas as semanas anteriores zeradas → tratamos como cold start
            icn_all       = 50.0
            icn_crossfit  = 50.0
            carga_cronica = None
            acwr_raw      = None

    # ── Validações log-only ────────────────────────────────────────────────
    if round(total_load_all - (total_load_crossfit + total_load_other), 2) != 0:
        logging.warning(
            f'[{week_label}] inconsistência: total_load_all={total_load_all} '
            f'≠ crossfit({total_load_crossfit}) + other({total_load_other})'
        )

    return {
        # Identificação
        'weekLabel': week_label,
        'weekStart': _date_key(week_start),
        'weekEnd':   _date_key(week_end),

        # Cargas brutas (AU)
        'totalLoadCrossfit': total_load_crossfit,
        'totalLoadOther':    total_load_other,
        'totalLoadAll':      total_load_all,

        # ICN via ACWR
        'icnAll':       icn_all,
        'icnCrossfit':  icn_crossfit,
        'cargaCronica': carga_cronica,
        'acwrRaw':      acwr_raw,
        'baselineType': baseline_type,

        # RPE médio
        'avgRpeCrossfit': avg_rpe_crossfit,
        'avgRpeAll':      avg_rpe_all,

        # Frequência
        'wodDays':   len(wod_days),
        'otherDays': len(other_days),
        'restDays':  len(rest_days),

        # Saúde do treino
        'monotony':  monotony,
        'strain':    strain,
        'restRatio': rest_ratio,

        # PRs
        'prsCount': prs_count,

        # Cargas diárias (para gráfico de barras no app)
        'dailyLoadsCrossfit': daily_loads_crossfit,
        'dailyLoadsOther':    daily_loads_other,

        # Estímulos (usados pela IA semanal e pelo card de estímulos)
        'stimuli': stimuli,

        # Metadado
        'updatedAt': firestore.SERVER_TIMESTAMP,
    }


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
      - users/{uid}/weekly_load/{weekLabel} para CADA semana com registros,
        em ordem cronológica, garantindo que cargaCronica cascateie corretamente
        quando um resultado de semana antiga é editado/apagado.
      - Apaga docs órfãos de weekly_load (semanas onde todos os results foram
        removidos).
    """
    db = firestore.client()

    uid = event.params.get('uid')
    if not uid:
        logging.error('update_athlete_stats: uid não encontrado nos params.')
        return

    logging.info(f'Atualizando stats do atleta: {uid}')

    # ── Carrega todos os results ────────────────────────────────────────────
    results_ref = db.collection('users').document(uid).collection('results')
    all_docs    = list(results_ref.stream())

    # ── Referências de tempo ────────────────────────────────────────────────
    now                          = datetime.now(tz=_TZ_BRAZIL)
    current_week_start, current_week_end = _week_bounds(now)
    month_start, month_end       = _month_bounds(now)
    current_label                = _week_label_sunday(current_week_start)

    # ── Acumuladores de stats gerais (all-time + mês + semana atual) ────────
    all_efforts          = []
    month_efforts        = []
    month_training_days  = set()
    week_efforts         = []
    week_training_days   = set()
    week_calendar        = {}

    # ── Agrupa results por semana (para recálculo de weekly_load) ───────────
    # Estrutura: label -> {'week_start', 'week_end', 'docs': [(doc_id, data, kind)]}
    docs_by_week: dict[str, dict] = {}

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

        # Bucket da semana deste doc
        wk_start, wk_end = _week_bounds(doc_date)
        wk_label = _week_label_sunday(wk_start)
        bucket = docs_by_week.setdefault(wk_label, {
            'week_start': wk_start,
            'week_end':   wk_end,
            'docs':       [],
        })
        bucket['docs'].append((doc_id, data, kind))

        # ── Stats agregadas (all-time / mês / semana atual) ─────────────────
        in_week  = current_week_start <= doc_date <= current_week_end
        in_month = month_start        <= doc_date <= month_end

        if in_week:
            existing = week_calendar.get(date_str)
            if existing != 'wod':
                week_calendar[date_str] = (
                    kind if kind in ('rest', 'other') else 'wod'
                )

        if kind == 'rest':
            continue

        effort = data.get('effort')
        if effort is None or effort == 0:
            continue

        all_efforts.append(effort)
        if in_month:
            month_efforts.append(effort)
            month_training_days.add(date_str)
        if in_week:
            week_efforts.append(effort)
            week_training_days.add(date_str)

    # ── Carrega PRs e agrupa por semana (para prsCount em cada weekly_load) ─
    prs_per_week: dict[str, int] = {}
    try:
        prs_ref = db.collection('users').document(uid).collection('prs')
        for pr_doc in prs_ref.stream():
            pr_data = pr_doc.to_dict() or {}
            pr_date = pr_data.get('date')
            if pr_date is None:
                continue
            # date pode vir como datetime (Timestamp) ou string ISO
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
            wk_start, _ = _week_bounds(pr_dt)
            wk_label = _week_label_sunday(wk_start)
            prs_per_week[wk_label] = prs_per_week.get(wk_label, 0) + 1
    except Exception as e:
        logging.warning(f'Falha ao agrupar PRs por semana: {e}')

    # ── Garante bucket para a semana ATUAL mesmo sem results, para que o
    #    summary tenha um weekly_load atual válido (ICN=null se não houver
    #    histórico, ou cargaCronica zerada).
    if current_label not in docs_by_week:
        docs_by_week[current_label] = {
            'week_start': current_week_start,
            'week_end':   current_week_end,
            'docs':       [],
        }

    # ── Calcula weekly_load para cada semana, EM ORDEM CRONOLÓGICA ──────────
    # Isso é crítico: cada semana usa as 4 anteriores JÁ calculadas para a
    # cargaCronica. Se um treino antigo é editado, a edição cascateia 4
    # semanas à frente automaticamente.
    sorted_labels    = sorted(docs_by_week.keys())  # asc
    computed_loads: dict[str, dict] = {}

    for label in sorted_labels:
        bucket = docs_by_week[label]

        # Pega totalLoadAll das semanas anteriores já calculadas (até 4)
        prev_loads = []
        for prev_label in reversed(sorted_labels):
            if prev_label >= label:
                continue
            prev = computed_loads.get(prev_label)
            if prev is None:
                continue
            prev_loads.append(float(prev.get('totalLoadAll') or 0.0))
            if len(prev_loads) >= _ACWR_CHRONIC_WINDOW:
                break

        computed_loads[label] = _compute_week_load_doc(
            week_label=label,
            week_start=bucket['week_start'],
            week_end=bucket['week_end'],
            week_docs=bucket['docs'],
            prev_weeks_loads=prev_loads,
            prs_count=prs_per_week.get(label, 0),
            db=db,
        )

    # ── Persiste todos os weekly_load docs ──────────────────────────────────
    weekly_load_ref = db.collection('users').document(uid).collection('weekly_load')
    for label, doc in computed_loads.items():
        weekly_load_ref.document(label).set(doc)

    # ── Apaga weekly_load órfãos (semanas onde todos os results foram apagados)
    try:
        existing_labels = {d.id for d in weekly_load_ref.stream()}
        orphan_labels = existing_labels - set(computed_loads.keys())
        for orphan in orphan_labels:
            weekly_load_ref.document(orphan).delete()
            logging.info(f'weekly_load órfão removido: {orphan}')
    except Exception as e:
        logging.warning(f'Falha ao limpar weekly_load órfãos: {e}')

    # ── Atualiza stats/summary (semana atual + agregados) ───────────────────
    def avg(lst):
        return round(sum(lst) / len(lst), 1) if lst else 0.0

    current_week = computed_loads[current_label]

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
        'currentWeekStimuli':          current_week.get('stimuli', {}),
        'currentWeekCalendar':         week_calendar,

        # Atalhos do weekly_load atual (lookup rápido sem 2ª query)
        'weeklyLoadCrossfit': current_week.get('totalLoadCrossfit', 0.0),
        'weeklyLoadAll':      current_week.get('totalLoadAll', 0.0),
        'weeklyLoadLabel':    current_label,
        'weeklyICN':          current_week.get('icnAll'),
        'weeklyBaselineType': current_week.get('baselineType', 'cold_start'),
        'weeklyCargaCronica': current_week.get('cargaCronica'),

        # Metadados
        'weekStart':  _date_key(current_week_start),
        'weekEnd':    _date_key(current_week_end),
        'monthStart': _date_key(month_start),
        'updatedAt':  firestore.SERVER_TIMESTAMP,
    }

    stats_ref = db.collection('users').document(uid) \
                  .collection('stats').document('summary')
    stats_ref.set(summary)

    logging.info(
        f'✅ {uid} | weeks={len(computed_loads)} '
        f'current={current_label} '
        f'loadAll={current_week.get("totalLoadAll")} '
        f'icn={current_week.get("icnAll")} '
        f'baseline={current_week.get("baselineType")} '
        f'cronica={current_week.get("cargaCronica")}'
    )
