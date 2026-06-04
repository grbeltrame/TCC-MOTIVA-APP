# requirements: pip install firebase-admin
import firebase_admin
from firebase_admin import credentials, firestore
import json
from typing import Optional, List, Dict

# Inicialize com o arquivo de chave de serviço (service account JSON)
# Ou use ADC deixando out the Certificate and relying on env var GOOGLE_APPLICATION_CREDENTIALS
cred = credentials.Certificate("motiva-8b82f-firebase-adminsdk-fbsvc-14d8d2b5e8.json")
firebase_admin.initialize_app(cred)
fs = firestore.client()

def get_collection(collection_name: str) -> List[Dict]:
    """Retorna todos os documentos da coleção como lista de dicts (inclui _id)."""
    docs = fs.collection(collection_name).stream()
    result = []
    for d in docs:
        data = d.to_dict() or {}
        data["_id"] = d.id
        result.append(data)
    return result

def get_document(collection_name: str, doc_id: str) -> Optional[Dict]:
    """Retorna um documento específico (ou None se não existir)."""
    ref = fs.collection(collection_name).document(doc_id)
    snap = ref.get()
    if snap.exists:
        data = snap.to_dict() or {}
        data["_id"] = snap.id
        return data
    return None

if __name__ == "__main__":
    colecao = get_collection("exercises")
    documento = get_document("exercises", "Yz2JObASlOPRoCyy5UMC")

    print("Coleção (JSON):")
    print(json.dumps(colecao, ensure_ascii=False, indent=2))
    print("\nDocumento (JSON):")
    print(json.dumps(documento, ensure_ascii=False, indent=2))
