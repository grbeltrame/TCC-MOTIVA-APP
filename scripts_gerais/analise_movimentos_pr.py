# requirements: pip install firebase-admin
"""
Analisa a coleção `movimentos` do Firestore e classifica cada exercício
pelo tipo de PR (Personal Record) que faz sentido registrar.

Tipos de PR possíveis:
  - weight   → carga máxima (kg)              → ex: Back Squat, Snatch
  - reps     → repetições máximas             → ex: Pull-up, Push-up
  - time     → tempo máximo em posição (s)    → ex: Plank, Dead Hang
  - distance → distância máxima (m/km)        → ex: Run, Row, Bike

Saída: JSON em `analise_movimentos_pr_result.json` no mesmo diretório,
com classificação + estatísticas agregadas por categoria e por tipo de PR.
"""

from __future__ import annotations

import json
import os
import re
import sys
import unicodedata
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import firebase_admin
from firebase_admin import credentials, firestore

# -----------------------------------------------------------------------------
# Inicialização Firebase
# -----------------------------------------------------------------------------

_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ID = "motiva-andre"


def _init_firebase() -> None:
    """
    Tenta inicializar o Firebase Admin.

    Usa Application Default Credentials configuradas no ambiente local.
    """
    if firebase_admin._apps:
        return

    firebase_admin.initialize_app(
        credentials.ApplicationDefault(),
        {"projectId": _PROJECT_ID},
    )


_init_firebase()
db = firestore.client()

# -----------------------------------------------------------------------------
# Heurísticas de classificação
# -----------------------------------------------------------------------------

# Tipo primário de PR + unidade sugerida.
PR_TYPES = {
    "weight":   {"unit": "kg",    "label": "Carga máxima"},
    "reps":     {"unit": "reps",  "label": "Repetições máximas"},
    "time":     {"unit": "s",     "label": "Tempo na posição"},
    "distance": {"unit": "m",     "label": "Distância percorrida"},
}

# Palavras-chave (normalizadas) para cada tipo.
# A ordem importa: a primeira regra que bate define o tipo primário.
_DISTANCE_KEYWORDS = [
    "run", "corrida", "sprint",
    "row", "remo", "remada ergometro", "remo ergometro",
    "bike", "assault bike", "air bike", "ciclismo",
    "ski", "ski erg", "skierg",
    "swim", "nado", "natacao",
    "walk", "caminhada", "rucking", "ruck",
    "farmer carry", "farmer walk", "suitcase carry",
    "sled push", "sled pull", "prowler",
]

_TIME_KEYWORDS = [
    "plank", "prancha",
    "hold", "isometric", "isometria",
    "dead hang", "hanging hold", "barra pendurado",
    "l-sit", "l sit",
    "handstand hold", "parada de mao estatica",
    "wall sit", "cadeirinha",
    "bridge hold",
    "chin over bar hold",
    "front lever hold", "back lever hold",
    "ring support hold", "support hold",
]

# Exercícios explicitamente só-reps (ginástica/bodyweight clássicos).
_REPS_KEYWORDS = [
    "pull up", "pull-up", "pullup", "barra fixa",
    "chin up", "chin-up",
    "chest to bar", "c2b", "ctb",
    "toes to bar", "t2b", "ttb",
    "knees to elbow", "k2e",
    "muscle up", "muscle-up", "bar muscle up", "ring muscle up",
    "push up", "push-up", "pushup", "flexao",
    "handstand push up", "hspu",
    "burpee", "burpees",
    "sit up", "situp", "abdominal",
    "air squat", "agachamento livre",
    "pistol", "pistol squat",
    "double under", "single under", "pular corda",
    "box jump", "box step up", "step up",
    "wall ball",
    "dip", "dips", "ring dip", "bar dip",
    "jumping jack", "polichinelo",
    "mountain climber",
    "lunges", "afundo",
    "v up", "v-up",
    "hollow rock", "superman",
    "kipping", "butterfly",
]

