import unittest

from user_settings_module.logic import athlete_ai_enabled, is_account_disabled


class _Snapshot:
    def __init__(self, data=None, exists=True):
        self._data = data or {}
        self.exists = exists

    def to_dict(self):
        return dict(self._data)


class _Doc:
    def __init__(self, data):
        self._data = data

    def get(self):
        if self._data is None:
            return _Snapshot(exists=False)
        return _Snapshot(self._data)

    def collection(self, name):
        if name != "settings":
            raise AssertionError("unexpected collection")
        return _SettingsCollection(self._data.setdefault("settings", {}))


class _SettingsCollection:
    def __init__(self, settings):
        self._settings = settings

    def document(self, doc_id):
        return _Doc(self._settings.get(doc_id))


class _UsersCollection:
    def __init__(self, users):
        self._users = users

    def document(self, uid):
        return _Doc(self._users.get(uid))


class _Db:
    def __init__(self, users):
        self._users = users

    def collection(self, name):
        if name != "users":
            raise AssertionError("unexpected collection")
        return _UsersCollection(self._users)


class UserSettingsModuleTest(unittest.TestCase):
    def test_disabled_account_blocks_ai(self):
        db = _Db({"u1": {"accountStatus": "disabled", "settings": {}}})

        self.assertTrue(is_account_disabled(db, "u1"))
        self.assertFalse(athlete_ai_enabled(db, "u1"))

    def test_missing_privacy_settings_default_to_ai_enabled(self):
        db = _Db({"u1": {"profile": "athlete", "settings": {}}})

        self.assertTrue(athlete_ai_enabled(db, "u1"))

    def test_privacy_setting_can_disable_ai(self):
        db = _Db(
            {
                "u1": {
                    "profile": "athlete",
                    "settings": {
                        "privacy": {"aiPersonalizationEnabled": False},
                    },
                }
            }
        )

        self.assertFalse(athlete_ai_enabled(db, "u1"))


if __name__ == "__main__":
    unittest.main()
