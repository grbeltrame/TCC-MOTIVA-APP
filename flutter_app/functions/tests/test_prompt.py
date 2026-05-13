"""
Smoke test do prompt_builder da IA do atleta.

Uso:
    cd flutter_app/functions
    python athlete_insights_module/test_prompt.py

Valida (sem chamar LLM):
  1. Geração dos prompts não levanta exceção.
  2. Prompts incluem o glossário completo dos campos de weekly_load/summary.
  3. Regra de 6-8 insights totais está presente.
  4. Regras absolutas (dicionário do atleta, zero perguntas) presentes.
  5. Não existem thresholds hardcoded (monotonia > 1.5, >30%, avgRpeAll > 8).
"""
from __future__ import annotations

import os
import sys
import types

_THIS_DIR    = os.path.dirname(os.path.abspath(__file__))
_FUNCTIONS_DIR = os.path.dirname(_THIS_DIR)
if _FUNCTIONS_DIR not in sys.path:
    sys.path.insert(0, _FUNCTIONS_DIR)

# ── Stubs: firebase_admin, google.cloud, langchain ───────────────────────────
# Precisam estar em sys.modules ANTES do import do módulo athlete_insights,
# porque __init__.py importa logic.py que puxa essas dependências.

if 'firebase_admin' not in sys.modules:
    _fa_pkg = types.ModuleType('firebase_admin')
    _fa_firestore = types.ModuleType('firebase_admin.firestore')
    class _StubQuery:
        DESCENDING = 'DESCENDING'
        ASCENDING  = 'ASCENDING'
    _fa_firestore.Query = _StubQuery
    _fa_firestore.SERVER_TIMESTAMP = '__SERVER_TS__'
    _fa_firestore.client = lambda: None
    _fa_pkg.firestore = _fa_firestore
    sys.modules['firebase_admin'] = _fa_pkg
    sys.modules['firebase_admin.firestore'] = _fa_firestore

if 'google.cloud.secretmanager' not in sys.modules:
    _g  = sys.modules.setdefault('google', types.ModuleType('google'))
    _gc = sys.modules.setdefault('google.cloud', types.ModuleType('google.cloud'))
    _sm = types.ModuleType('google.cloud.secretmanager')
    class _StubSmClient:
        def access_secret_version(self, request=None):
            raise RuntimeError('Secret Manager não disponível em teste local')
    _sm.SecretManagerServiceClient = _StubSmClient
    sys.modules['google.cloud.secretmanager'] = _sm
    _gc.secretmanager = _sm
    _g.cloud = _gc

if 'langchain_google_genai' not in sys.modules:
    _lc_google = types.ModuleType('langchain_google_genai')
    class _StubChat:
        def __init__(self, *_, **__): pass
        def invoke(self, *_args, **_kwargs):
            raise RuntimeError('LLM não disponível em teste local')
    _lc_google.ChatGoogleGenerativeAI = _StubChat
    sys.modules['langchain_google_genai'] = _lc_google

if 'pydantic' not in sys.modules:
    try:
        import pydantic  # type: ignore
    except Exception:
        _pd = types.ModuleType('pydantic')

        class _StubBaseModel:
            def __init__(self, **kwargs):
                for k, v in kwargs.items():
                    setattr(self, k, v)

        def _Field(*_args, **_kwargs):
            return None

        _pd.BaseModel = _StubBaseModel
        _pd.Field = _Field
        sys.modules['pydantic'] = _pd

if 'langchain_core.output_parsers' not in sys.modules:
    try:
        import langchain_core.output_parsers  # type: ignore
    except Exception:
        lc_pkg = sys.modules.setdefault('langchain_core', types.ModuleType('langchain_core'))
        lc_op  = types.ModuleType('langchain_core.output_parsers')

        class _StubParser:
            def __init__(self, pydantic_object=None):
                self._model = pydantic_object

            def get_format_instructions(self):
                return 'FORMAT_INSTRUCTIONS_PLACEHOLDER'

        lc_op.PydanticOutputParser = _StubParser
        sys.modules['langchain_core.output_parsers'] = lc_op
        lc_pkg.output_parsers = lc_op

try:
    from athlete_insights_module.prompt_builder import (
        create_weekly_insights_prompt,
        create_evolution_insights_prompt,
    )
except Exception as e:
    print(f'❌ Falha ao importar prompt_builder: {e}')
    sys.exit(1)


def _mock_weekly_load():
    return {
        'weekLabel':         '2026-W16',
        'weekStart':         '2026-04-19',
        'weekEnd':           '2026-04-25',
        'totalLoadAll':      640.0,
        'totalLoadCrossfit': 640.0,
        'totalLoadOther':    0.0,
        'icnAll':            75.3,
        'icnCrossfit':       75.3,
        'cargaCronica':      425.0,
        'acwrRaw':           1.506,
        'baselineType':      'partial_2_weeks',
        'avgRpeAll':         8.0,
        'avgRpeCrossfit':    8.0,
        'wodDays':           4,
        'otherDays':         0,
        'restDays':          3,
        'monotony':          1.1,
        'strain':            704.0,
        'restRatio':         0.43,
        'prsCount':          1,
        'dailyLoadsCrossfit': {'2026-04-19': 160, '2026-04-20': 160},
        'dailyLoadsOther':    {},
    }


def _mock_stats_summary():
    return {
        'totalTrainingDays':            42,
        'averageEffortAllTime':         7.1,
        'currentMonthTrainingDays':     16,
        'averageEffortCurrentMonth':    7.4,
        'currentWeekTrainingDays':      4,
        'averageEffortCurrentWeek':     8.0,
        'currentWeekStimuli':           {'Força': 2, 'Ritmo': 2},
        'currentWeekCalendar':          {'2026-04-19': 'wod'},
        'weeklyLoadAll':                640.0,
        'weeklyICN':                    75.3,
        'weeklyBaselineType':           'partial_2_weeks',
        'weekStart':                    '2026-04-19',
        'weekEnd':                      '2026-04-25',
    }


