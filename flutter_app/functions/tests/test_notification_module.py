import unittest
from datetime import datetime, timedelta
from unittest.mock import patch
from zoneinfo import ZoneInfo

from notification_module.logic import (
    NOTIFICATION_RETENTION_DAYS,
    _stable_hour,
    _with_role_prefix,
    create_user_notification,
    delete_expired_notifications,
    notify_all_coaches,
)


class _Snapshot:
    def __init__(self, id_, data=None, exists=True, reference=None):
        self.id = id_
        self._data = data or {}
        self.exists = exists
        self.reference = reference

    def to_dict(self):
        return dict(self._data)


class _NotificationDoc:
    def __init__(self, store, doc_id):
        self.id = doc_id
        self._store = store

    def get(self):
        if self.id in self._store:
            return _Snapshot(self.id, self._store[self.id], exists=True)
        return _Snapshot(self.id, exists=False)

    def set(self, data):
        self._store[self.id] = dict(data)

    def delete(self):
        self._store.pop(self.id, None)


class _NotificationsCollection:
    def __init__(self, store):
        self._store = store

    def document(self, doc_id):
        return _NotificationDoc(self._store, doc_id)


class _SettingsCollection:
    def __init__(self, store):
        self._store = store

    def document(self, doc_id):
        return _NotificationDoc(self._store, doc_id)


class _UserRef:
    def __init__(self, db, uid):
        self._db = db
        self._uid = uid

    def get(self):
        if self._uid in self._db.users:
            return _Snapshot(self._uid, self._db.users[self._uid], exists=True)
        return _Snapshot(self._uid, exists=False)

    def collection(self, name):
        if name == "notifications":
            return _NotificationsCollection(
                self._db.notifications.setdefault(self._uid, {})
            )
        if name == "settings":
            return _SettingsCollection(self._db.settings.setdefault(self._uid, {}))
        raise AssertionError(f"unexpected collection {name}")


class _UsersQuery:
    def __init__(self, db, profile):
        self._db = db
        self._profile = profile

    def stream(self):
        for uid, data in self._db.users.items():
            if data.get("profile") == self._profile:
                yield _Snapshot(uid, data, exists=True)


class _UsersCollection:
    def __init__(self, db):
        self._db = db

    def document(self, uid):
        return _UserRef(self._db, uid)

    def where(self, field, op, value):
        if field != "profile" or op != "==":
            raise AssertionError("unexpected where")
        return _UsersQuery(self._db, value)


class _NotificationGroupQuery:
    def __init__(self, db, filters=None, limit_value=None):
        self._db = db
        self._filters = filters or []
        self._limit_value = limit_value

    def where(self, field, op, value):
        return _NotificationGroupQuery(
            self._db,
            filters=[*self._filters, (field, op, value)],
            limit_value=self._limit_value,
        )

    def limit(self, value):
        return _NotificationGroupQuery(
            self._db,
            filters=self._filters,
            limit_value=value,
        )

    def stream(self):
        emitted = 0
        for uid, notifications in self._db.notifications.items():
            for doc_id, data in list(notifications.items()):
                if not self._matches(data):
                    continue

                if self._limit_value is not None and emitted >= self._limit_value:
                    return

                emitted += 1
                reference = _NotificationDoc(notifications, doc_id)
                yield _Snapshot(doc_id, data, exists=True, reference=reference)

    def _matches(self, data):
        for field, op, value in self._filters:
            current = data.get(field)
            if op == "<=":
                if current is None or current > value:
                    return False
            else:
                raise AssertionError(f"unexpected op {op}")
        return True


class _Batch:
    def __init__(self):
        self._refs = []

    def delete(self, ref):
        self._refs.append(ref)

    def commit(self):
        for ref in self._refs:
            ref.delete()


class _Db:
    def __init__(self, users):
        self.users = users
        self.notifications = {}
        self.settings = {}

    def collection(self, name):
        if name != "users":
            raise AssertionError(f"unexpected collection {name}")
        return _UsersCollection(self)

    def collection_group(self, name):
        if name != "notifications":
            raise AssertionError(f"unexpected collection group {name}")
        return _NotificationGroupQuery(self)

    def batch(self):
        return _Batch()


