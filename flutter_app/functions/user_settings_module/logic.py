from __future__ import annotations

_ATHLETE_NOTIFICATION_KEYS = {
    "athlete_weekly_insights_ready": "weeklyInsights",
    "athlete_evolution_insights_ready": "evolutionInsights",
    "athlete_pre_workout_insights_ready": "preWorkoutInsights",
    "athlete_daily_result_reminder": "trainingReminders",
}

_COACH_NOTIFICATION_KEYS = {
    "coach_daily_analysis_ready": "dailyTrainingAnalysis",
    "coach_cycle_analysis_ready": "cycleAnalysis",
    "coach_missing_training_reminder": "missingTrainingReminder",
}


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


def notification_enabled(
    db,
    uid: str,
    role: str,
    type_: str,
    user_data: dict | None = None,
) -> bool:
    if is_account_disabled(db, uid, user_data=user_data):
        return False

    if role == "coach":
        key = _COACH_NOTIFICATION_KEYS.get(type_)
        if key is None:
            return True
        settings = _settings_data(db, uid, "coach")
        return settings.get(key, True) is not False

    key = _ATHLETE_NOTIFICATION_KEYS.get(type_)
    if key is None:
        return True
    settings = _settings_data(db, uid, "athlete")
    return settings.get(key, True) is not False
