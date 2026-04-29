import hashlib
import logging
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

from firebase_admin import firestore, messaging
from user_settings_module import notification_enabled

_TZ_BRAZIL = ZoneInfo("America/Sao_Paulo")
_HYBRID_PROFILES = {"athleteCoach", "athleteIntern"}
_COACH_PROFILES = {"coach", "intern", "athleteCoach", "athleteIntern"}
_ATHLETE_PROFILES = {"athlete", "athleteCoach", "athleteIntern"}
NOTIFICATION_RETENTION_DAYS = 7
_NOTIFICATION_CLEANUP_BATCH_SIZE = 450


def _date_key(day: datetime) -> str:
    return day.strftime("%Y-%m-%d")


def _stable_hour(seed: str, start_hour: int, end_hour: int) -> int:
    digest = int(hashlib.md5(seed.encode()).hexdigest(), 16)
    return start_hour + (digest % (end_hour - start_hour + 1))


def _safe_doc_id(value: str) -> str:
    return (
        value.replace("/", "_")
        .replace("#", "_")
        .replace("[", "_")
        .replace("]", "_")
        .replace(".", "_")
    )


def _notification_expires_at(now: datetime | None = None) -> datetime:
    base = now or datetime.now(tz=_TZ_BRAZIL)
    return base + timedelta(days=NOTIFICATION_RETENTION_DAYS)


def _notification_retention_cutoff(now: datetime | None = None) -> datetime:
    base = now or datetime.now(tz=_TZ_BRAZIL)
    return base - timedelta(days=NOTIFICATION_RETENTION_DAYS)


def _with_role_prefix(title: str, role: str, profile: str | None) -> str:
    if profile not in _HYBRID_PROFILES:
        return title
    prefix = "[coach]" if role == "coach" else "[atleta]"
    if title.startswith(prefix):
        return title
    return f"{prefix} {title}"


def _send_push_to_user(db, uid: str, title: str, body: str, data: dict) -> None:
    try:
        token_docs = (
            db.collection("users")
            .document(uid)
            .collection("notificationTokens")
            .where("enabled", "==", True)
            .stream()
        )
        tokens = []
        for doc in token_docs:
            token = (doc.to_dict() or {}).get("token") or doc.id
            if token:
                tokens.append(token)

        for token in tokens:
            messaging.send(
                messaging.Message(
                    token=token,
                    notification=messaging.Notification(title=title, body=body),
                    data={k: str(v) for k, v in data.items() if v is not None},
                )
            )
    except Exception as exc:
        logging.warning(f"[notifications] falha ao enviar push uid={uid}: {exc}")


def create_user_notification(
    db,
    uid: str,
    role: str,
    type_: str,
    title: str,
    body: str,
    dedupe_key: str,
    route_name: str | None = None,
    route_args: dict | None = None,
    source_id: str | None = None,
) -> bool:
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()
    if not user_doc.exists:
        return False

    user_data = user_doc.to_dict() or {}
    if not notification_enabled(db, uid, role, type_, user_data=user_data):
        return False

    profile = user_data.get("profile")
    notification_ref = user_ref.collection("notifications").document(
        _safe_doc_id(dedupe_key)
    )

    if notification_ref.get().exists:
        return False

    now = firestore.SERVER_TIMESTAMP
    notification_ref.set(
        {
            "role": role,
            "type": type_,
            "title": title,
            "body": body,
            "status": "unread",
            "createdAt": now,
            "expiresAt": _notification_expires_at(),
            "readAt": None,
            "dedupeKey": dedupe_key,
            "routeName": route_name,
            "routeArgs": route_args or {},
            "sourceId": source_id,
        }
    )

    push_title = _with_role_prefix(title, role, profile)
    _send_push_to_user(
        db,
        uid,
        push_title,
        body,
        {
            "notificationId": notification_ref.id,
            "role": role,
            "type": type_,
            "routeName": route_name,
            "sourceId": source_id,
        },
    )
    return True


def notify_all_coaches(
    db,
    type_: str,
    title: str,
    body: str,
    dedupe_key: str,
    route_name: str | None = None,
    route_args: dict | None = None,
    source_id: str | None = None,
) -> int:
    created = 0
    for profile in _COACH_PROFILES:
        users = db.collection("users").where("profile", "==", profile).stream()
        for user_doc in users:
            if create_user_notification(
                db=db,
                uid=user_doc.id,
                role="coach",
                type_=type_,
                title=title,
                body=body,
                dedupe_key=f"{dedupe_key}:{user_doc.id}",
                route_name=route_name,
                route_args=route_args,
                source_id=source_id,
            ):
                created += 1
    return created


