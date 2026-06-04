import unittest
from unittest.mock import patch

from account_module.logic import (
    deactivate_user_account,
    delete_user_account,
    reactivate_user_account,
)
from export_module.logic import export_user_data
from support_module.logic import submit_support_ticket


class _Snapshot:
    def __init__(self, id_, data=None, exists=True, reference=None):
        self.id = id_
        self._data = data or {}
        self.exists = exists
        self.reference = reference

    def to_dict(self):
        return dict(self._data)


class _DocRef:
    def __init__(self, collection, doc_id):
        self._collection = collection
        self.id = doc_id

    def get(self):
        exists = self.id in self._collection.store
        return _Snapshot(
            self.id,
            self._collection.store.get(self.id, {}),
            exists=exists,
            reference=self,
        )

    def set(self, data, merge=False):
        if merge:
            self._collection.store.setdefault(self.id, {}).update(data)
            return
        self._collection.store[self.id] = dict(data)

    def delete(self):
        self._collection.store.pop(self.id, None)

    def collections(self):
        return []


class _Query:
    def __init__(self, collection, field, value):
        self._collection = collection
        self._field = field
        self._value = value

    def stream(self):
        for doc_id, data in list(self._collection.store.items()):
            if data.get(self._field) == self._value:
                ref = _DocRef(self._collection, doc_id)
                yield _Snapshot(doc_id, data, exists=True, reference=ref)


class _Collection:
    def __init__(self, name, store):
        self.id = name
        self.store = store
        self._auto_index = 0

    def document(self, doc_id=None):
        if doc_id is None:
            self._auto_index += 1
            doc_id = f"auto-{self._auto_index}"
        return _DocRef(self, doc_id)

    def where(self, field, op, value):
        if op != "==":
            raise AssertionError("unexpected operator")
        return _Query(self, field, value)

    def stream(self):
        for doc_id, data in list(self.store.items()):
            ref = _DocRef(self, doc_id)
            yield _Snapshot(doc_id, data, exists=True, reference=ref)


class _Db:
    def __init__(self):
        self.stores = {
            "users": {},
            "exercises": {},
            "supportTickets": {},
            "mail": {},
        }

    def collection(self, name):
        return _Collection(name, self.stores.setdefault(name, {}))


class AccountSupportExportModuleTest(unittest.TestCase):
    def test_deactivate_and_reactivate_user_account(self):
        db = _Db()
        db.stores["users"]["u1"] = {"email": "user@test.com"}

        self.assertEqual(deactivate_user_account("u1", db=db)["status"], "disabled")
        self.assertEqual(db.stores["users"]["u1"]["accountStatus"], "disabled")

        self.assertEqual(reactivate_user_account("u1", db=db)["status"], "active")
        self.assertEqual(db.stores["users"]["u1"]["accountStatus"], "active")

    def test_delete_user_account_removes_user_and_owned_exercises(self):
        db = _Db()
        db.stores["users"]["u1"] = {"email": "user@test.com"}
        db.stores["exercises"]["mine"] = {"createdByUid": "u1"}
        db.stores["exercises"]["other"] = {"createdByUid": "u2"}

        with patch("account_module.logic.auth.delete_user") as delete_auth:
            result = delete_user_account("u1", db=db)

        self.assertEqual(result["deletedDocs"], 2)
        self.assertNotIn("u1", db.stores["users"])
        self.assertNotIn("mine", db.stores["exercises"])
        self.assertIn("other", db.stores["exercises"])
        delete_auth.assert_called_once_with("u1")

    def test_export_user_data_returns_user_tree_and_owned_exercises(self):
        db = _Db()
        db.stores["users"]["u1"] = {"email": "user@test.com"}
        db.stores["exercises"]["mine"] = {"createdByUid": "u1", "titulo": "A"}
        db.stores["exercises"]["other"] = {"createdByUid": "u2", "titulo": "B"}

        result = export_user_data("u1", db=db)

        self.assertEqual(result["uid"], "u1")
        self.assertEqual(result["user"]["data"]["email"], "user@test.com")
        self.assertIn("mine", result["exercises"])
        self.assertNotIn("other", result["exercises"])

    def test_submit_support_ticket_creates_ticket_and_mail_document(self):
        db = _Db()
        db.stores["users"]["u1"] = {
            "email": "user@test.com",
            "name": "Usuario",
        }

        with patch.dict("support_module.logic.os.environ", {"SUPPORT_EMAIL": "help@test.com"}):
            result = submit_support_ticket(
                "u1",
                {"type": "feedback", "message": "Muito bom", "rating": 9},
                db=db,
            )

        ticket_id = result["ticketId"]
        self.assertIn(ticket_id, db.stores["supportTickets"])
        self.assertEqual(db.stores["supportTickets"][ticket_id]["type"], "feedback")
        self.assertEqual(db.stores["mail"][ticket_id]["to"], ["help@test.com"])
        self.assertIn("novo feedback", db.stores["mail"][ticket_id]["message"]["subject"])


if __name__ == "__main__":
    unittest.main()