# Categorias que já indicam o tipo principal.
_CATEGORY_HINTS = {
    "lpo": "weight",          # Levantamento de Peso Olímpico
    "weightlifting": "weight",
    "powerlifting": "weight",
    "olympic": "weight",
    "gym": "reps",            # Ginástica
    "gymnastics": "reps",
    "ginastica": "reps",
    "endurance": "distance",
    "cardio": "distance",
    "monostructural": "distance",
    "mono": "distance",
}

# Equipamentos que indicam o tipo.
_EQUIPMENT_HINTS = {
    "barbell": "weight",
    "dumbbell": "weight",
    "kettlebell": "weight",
    "trap bar": "weight",
    "barra": "weight",
    "halter": "weight",
    "rower": "distance",
    "rowing": "distance",
    "bike": "distance",
    "assault bike": "distance",
    "echo bike": "distance",
    "ski erg": "distance",
    "skierg": "distance",
    "treadmill": "distance",
    "esteira": "distance",
    "jump rope": "reps",
    "corda": "reps",
    "pull up bar": "reps",
    "rings": "reps",
    "parallel bars": "reps",
    "wall ball": "reps",
    "box": "reps",
}

# Movimentos clássicos de barra/haltere que aceitam peso.
# Quando o nome bate, priorizamos weight mesmo se a categoria não for lpo.
_WEIGHT_NAME_KEYWORDS = [
    "snatch", "arranco",
    "clean", "jerk", "arremesso",
    "deadlift", "levantamento terra", "terra",
    "back squat", "front squat", "overhead squat", "agachamento",
    "press", "shoulder press", "push press", "push jerk", "strict press",
    "bench press", "supino",
    "thruster",
    "row barbell", "bent over row", "remada curvada",
    "good morning",
    "hip thrust",
    "lunge barbell",
    "clean and jerk", "clean & jerk",
    "high pull",
    "power clean", "power snatch",
    "muscle clean", "muscle snatch",
    "hang clean", "hang snatch",
    "split jerk",
    "turkish get up",
]

# -----------------------------------------------------------------------------
# Overrides explícitos — casos ambíguos onde as heurísticas gerais erram.
# Formato: (substring no nome, tipo primário, tipos suportados)
# Primeiro match vence.
# -----------------------------------------------------------------------------
_EXPLICIT_OVERRIDES: List[Tuple[str, str, List[str]]] = [
    # Bodyweight squats → reps (não entram no keyword "squat")
    ("air squat",         "reps", ["reps"]),
    ("pistol",            "reps", ["reps"]),
    ("single-leg squat",  "reps", ["reps"]),
    ("single leg squat",  "reps", ["reps"]),
    # Ring row é puxada invertida, não remo ergométrico
    ("ring row",          "reps", ["reps"]),
    # Walking/Static lunges — reps primário; pode ser carregado com peso
    ("lunges",            "reps", ["reps", "weight"]),
    ("lunge",             "reps", ["reps", "weight"]),
    ("afundo",            "reps", ["reps", "weight"]),
    # Kettlebell swing — reps (carga fixa)
    ("kettlebell swing",  "reps", ["reps"]),
    ("kb swing",          "reps", ["reps"]),
    # Farmers carry — distância carregando peso
    ("farmers carry",     "distance", ["distance", "weight"]),
    ("farmer carry",      "distance", ["distance", "weight"]),
    ("farmers walk",      "distance", ["distance", "weight"]),
    ("farmer walk",       "distance", ["distance", "weight"]),
    # Wall ball (bola de peso fixo)
    ("wall ball",         "reps", ["reps"]),
    # Box jumps são reps
    ("box jump",          "reps", ["reps"]),
    # Double/single unders
    ("double under",      "reps", ["reps"]),
    ("single under",      "reps", ["reps"]),
    # Burpees
    ("burpee",            "reps", ["reps"]),
]


def _normalize(text: str) -> str:
    """Remove acentos, lowercase, remove pontuação redundante."""
    if not text:
        return ""
    nfkd = unicodedata.normalize("NFKD", text)
    no_accent = "".join(c for c in nfkd if not unicodedata.combining(c))
    no_accent = no_accent.lower()
    no_accent = re.sub(r"[^a-z0-9\s\-]", " ", no_accent)
    no_accent = re.sub(r"\s+", " ", no_accent).strip()
    return no_accent


