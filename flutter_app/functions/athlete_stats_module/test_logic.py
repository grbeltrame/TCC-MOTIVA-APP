# functions/athlete_stats_module/test_logic.py
"""
Teste local dos 5 cenários da refatoração do weekly_load.

Uso:
    cd flutter_app/functions
    python -m athlete_stats_module.test_logic

Mocka Firestore (get/stream/set) em memória, chama update_athlete_stats_logic
e compara os documentos finais de weekly_load e stats/summary com o esperado.

NÃO depende de credenciais nem de rede.
"""

from __future__ import annotations

import os
import statistics
import sys
import types
from datetime import datetime, timedelta
from unittest.mock import patch
from zoneinfo import ZoneInfo

# Garante que 'functions/' está no sys.path para que 'athlete_stats_module'
# seja importável tanto via 'python -m' quanto rodando o arquivo direto.
_THIS_DIR    = os.path.dirname(os.path.abspath(__file__))
_FUNCTIONS_DIR = os.path.dirname(_THIS_DIR)
if _FUNCTIONS_DIR not in sys.path:
    sys.path.insert(0, _FUNCTIONS_DIR)

# ------------------------------------------------------------------
# Stub de firebase_admin.firestore e google.cloud.firestore_v1.base_query
# ANTES de importar qualquer coisa de athlete_stats_module (seu __init__.py
# puxa logic.py que importa esses módulos).
# ------------------------------------------------------------------

if 'firebase_admin' not in sys.modules:
    _fa_pkg = types.ModuleType('firebase_admin')
    _fa_firestore = types.ModuleType('firebase_admin.firestore')

    class _StubQuery:
        DESCENDING = 'DESCENDING'
        ASCENDING  = 'ASCENDING'

    _fa_firestore.Query = _StubQuery
    _fa_firestore.SERVER_TIMESTAMP = '__SERVER_TS__'
    _fa_firestore.client = lambda: None  # patchado no runner
    _fa_pkg.firestore = _fa_firestore
    sys.modules['firebase_admin'] = _fa_pkg
    sys.modules['firebase_admin.firestore'] = _fa_firestore

if 'google.cloud.firestore_v1.base_query' not in sys.modules:
    _google        = sys.modules.setdefault('google', types.ModuleType('google'))
    _google_cloud  = sys.modules.setdefault('google.cloud', types.ModuleType('google.cloud'))
    _google_cloud_firestore_v1 = sys.modules.setdefault(
        'google.cloud.firestore_v1', types.ModuleType('google.cloud.firestore_v1')
    )
    _base_query = types.ModuleType('google.cloud.firestore_v1.base_query')

    class _StubFieldFilter:
        def __init__(self, field, op, value):
            self._field = field
            self._op    = op
            self._value = value

    _base_query.FieldFilter = _StubFieldFilter
    sys.modules['google.cloud.firestore_v1.base_query'] = _base_query
    _google_cloud_firestore_v1.base_query = _base_query
    _google_cloud.firestore_v1 = _google_cloud_firestore_v1
    _google.cloud = _google_cloud

# ------------------------------------------------------------------
# Fake Firestore — suporta .collection().document().collection()...
# e as operações .get / .stream / .set / .order_by / .limit / .where
# ------------------------------------------------------------------

_TZ = ZoneInfo('America/Sao_Paulo')


class _FakeDoc:
    def __init__(self, doc_id, data):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data) if self._data else None


class _FakeQuery:
    """Aplica filtros/ordenação/limite sobre uma lista de _FakeDoc."""

    def __init__(self, docs):
        self._docs = list(docs)

    def order_by(self, field, direction=None):
        desc = False
        if direction is not None:
            # firestore.Query.DESCENDING é uma constante string "DESCENDING"
            desc = str(direction).upper().find('DESC') >= 0
        self._docs.sort(
            key=lambda d: (d.to_dict() or {}).get(field, ''),
            reverse=desc,
        )
        return self

    def limit(self, n):
        self._docs = self._docs[:n]
        return self

    def where(self, *args, **kwargs):
        """Suporta filter=FieldFilter(field, op, value) — usado só em prs."""
        f = kwargs.get('filter')
        if f is None:
            return self
        # FieldFilter stub com atributos privados é o mais frequente.
        field = getattr(f, '_field', None) or getattr(f, 'field_path', None)
        op    = getattr(f, '_op', None)    or getattr(f, 'op_string', None)
        value = getattr(f, '_value', None) or getattr(f, 'value', None)

        def keep(d):
            data = d.to_dict() or {}
            v = data.get(field)
            if op in ('>=', 'GREATER_THAN_OR_EQUAL'):
                return v is not None and v >= value
            if op in ('<=', 'LESS_THAN_OR_EQUAL'):
                return v is not None and v <= value
            return True

        self._docs = [d for d in self._docs if keep(d)]
        return self

    def stream(self):
        for d in self._docs:
            yield d


