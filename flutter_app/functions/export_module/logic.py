from datetime import date, datetime

from firebase_admin import firestore


def _json_safe(value):
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if hasattr(value, "to_datetime"):
        return value.to_datetime().isoformat()
    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_json_safe(v) for v in value]
    if isinstance(value, tuple):
        return [_json_safe(v) for v in value]
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    return str(value)


def _export_doc_tree(doc_ref) -> dict:
    snap = doc_ref.get()
    data = snap.to_dict() if snap.exists else {}
    collections = {}
    for collection_ref in doc_ref.collections():
        collections[collection_ref.id] = {
            child.id: _export_doc_tree(child.reference)
            for child in collection_ref.stream()
        }
    return {
        "id": doc_ref.id,
        "exists": snap.exists,
        "data": _json_safe(data or {}),
        "collections": collections,
    }


def export_user_data(uid: str, db=None) -> dict:
    db = db or firestore.client()
    exercises = {}
    for exercise in (
        db.collection("exercises")
        .where("createdByUid", "==", uid)
        .stream()
    ):
        exercises[exercise.id] = _json_safe(exercise.to_dict() or {})

    return {
        "uid": uid,
        "exportedAt": datetime.utcnow().isoformat() + "Z",
        "user": _export_doc_tree(db.collection("users").document(uid)),
        "exercises": exercises,
    }