def _match_any(haystack: str, keywords: List[str]) -> Optional[str]:
    for kw in keywords:
        if kw in haystack:
            return kw
    return None


def classify_movement(
    display_name: str,
    categories: List[str],
    equipment: List[str],
) -> Dict:
    """
    Classifica um movimento em (primary_pr_type, supported_pr_types, reason).

    Estratégia:
      1. Nome do movimento é o sinal mais forte (ex: "Back Squat" → weight).
      2. Lista de keywords por tipo aplica no nome normalizado.
      3. Categorias complementam quando o nome é ambíguo.
      4. Equipamentos servem de desempate.
      5. Fallback: reps (maioria dos movimentos sem outro sinal).
    """
    name_norm = _normalize(display_name)
    cats_norm = [_normalize(c) for c in (categories or [])]
    equip_norm = [_normalize(e) for e in (equipment or [])]

    reasons: List[str] = []
    supported: set = set()
    primary: Optional[str] = None

    # --- 0. Overrides explícitos (casos ambíguos onde a heurística erra)
    for override_kw, override_type, override_supported in _EXPLICIT_OVERRIDES:
        if override_kw in name_norm:
            primary = override_type
            for t in override_supported:
                supported.add(t)
            reasons.append(f'override explícito: "{override_kw}" → {override_type}')
            break

    # --- 1. Keywords de tempo (isométricos) — sinal muito específico
    if primary is None:
        match = _match_any(name_norm, _TIME_KEYWORDS)
        if match:
            primary = "time"
            supported.add("time")
            reasons.append(f'nome contém "{match}" (isométrico)')

    # --- 2. Keywords de distância (cardio/monostructural)
    if primary is None:
        match = _match_any(name_norm, _DISTANCE_KEYWORDS)
        if match:
            primary = "distance"
            supported.add("distance")
            supported.add("time")  # cardio também aceita PR de tempo p/ distância fixa
            reasons.append(f'nome contém "{match}" (cardio/distância)')

    # --- 3. Nome indica levantamento com carga
    if primary is None:
        match = _match_any(name_norm, _WEIGHT_NAME_KEYWORDS)
        if match:
            primary = "weight"
            supported.add("weight")
            reasons.append(f'nome contém "{match}" (levantamento com carga)')

    # --- 4. Keywords explícitas de reps (ginástica clássica)
    if primary is None:
        match = _match_any(name_norm, _REPS_KEYWORDS)
        if match:
            primary = "reps"
            supported.add("reps")
            reasons.append(f'nome contém "{match}" (ginástica/bodyweight)')

    # --- 5. Categorias (fallback suave)
    for cat in cats_norm:
        hint = _CATEGORY_HINTS.get(cat)
        if hint:
            supported.add(hint)
            if primary is None:
                primary = hint
                reasons.append(f'categoria "{cat}" sugere {hint}')

    # --- 6. Equipamento (fallback)
    for eq in equip_norm:
        for eq_key, hint in _EQUIPMENT_HINTS.items():
            if eq_key in eq:
                supported.add(hint)
                if primary is None:
                    primary = hint
                    reasons.append(f'equipamento "{eq}" sugere {hint}')
                break

    # --- 7. Fallback final
    if primary is None:
        primary = "reps"
        supported.add("reps")
        reasons.append("sem sinais claros — fallback para reps")

    # Para levantamentos com barra/haltere, reps também é registrável
    # (ex: 10RM de Back Squat).
    if primary == "weight":
        supported.add("reps")

    return {
        "primaryPrType": primary,
        "supportedPrTypes": sorted(supported),
        "unit": PR_TYPES[primary]["unit"],
        "reason": "; ".join(reasons),
    }


# -----------------------------------------------------------------------------
# Pipeline principal
# -----------------------------------------------------------------------------

def fetch_movimentos() -> List[Dict]:
    """Busca todos os documentos de `movimentos` com os campos que nos interessam."""
    docs = db.collection("movimentos").stream()
    out: List[Dict] = []
    for d in docs:
        data = d.to_dict() or {}
        out.append({
            "id": d.id,
            "displayName": data.get("displayName") or data.get("name") or "",
            "categories": data.get("categories") or [],
            "equipment": data.get("equipment") or [],
            "primaryMuscles": data.get("primaryMuscles") or [],
        })
    return out