class _FakeDocRef:
    def __init__(self, store, path):
        self._store = store
        self._path = path

    def get(self):
        return _FakeDoc(self._path[-1], self._store.get(tuple(self._path)))

    def set(self, data):
        # Resolve SERVER_TIMESTAMP para um datetime fixo de teste.
        resolved = {}
        for k, v in (data or {}).items():
            resolved[k] = datetime(2026, 4, 21, 12, 0, tzinfo=_TZ) \
                if v == '__SERVER_TS__' else v
        self._store[tuple(self._path)] = resolved

    def collection(self, name):
        return _FakeCollection(self._store, self._path + [name])


class _FakeCollection:
    def __init__(self, store, path):
        self._store = store
        self._path = path

    def document(self, doc_id):
        return _FakeDocRef(self._store, self._path + [doc_id])

    def stream(self):
        prefix = tuple(self._path)
        # Todos os docs cuja path começa com self._path e tem +1 elemento.
        for key, data in list(self._store.items()):
            if len(key) == len(prefix) + 1 and key[:-1] == prefix:
                yield _FakeDoc(key[-1], data)

    def order_by(self, field, direction=None):
        return _FakeQuery(self.stream()).order_by(field, direction)

    def where(self, **kwargs):
        return _FakeQuery(self.stream()).where(**kwargs)


class _FakeDB:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return _FakeCollection(self.store, [name])


# ------------------------------------------------------------------
# Stubs de firebase_admin/firestore
# ------------------------------------------------------------------

class _Query:
    DESCENDING = 'DESCENDING'
    ASCENDING  = 'ASCENDING'


class _FirestoreModuleStub:
    Query = _Query
    SERVER_TIMESTAMP = '__SERVER_TS__'

    def client(self):
        return _FirestoreModuleStub._db  # type: ignore


# ------------------------------------------------------------------
# Utilidades de montagem de cenário
# ------------------------------------------------------------------

def _week_sunday(ref: datetime) -> datetime:
    days_since_sunday = (ref.weekday() + 1) % 7
    start = ref - timedelta(days=days_since_sunday)
    return start.replace(hour=0, minute=0, second=0, microsecond=0)


def _label(week_start: datetime) -> str:
    from athlete_stats_module.logic import _week_label_sunday
    return _week_label_sunday(week_start)


def _put_result(db: _FakeDB, uid: str, doc_id: str, data: dict):
    db.store[('users', uid, 'results', doc_id)] = data


def _put_exercise(db: _FakeDB, exercise_id: str, duracao_minutos: float):
    db.store[('exercises', exercise_id)] = {
        'partes': {'WOD PRINCIPAL': {'duracaoMinutos': duracao_minutos}},
    }


def _put_history(db: _FakeDB, uid: str, history: list[tuple[str, float]]):
    """history = [(weekLabel, totalLoadAll), ...]."""
    for label, load in history:
        db.store[('users', uid, 'weekly_load', label)] = {
            'weekLabel':    label,
            'totalLoadAll': load,
        }


class _Event:
    def __init__(self, uid: str):
        self.params = {'uid': uid}


# ------------------------------------------------------------------
# Runner
# ------------------------------------------------------------------

def _run_scenario(name: str, build):
    """build(db, now) popula o fake db. Retorna (weekly_load, summary)."""
    print(f'\n── {name} ' + '─' * (60 - len(name)))
    db = _FakeDB()
    _FirestoreModuleStub._db = db  # type: ignore

    now = datetime(2026, 4, 21, 12, 0, tzinfo=_TZ)  # uma terça qualquer
    uid = 'test-uid'

    build(db, uid, now)

    # Patch firestore.client() e datetime.now() dentro do módulo.
    import athlete_stats_module.logic as logic_mod

    fake_module = _FirestoreModuleStub()

    class _FakeDateTime(datetime):
        @classmethod
        def now(cls, tz=None):
            return now if tz is None else now.astimezone(tz)

    with patch.object(logic_mod, 'firestore', fake_module), \
         patch.object(logic_mod, 'datetime', _FakeDateTime):
        logic_mod.update_athlete_stats_logic(_Event(uid))

    week_start = _week_sunday(now)
    label      = _label(week_start)
    weekly     = db.store.get(('users', uid, 'weekly_load', label))
    summary    = db.store.get(('users', uid, 'stats', 'summary'))
    return weekly, summary


def _assert(cond, msg):
    if not cond:
        print(f'  ❌ FAIL: {msg}')
        return False
    print(f'  ✓ {msg}')
    return True