class NotificationModuleTest(unittest.TestCase):
    def test_prefix_only_for_hybrid_profiles(self):
        self.assertEqual(_with_role_prefix("Pronto", "athlete", "athlete"), "Pronto")
        self.assertEqual(_with_role_prefix("Pronto", "coach", "coach"), "Pronto")
        self.assertEqual(
            _with_role_prefix("Pronto", "athlete", "athleteCoach"),
            "[atleta] Pronto",
        )
        self.assertEqual(
            _with_role_prefix("Pronto", "coach", "athleteIntern"),
            "[coach] Pronto",
        )

    def test_stable_hour_is_deterministic_inside_window(self):
        first = _stable_hour("uid:athlete:2026-04-28", 9, 18)
        second = _stable_hour("uid:athlete:2026-04-28", 9, 18)

        self.assertEqual(first, second)
        self.assertGreaterEqual(first, 9)
        self.assertLessEqual(first, 18)

    def test_create_user_notification_dedupes_by_key(self):
        db = _Db({"u1": {"profile": "athleteCoach"}})
        pushes = []

        with patch(
            "notification_module.logic._send_push_to_user",
            lambda _db, uid, title, body, data: pushes.append((uid, title, body, data)),
        ):
            created = create_user_notification(
                db=db,
                uid="u1",
                role="athlete",
                type_="weekly_ready",
                title="Resumo pronto",
                body="Veja sua semana.",
                dedupe_key="weekly/u1/2026-W18",
                route_name="/athlete_insight",
                source_id="2026-W18",
            )
            duplicated = create_user_notification(
                db=db,
                uid="u1",
                role="athlete",
                type_="weekly_ready",
                title="Resumo pronto",
                body="Veja sua semana.",
                dedupe_key="weekly/u1/2026-W18",
            )

        self.assertTrue(created)
        self.assertFalse(duplicated)
        self.assertEqual(len(db.notifications["u1"]), 1)
        self.assertEqual(pushes[0][1], "[atleta] Resumo pronto")

        stored = next(iter(db.notifications["u1"].values()))
        self.assertIn("expiresAt", stored)
        self.assertIsInstance(stored["expiresAt"], datetime)
        retention = stored["expiresAt"] - datetime.now(tz=stored["expiresAt"].tzinfo)
        min_retention = timedelta(days=NOTIFICATION_RETENTION_DAYS) - timedelta(
            minutes=1
        )
        max_retention = timedelta(days=NOTIFICATION_RETENTION_DAYS, minutes=1)
        self.assertGreater(retention, min_retention)
        self.assertLessEqual(retention, max_retention)

    def test_create_user_notification_respects_disabled_category(self):
        db = _Db({"u1": {"profile": "athlete"}})
        db.settings = {
            "u1": {
                "athlete": {
                    "weeklyInsights": False,
                }
            }
        }

        with patch("notification_module.logic._send_push_to_user") as push:
            created = create_user_notification(
                db=db,
                uid="u1",
                role="athlete",
                type_="athlete_weekly_insights_ready",
                title="Resumo pronto",
                body="Veja sua semana.",
                dedupe_key="weekly/u1/2026-W18",
            )

        self.assertFalse(created)
        self.assertNotIn("u1", db.notifications)
        push.assert_not_called()

    def test_create_user_notification_skips_disabled_account(self):
        db = _Db({"u1": {"profile": "coach", "accountStatus": "disabled"}})

        with patch("notification_module.logic._send_push_to_user") as push:
            created = create_user_notification(
                db=db,
                uid="u1",
                role="coach",
                type_="coach_daily_analysis_ready",
                title="Analise pronta",
                body="Treino analisado.",
                dedupe_key="coach/workout-1",
            )

        self.assertFalse(created)
        self.assertNotIn("u1", db.notifications)
        push.assert_not_called()

    def test_notify_all_coaches_skips_pure_athletes(self):
        db = _Db(
            {
                "athlete": {"profile": "athlete"},
                "coach": {"profile": "coach"},
                "intern": {"profile": "intern"},
                "hybrid": {"profile": "athleteCoach"},
            }
        )

        with patch("notification_module.logic._send_push_to_user", lambda *args: None):
            created = notify_all_coaches(
                db=db,
                type_="coach_ready",
                title="Analise pronta",
                body="Treino analisado.",
                dedupe_key="coach-analysis:workout-1",
            )

        self.assertEqual(created, 3)
        self.assertNotIn("athlete", db.notifications)
        self.assertIn("coach", db.notifications)
        self.assertIn("intern", db.notifications)
        self.assertIn("hybrid", db.notifications)

    def test_delete_expired_notifications_removes_only_old_docs(self):
        tz = ZoneInfo("America/Sao_Paulo")
        now = datetime(2026, 4, 28, 12, 0, tzinfo=tz)
        db = _Db({"u1": {"profile": "athlete"}, "u2": {"profile": "coach"}})
        db.notifications = {
            "u1": {
                "old-read": {
                    "createdAt": now - timedelta(days=8),
                    "status": "read",
                },
                "recent-unread": {
                    "createdAt": now - timedelta(days=6, hours=23),
                    "status": "unread",
                },
            },
            "u2": {
                "old-unread": {
                    "createdAt": now - timedelta(days=7, minutes=1),
                    "status": "unread",
                },
            },
        }

        result = delete_expired_notifications(db=db, now=now, batch_size=1)

        self.assertEqual(result["deleted"], 2)
        self.assertNotIn("old-read", db.notifications["u1"])
        self.assertIn("recent-unread", db.notifications["u1"])
        self.assertNotIn("old-unread", db.notifications["u2"])


if __name__ == "__main__":
    unittest.main()