def build_report(movements: List[Dict]) -> Dict:
    classified: List[Dict] = []
    by_category: Dict[str, int] = {}
    by_pr_type: Dict[str, int] = {}
    by_category_and_pr: Dict[str, Dict[str, int]] = {}

    for m in movements:
        result = classify_movement(
            m["displayName"], m["categories"], m["equipment"]
        )
        row = {
            **m,
            **result,
        }
        classified.append(row)

        # Agregações
        pr = result["primaryPrType"]
        by_pr_type[pr] = by_pr_type.get(pr, 0) + 1

        cats = m["categories"] or ["(sem categoria)"]
        for c in cats:
            by_category[c] = by_category.get(c, 0) + 1
            by_category_and_pr.setdefault(c, {})
            by_category_and_pr[c][pr] = by_category_and_pr[c].get(pr, 0) + 1

    # Ordena classified por categoria → nome (para facilitar revisão humana)
    def _sort_key(item: Dict) -> Tuple[str, str]:
        cats = item.get("categories") or [""]
        return (cats[0] if cats else "", item["displayName"].lower())

    classified.sort(key=_sort_key)

    return {
        "generatedAt": datetime.now().isoformat(),
        "totalMovements": len(classified),
        "summary": {
            "byPrType": dict(sorted(by_pr_type.items())),
            "byCategory": dict(sorted(by_category.items())),
            "byCategoryAndPrType": {
                k: dict(sorted(v.items()))
                for k, v in sorted(by_category_and_pr.items())
            },
        },
        "prTypes": PR_TYPES,
        "movements": classified,
    }


def print_summary(report: Dict) -> None:
    print(f"\n{'='*70}")
    print(f"  Análise de Movimentos → PR Types")
    print(f"{'='*70}")
    print(f"Total de movimentos: {report['totalMovements']}")
    print(f"\nPor tipo de PR (primário):")
    for k, v in report["summary"]["byPrType"].items():
        label = PR_TYPES.get(k, {}).get("label", k)
        print(f"  {k:10s} ({label:30s}) → {v}")

    print(f"\nPor categoria:")
    for k, v in report["summary"]["byCategory"].items():
        print(f"  {k:25s} → {v}")

    print(f"\nPor categoria × tipo de PR:")
    for cat, prs in report["summary"]["byCategoryAndPrType"].items():
        prs_str = ", ".join(f"{k}={v}" for k, v in prs.items())
        print(f"  {cat:25s} → {prs_str}")


def save_report(report: Dict) -> str:
    out_path = os.path.join(_THIS_DIR, "analise_movimentos_pr_result.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    return out_path


def write_pr_types_to_firestore(report: Dict) -> None:
    """
    Escreve `prType` e `supportedPrTypes` em cada doc de `movimentos/`.
    Usa batch para minimizar round-trips.
    """
    movements = report["movements"]
    batch = db.batch()
    col = db.collection("movimentos")
    written = 0

    for m in movements:
        doc_id = m["id"]
        ref = col.document(doc_id)
        batch.update(ref, {
            "prType": m["primaryPrType"],
            "supportedPrTypes": m["supportedPrTypes"],
            "prUnit": m["unit"],
        })
        written += 1

        # Firestore batch limit: 500 ops
        if written % 400 == 0:
            batch.commit()
            batch = db.batch()

    batch.commit()
    print(f"\n✓ {written} movimentos atualizados no Firestore com prType/supportedPrTypes/prUnit.")


if __name__ == "__main__":
    write_mode = "--write" in sys.argv

    print("Buscando movimentos do Firestore...")
    movements = fetch_movimentos()
    print(f"  → {len(movements)} movimentos encontrados.")

    print("Classificando...")
    report = build_report(movements)

    out_path = save_report(report)
    print_summary(report)

    print(f"\n✓ Relatório completo salvo em:\n  {out_path}")

    if write_mode:
        print("\n[WRITE MODE] Atualizando documentos no Firestore...")
        write_pr_types_to_firestore(report)
    else:
        print("\n(rode com --write para persistir prType nos documentos)")
    print()