# ------------------------------------------------------------------
# Cenários
# ------------------------------------------------------------------

def scenario_1_cold_start():
    """3 WODs (RPE 7, 20min cada), sem histórico."""
    def build(db, uid, now):
        week_start = _week_sunday(now)
        # Popula 3 dias consecutivos com um WOD cada.
        for i in range(3):
            date = (week_start + timedelta(days=i + 1)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_TRAINING_A', {
                'date': date,
                'effort': 7,
                'modalidade': 'AMRAP',
                'trainingDocId': 'wod-20min',
                'category': 'RX',
                'keyMetrics': ['Força'],
            })
        _put_exercise(db, 'wod-20min', 20.0)

    weekly, summary = _run_scenario('Cenário 1 — Cold Start (semana 1)', build)

    ok = True
    ok &= _assert(weekly is not None, 'weekly_load criado')
    ok &= _assert(weekly['totalLoadCrossfit'] == 420.0, 'totalLoadCrossfit = 420 (3 × 7 × 20)')
    ok &= _assert(weekly['totalLoadAll']      == 420.0, 'totalLoadAll = 420')
    ok &= _assert(weekly['icnAll']            == 50.0,  'icnAll = 50.0 (cold start neutro)')
    ok &= _assert(weekly['baselineType']      == 'cold_start', 'baselineType = cold_start')
    ok &= _assert(weekly['cargaCronica']      is None, 'cargaCronica = None')
    ok &= _assert(weekly['acwrRaw']           is None, 'acwrRaw = None')
    ok &= _assert('icnBaselineUsed' not in weekly,     'icnBaselineUsed removido do doc')
    ok &= _assert(summary['weeklyICN']          == 50.0,        'summary.weeklyICN = 50')
    ok &= _assert(summary['weeklyBaselineType'] == 'cold_start','summary.weeklyBaselineType = cold_start')
    return ok


def scenario_2_partial_history():
    """Semana 3 com 2 semanas anteriores de histórico."""
    def build(db, uid, now):
        week_start = _week_sunday(now)
        # 4 WODs RPE 8, 20 min → 4 × 160 = 640 AU
        for i in range(4):
            date = (week_start + timedelta(days=i)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_TRAINING_A', {
                'date': date,
                'effort': 8,
                'modalidade': 'AMRAP',
                'trainingDocId': 'wod-20min',
                'category': 'RX',
                'keyMetrics': ['Ritmo'],
            })
        _put_exercise(db, 'wod-20min', 20.0)
        # 2 semanas anteriores (usando labels qualquer "menor" que a atual)
        current_label = _label(week_start)
        prev1 = _label(week_start - timedelta(days=7))
        prev2 = _label(week_start - timedelta(days=14))
        _put_history(db, uid, [
            (prev1, 450.0),
            (prev2, 400.0),
        ])

    weekly, summary = _run_scenario('Cenário 2 — Histórico parcial (2 semanas)', build)

    ok = True
    ok &= _assert(weekly['totalLoadAll']   == 640.0, 'totalLoadAll = 640')
    ok &= _assert(weekly['cargaCronica']   == 425.0, 'cargaCronica = 425 (média de 400 e 450)')
    ok &= _assert(abs(weekly['acwrRaw'] - 1.506) < 0.01, f"acwrRaw ≈ 1.506 (got {weekly['acwrRaw']})")
    ok &= _assert(abs(weekly['icnAll']  - 75.3)  < 0.2,  f"icnAll ≈ 75.3 (got {weekly['icnAll']})")
    ok &= _assert(weekly['baselineType'] == 'partial_2_weeks', 'baselineType = partial_2_weeks')
    return ok


