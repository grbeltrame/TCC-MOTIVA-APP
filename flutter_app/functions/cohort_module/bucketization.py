# functions/cohort_module/bucketization.py
#
# Funções puras de normalização dos campos de perfil para a chave de coorte.
# Determinísticas, testáveis isoladamente, sem dependência de Firestore.
#
# Decisões fechadas:
# - Coorte = Nível 3: category + gender + experience_bucket (mínimo).
# - Peso/altura: opcionais — não entram na chave.
# - "Outro" gender: skip cohort (pool muito pequeno para inferência).
# - Atleta sem qualquer um dos 3 campos obrigatórios → sem coorte.

from __future__ import annotations

from typing import Optional, Tuple


# ============================================================================
# CATEGORY
# ============================================================================
# Valores válidos no app (athlete_edit_profile_screen.dart):
#   'Iniciante', 'Scaled', 'Intermediário', 'RX', 'Elite'

_CATEGORY_MAP = {
    'INICIANTE':     'INICIANTE',
    'SCALED':        'SCALED',
    'INTERMEDIARIO': 'INTERMEDIARIO',
    'INTERMEDIÁRIO': 'INTERMEDIARIO',
    'RX':            'RX',
    'ELITE':         'ELITE',
}


def normalize_category(raw) -> Optional[str]:
    """
    Recebe o valor cru de `category` do perfil e retorna a chave canônica
    (sem acentos, uppercase). None se não for um valor válido.
    """
    if raw is None:
        return None
    key = str(raw).strip().upper()
    return _CATEGORY_MAP.get(key)


# ============================================================================
# GENDER
# ============================================================================
# Valores válidos no app: 'Homem', 'Mulher', 'Outro'.
# 'Outro' tende a ter pool insuficiente — tratado como não-elegível para
# comparação de coorte (atleta recebe insights normais sem comparação).

_GENDER_MAP = {
    'HOMEM':     'M',
    'MASCULINO': 'M',
    'M':         'M',
    'MULHER':    'F',
    'FEMININO':  'F',
    'F':         'F',
}


def normalize_gender(raw) -> Optional[str]:
    """
    Retorna 'M' ou 'F'. None para 'Outro' ou valores inválidos —
    nesses casos o atleta não entra em comparação de coorte.
    """
    if raw is None:
        return None
    key = str(raw).strip().upper()
    return _GENDER_MAP.get(key)


# ============================================================================
# PRACTICE YEARS (experience bucket)
# ============================================================================
# Valores válidos no dropdown:
#   'Menos de 1 ano', 'Entre 1 e 3 anos', 'Entre 3 e 5 anos', 'Mais de 5 anos'
#
# Buckets: 'lt1y', '1-3y', '3-5y', 'gt5y'

_PRACTICE_MAP = {
    'MENOS DE 1 ANO':    'lt1y',
    'ENTRE 1 E 3 ANOS':  '1-3y',
    'ENTRE 3 E 5 ANOS':  '3-5y',
    'MAIS DE 5 ANOS':    'gt5y',
}


def normalize_practice_years(raw) -> Optional[str]:
    """
    Mapeia o valor textual do dropdown para a chave canônica do bucket.
    Tolera variações: caps, espaços extras, vírgulas residuais.
    Retorna None para valores não reconhecidos — atleta sem coorte.
    """
    if raw is None:
        return None
    text = str(raw).strip()
    if not text:
        return None
    # Normaliza espaços múltiplos
    text = ' '.join(text.split()).upper()
    return _PRACTICE_MAP.get(text)


# ============================================================================
# COHORT KEY BUILDER
# ============================================================================

def build_cohort_keys(profile: dict) -> Tuple[Optional[str], Optional[str]]:
    """
    Recebe o doc de perfil (users/{uid}/profiles/athlete) e retorna
    (level3_key, level2_key).

    - level3_key: '{CATEGORY}_{GENDER}_{BUCKET}' — chave principal.
    - level2_key: '{CATEGORY}_{GENDER}'         — fallback.

    Retorna (None, None) se algum campo essencial faltar para qualquer
    nível (atleta não recebe insights comparativos).
    """
    cat    = normalize_category(profile.get('category'))
    gender = normalize_gender(profile.get('gender'))
    bucket = normalize_practice_years(profile.get('practiceYears'))

    if cat is None or gender is None:
        # Sem categoria OU gênero → nem level 2 dá pra montar.
        return (None, None)

    level2 = f'{cat}_{gender}'
    level3 = f'{cat}_{gender}_{bucket}' if bucket else None

    return (level3, level2)
