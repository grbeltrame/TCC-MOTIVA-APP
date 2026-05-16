from __future__ import annotations


def _user_data(db, uid: str) -> dict:
    snap = db.collection("users").document(uid).get()
    if not snap.exists:
        return {}
    return snap.to_dict() or {}


def _settings_data(db, uid: str, doc_id: str) -> dict:
    snap = (
        db.collection("users")
        .document(uid)
        .collection("settings")
        .document(doc_id)
        .get()
    )
    if not snap.exists:
        return {}
    return snap.to_dict() or {}


def is_account_disabled(db, uid: str, user_data: dict | None = None) -> bool:
    data = user_data if user_data is not None else _user_data(db, uid)
    return data.get("accountStatus") == "disabled"


def athlete_ai_enabled(db, uid: str) -> bool:
    if is_account_disabled(db, uid):
        return False
    privacy = _settings_data(db, uid, "privacy")
    return privacy.get("aiPersonalizationEnabled", True) is not False