def scenario_3_historical_4_weeks():
    """6 semanas de histórico → usa só as 4 mais recentes."""
    def build(db, uid, now):
        week_start = _week_sunday(now)
        # Semana atual: 1 doc que soma 700 AU → effort=10 × duração=70min? Não,
        # mais simples: 7 WODs que somem 700. Escolhemos effort=10, cap=10min → 100 cada.
        # 7 × 100 = 700.
        for i in range(7):
            date = (week_start + timedelta(days=i)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_TRAINING_A', {
                'date': date,
                'effort': 10,
                'modalidade': 'AMRAP',
                'trainingDocId': 'wod-10min',
                'category': 'RX',
                'keyMetrics': ['Força'],
            })
        _put_exercise(db, 'wod-10min', 10.0)
        # 6 semanas: queremos que as 4 últimas (mais recentes) sejam 520/510/550/600.
        # Labels ordenados desc: prev1 > prev2 > prev3 > prev4 > prev5 > prev6
        prev1 = _label(week_start - timedelta(days=7))
        prev2 = _label(week_start - timedelta(days=14))
        prev3 = _label(week_start - timedelta(days=21))
        prev4 = _label(week_start - timedelta(days=28))
        prev5 = _label(week_start - timedelta(days=35))
        prev6 = _label(week_start - timedelta(days=42))
        _put_history(db, uid, [
            (prev1, 520.0),
            (prev2, 510.0),
            (prev3, 550.0),
            (prev4, 600.0),
            (prev5, 480.0),
            (prev6, 500.0),
        ])

    weekly, summary = _run_scenario('Cenário 3 — 6 semanas de histórico (usa 4)', build)

    ok = True
    ok &= _assert(weekly['totalLoadAll'] == 700.0, 'totalLoadAll = 700')
    expected = round(statistics.mean([520.0, 510.0, 550.0, 600.0]), 1)  # 545.0
    ok &= _assert(weekly['cargaCronica'] == expected, f'cargaCronica = {expected}')
    ok &= _assert(abs(weekly['acwrRaw'] - 1.284) < 0.01, f"acwrRaw ≈ 1.284 (got {weekly['acwrRaw']})")
    ok &= _assert(abs(weekly['icnAll']  - 64.2)  < 0.2,  f"icnAll ≈ 64.2 (got {weekly['icnAll']})")
    ok &= _assert(weekly['baselineType'] == 'historical_4_weeks', 'baselineType = historical_4_weeks')
    return ok


def scenario_4_rest_week():
    """5 REST + 2 WODs (RPE 6, 15min)."""
    def build(db, uid, now):
        week_start = _week_sunday(now)
        for i in range(5):
            date = (week_start + timedelta(days=i)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_REST', {
                'date': date,
                'effort': 0,
            })
        for i in (5, 6):
            date = (week_start + timedelta(days=i)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_TRAINING_A', {
                'date': date,
                'effort': 6,
                'modalidade': 'AMRAP',
                'trainingDocId': 'wod-15min',
                'category': 'RX',
                'keyMetrics': ['Ritmo'],
            })
        _put_exercise(db, 'wod-15min', 15.0)

    weekly, summary = _run_scenario('Cenário 4 — Semana de descanso (monotonia baixa)', build)

    ok = True
    ok &= _assert(weekly['totalLoadCrossfit'] == 180.0, 'totalLoadCrossfit = 180 (2 × 6 × 15)')
    ok &= _assert(weekly['monotony'] < 1.0, f"monotonia < 1.0 (got {weekly['monotony']})")
    ok &= _assert(weekly['restDays'] == 5, 'restDays = 5')
    ok &= _assert(weekly['wodDays']  == 2, 'wodDays = 2')
    return ok


def scenario_5_overtraining():
    """5 WODs consecutivos RPE 9, 25 min."""
    def build(db, uid, now):
        week_start = _week_sunday(now)
        for i in range(5):
            date = (week_start + timedelta(days=i)).strftime('%Y-%m-%d')
            _put_result(db, uid, f'{date}_TRAINING_A', {
                'date': date,
                'effort': 9,
                'modalidade': 'AMRAP',
                'trainingDocId': 'wod-25min',
                'category': 'RX',
                'keyMetrics': ['Força', 'Resistência'],
            })
        _put_exercise(db, 'wod-25min', 25.0)

    weekly, summary = _run_scenario('Cenário 5 — Overtraining (strain alto)', build)

    ok = True
    ok &= _assert(weekly['totalLoadCrossfit'] == 1125.0, 'totalLoadCrossfit = 1125 (5 × 9 × 25)')
    # 5 dias de carga alta + 2 de zero numa janela de 7 dias:
    # média ≈ 160.71, pstdev ≈ 101.64 → monotonia ≈ 1.58 (acima do 1.5 de Foster)
    ok &= _assert(abs(weekly['monotony'] - 1.58) < 0.05,
                  f"monotonia > 1.5 (Foster) — got {weekly['monotony']}")
    ok &= _assert(weekly['strain'] > 1500, f"strain alto (got {weekly['strain']})")
    return ok


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

def main():
    results = []
    results.append(('cold_start',         scenario_1_cold_start()))
    results.append(('partial_2_weeks',    scenario_2_partial_history()))
    results.append(('historical_4_weeks', scenario_3_historical_4_weeks()))
    results.append(('rest_week',          scenario_4_rest_week()))
    results.append(('overtraining',       scenario_5_overtraining()))

    print('\n' + '=' * 60)
    print('RESULTADO')
    print('=' * 60)
    passed = sum(1 for _, ok in results if ok)
    total  = len(results)
    for name, ok in results:
        mark = '✓' if ok else '✗'
        print(f'  {mark} {name}')
    print(f'\n{passed}/{total} cenários passaram.')
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