def _assert(ok, msg):
    mark = '✓' if ok else '❌ FAIL:'
    print(f'  {mark} {msg}')
    return ok


def _has_format_instructions(prompt):
    return (
        'FORMAT_INSTRUCTIONS_PLACEHOLDER' in prompt
        or '"required": ["alertas", "informacoes"]' in prompt
        or '"required": ["weeksAnalyzed", "alertas", "informacoes"]' in prompt
    )


def test_weekly_prompt():
    print('\n── Weekly prompt ─────────────────────────────')
    prompt = create_weekly_insights_prompt(
        stats_summary=_mock_stats_summary(),
        weekly_load=_mock_weekly_load(),
        recent_results=[{'date': '2026-04-19', 'effort': 8}],
        recent_weeks=[{
            'weekLabel': '2026-W15',
            'totalLoadAll': 450.0,
            'icnAll': 60.0,
            'baselineType': 'partial_1_weeks',
        }],
    )
    ok = True
    ok &= _assert(isinstance(prompt, str) and len(prompt) > 500,
                  f'prompt não-vazio (len={len(prompt)})')
    ok &= _assert('GLOSSÁRIO DOS CAMPOS' in prompt,
                  'glossário presente')
    ok &= _assert('DICIONÁRIO DO ATLETA' in prompt,
                  'dicionário do atleta presente')
    ok &= _assert('6 insights mais relevantes' in prompt,
                  'alvo de 6 insights (weekly) presente')
    ok &= _assert('NUNCA faça perguntas' in prompt,
                  'regra zero perguntas presente')
    ok &= _assert('cargaCronica' in prompt and 'acwrRaw' in prompt,
                  'novos campos ACWR explicados')
    ok &= _assert('baselineType' in prompt and 'cold_start' in prompt,
                  'baselineType documentado')
    ok &= _assert('CONTEXTO TEÓRICO' in prompt,
                  'contexto teórico (Gabbett/Foster) presente')
    ok &= _assert('CRUZAMENTO DE DADOS' in prompt,
                  'seção de cruzamento de dados presente')
    ok &= _assert('ALERTAS ACIONÁVEIS' in prompt,
                  'regra de alertas acionáveis presente')
    ok &= _assert('NUNCA retorne só alertas' in prompt,
                  'regra de distribuição obrigatória presente')
    # Não deve ter thresholds hardcoded antigos
    ok &= _assert('Monotonia > 1.5' not in prompt
                  and 'avgRpeAll > 8' not in prompt
                  and '>30% a mais' not in prompt,
                  'sem thresholds hardcoded antigos')
    ok &= _assert(_has_format_instructions(prompt),
                  'format instructions do parser incluídas')
    return ok


def test_evolution_prompt():
    print('\n── Evolution prompt ──────────────────────────')
    prompt = create_evolution_insights_prompt(
        stats_summary=_mock_stats_summary(),
        last_12_weeks=[
            {'weekLabel': '2026-W13', 'totalLoadAll': 420, 'icnAll': 50},
            {'weekLabel': '2026-W14', 'totalLoadAll': 450, 'icnAll': 55},
            {'weekLabel': '2026-W15', 'totalLoadAll': 480, 'icnAll': 58},
            {'weekLabel': '2026-W16', 'totalLoadAll': 640, 'icnAll': 75},
        ],
        prs_summary={'count': 3, 'byMovement': {'Clean': 2, 'Snatch': 1}},
        stimulus_distribution={'Força': 12, 'Ritmo': 8, 'Resistência': 2},
    )
    ok = True
    ok &= _assert(isinstance(prompt, str) and len(prompt) > 500,
                  f'prompt não-vazio (len={len(prompt)})')
    ok &= _assert('GLOSSÁRIO DOS CAMPOS' in prompt,
                  'glossário presente')
    ok &= _assert('10 insights mais relevantes' in prompt,
                  'alvo de 10 insights (evolution) presente')
    ok &= _assert('NUNCA faça perguntas' in prompt,
                  'regra zero perguntas presente')
    ok &= _assert('tendências' in prompt.lower(),
                  'foco em tendências')
    ok &= _assert('CONTEXTO TEÓRICO' in prompt,
                  'contexto teórico (Gabbett/Foster) presente')
    ok &= _assert('CRUZAMENTO DE DADOS' in prompt,
                  'seção de cruzamento de dados presente')
    ok &= _assert('ALERTAS ACIONÁVEIS' in prompt,
                  'regra de alertas acionáveis presente')
    ok &= _assert('Sweet Spot' in prompt or 'sweet spot' in prompt.lower(),
                  'regra de validação do Sweet Spot presente')
    ok &= _assert('stimulus_distribution' in prompt
                  and 'prs_summary' in prompt,
                  'cruzamento PRs × estímulos instruído')
    ok &= _assert(_has_format_instructions(prompt),
                  'format instructions do parser incluídas')
    return ok


def main():
    results = [
        ('weekly_prompt',    test_weekly_prompt()),
        ('evolution_prompt', test_evolution_prompt()),
    ]
    print('\n' + '=' * 50)
    print('RESULTADO')
    print('=' * 50)
    passed = sum(1 for _, ok in results if ok)
    for name, ok in results:
        mark = '✓' if ok else '✗'
        print(f'  {mark} {name}')
    print(f'\n{passed}/{len(results)} testes passaram.')
    sys.exit(0 if passed == len(results) else 1)


if __name__ == '__main__':
    main()
