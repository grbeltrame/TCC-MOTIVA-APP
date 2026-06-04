# upload_movimentos.py
# Substitui TODA a coleção `movimentos` no Firestore pelo conteúdo de movimentos.json.
# Cada doc usa o campo `name` como doc ID.
#
# Uso: python upload_movimentos.py

import json
import os

import firebase_admin
from firebase_admin import credentials, firestore

_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJECT_ID = "motiva-8b82f"

if not firebase_admin._apps:
    try:
        firebase_admin.initialize_app(
            credentials.ApplicationDefault(),
            {"projectId": _PROJECT_ID},
        )
    except Exception:
        cred_path = os.path.join(
            _THIS_DIR, "motiva-8b82f-firebase-adminsdk-fbsvc-14d8d2b5e8.json"
        )
        firebase_admin.initialize_app(credentials.Certificate(cred_path))

db = firestore.client()
col = db.collection("movimentos")

# 1. Ler JSON local
json_path = os.path.join(_THIS_DIR, "movimentos.json")
with open(json_path, "r", encoding="utf-8") as f:
    movements = json.load(f)

print(f"JSON carregado: {len(movements)} movimentos.\n")

# 2. Apagar todos os docs atuais
print("Apagando documentos existentes...")
existing = col.stream()
deleted = 0
batch = db.batch()
for doc in existing:
    batch.delete(col.document(doc.id))
    deleted += 1
    if deleted % 400 == 0:
        batch.commit()
        batch = db.batch()
batch.commit()
print(f"  → {deleted} documentos apagados.\n")

# 3. Criar novos docs (name como doc ID)
print("Enviando novos documentos...")
batch = db.batch()
written = 0
for m in movements:
    doc_id = m["name"]
    batch.set(col.document(doc_id), m)
    written += 1
    if written % 400 == 0:
        batch.commit()
        batch = db.batch()
batch.commit()
print(f"  → {written} documentos criados.\n")

print("✓ Coleção `movimentos` atualizada com sucesso.")