def delete_expired_notifications(
    db=None,
    now: datetime | None = None,
    batch_size: int = _NOTIFICATION_CLEANUP_BATCH_SIZE,
) -> dict:
    db = db or firestore.client()
    cutoff = _notification_retention_cutoff(now)
    deleted = 0

    while True:
        expired_docs = list(
            db.collection_group("notifications")
            .where("createdAt", "<=", cutoff)
            .limit(batch_size)
            .stream()
        )
        if not expired_docs:
            break

        batch = db.batch()
        for doc in expired_docs:
            batch.delete(doc.reference)
        batch.commit()

        deleted += len(expired_docs)
        if len(expired_docs) < batch_size:
            break

    return {"deleted": deleted, "cutoff": cutoff.isoformat()}


def _has_result_for_date(db, uid: str, date_key: str) -> bool:
    docs = (
        db.collection("users")
        .document(uid)
        .collection("results")
        .where("date", "==", date_key)
        .limit(1)
        .stream()
    )
    return any(True for _ in docs)


def _has_result_since(db, uid: str, date_key: str) -> bool:
    docs = (
        db.collection("users")
        .document(uid)
        .collection("results")
        .where("date", ">=", date_key)
        .limit(1)
        .stream()
    )
    return any(True for _ in docs)


def _has_training_for_date(db, date_key: str) -> bool:
    docs = (
        db.collection("exercises")
        .where("dataTreinoIso", "==", date_key)
        .stream()
    )
    return any((doc.to_dict() or {}).get("status") == "publicado" for doc in docs)


def _athlete_reminder_copy(now: datetime, week_start_key: str, has_week_result: bool):
    if now.weekday() == 0 and 8 <= now.hour <= 12:
        return (
            "A semana começou",
            "Uma ótima hora para começar bem ou manter a constância nos treinos.",
        )
    if not has_week_result and now.weekday() >= 2:
        return (
            "Vamos manter a constância?",
            "Ainda dá tempo de registrar um treino esta semana e acompanhar sua evolução.",
        )
    return (
        "Seu registro de hoje está pendente",
        "Você ainda não registrou como foi seu treino hoje.",
    )


def run_hourly_notification_reminders() -> dict:
    db = firestore.client()
    now = datetime.now(tz=_TZ_BRAZIL)
    today_key = _date_key(now)
    week_start = now - timedelta(days=now.weekday())
    week_start_key = _date_key(week_start)
    created = {"athlete": 0, "coach": 0}

    if not (9 <= now.hour <= 18 or (now.weekday() == 0 and 8 <= now.hour <= 12)):
        return {"skipped": "outside_window", "now": now.isoformat(), **created}

    has_training_today = _has_training_for_date(db, today_key)
    for user_doc in db.collection("users").stream():
        uid = user_doc.id
        data = user_doc.to_dict() or {}
        profile = data.get("profile")

        if profile in _ATHLETE_PROFILES:
            target_hour = _stable_hour(f"{uid}:athlete:{today_key}", 9, 18)
            if now.weekday() == 0:
                target_hour = _stable_hour(f"{uid}:athlete:monday:{today_key}", 8, 12)
            if now.hour == target_hour and not _has_result_for_date(db, uid, today_key):
                has_week_result = _has_result_since(db, uid, week_start_key)
                title, body = _athlete_reminder_copy(now, week_start_key, has_week_result)
                if create_user_notification(
                    db=db,
                    uid=uid,
                    role="athlete",
                    type_="athlete_daily_result_reminder",
                    title=title,
                    body=body,
                    dedupe_key=f"athlete-reminder:{uid}:{today_key}",
                    route_name="/athlete_training",
                    source_id=today_key,
                ):
                    created["athlete"] += 1

        if profile in _COACH_PROFILES and not has_training_today:
            target_hour = _stable_hour(f"{uid}:coach:{today_key}", 9, 18)
            if now.hour == target_hour:
                if create_user_notification(
                    db=db,
                    uid=uid,
                    role="coach",
                    type_="coach_missing_training_reminder",
                    title="Nenhum treino cadastrado",
                    body="Ainda não há treino cadastrado para hoje.",
                    dedupe_key=f"coach-missing-training:{uid}:{today_key}",
                    route_name="/coach_training",
                    source_id=today_key,
                ):
                    created["coach"] += 1

    return {"now": now.isoformat(), **created}
