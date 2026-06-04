# functions/cohort_module/matching.py
#
# Resolve a coorte de um atleta no momento de gerar insights.
# Lê de cohorts/{cohort_key} (pré-computado pelo job de agregação).
#
# Estratégia de fallback:
#   1. Tenta level 3 (CATEGORY_GENDER_BUCKET).
#   2. Se ausente (coorte < 5 atletas), cai para level 2 (CATEGORY_GENDER).
#   3. Se ainda assim ausente, retorna None — atleta NÃO recebe insight
#      comparativo (e o prompt deve omitir o bloco de coorte).

from __future__ import annotations

import logging
from typing import Optional

from .bucketization import build_cohort_keys


def find_athlete_cohort(uid: str, db) -> Optional[dict]:
    """
    Retorna o snapshot da coorte do atleta, ou None se o atleta não tem
    perfil completo ou nenhuma coorte (level 3 nem level 2) está disponível.

    O dict retornado é o conteúdo bruto de cohorts/{key} acrescido do
    nível usado, para a IA poder calibrar o tom da comparação:

        {
          'cohortKey': 'RX_M_1-3y',
          'level': 3,                # ou 2 (fallback)
          'category': 'RX',
          'gender': 'M',
          'experienceBucket': '1-3y',  # None se level 2
          'athleteCount': 47,
          'weekLabel': '2026-W17',
          'metrics': { ... },
        }
    """
    try:
        prof_doc = db.collection('users').document(uid) \
                     .collection('profiles').document('athlete').get()
    except Exception as e:
        logging.warning(f'[cohort-match] {uid}: falha ao ler perfil: {e}')
        return None

    if not prof_doc.exists:
        return None

    l3, l2 = build_cohort_keys(prof_doc.to_dict() or {})
    if l2 is None:
        # Perfil incompleto (ou 'Outro' gender) — sem coorte.
        return None

    cohorts_ref = db.collection('cohorts')

    # 1) Tenta level 3
    if l3 is not None:
        try:
            doc = cohorts_ref.document(l3).get()
            if doc.exists:
                data = doc.to_dict() or {}
                if data:
                    return data
        except Exception as e:
            logging.warning(f'[cohort-match] {uid}: falha em {l3}: {e}')

    # 2) Fallback level 2
    try:
        doc = cohorts_ref.document(l2).get()
        if doc.exists:
            data = doc.to_dict() or {}
            if data:
                return data
    except Exception as e:
        logging.warning(f'[cohort-match] {uid}: falha em {l2}: {e}')

    return None
