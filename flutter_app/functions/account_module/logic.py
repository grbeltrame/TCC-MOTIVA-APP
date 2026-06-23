import logging

from firebase_admin import auth, firestore


def deactivate_user_account(uid: str, db=None) -> dict:
    db = db or firestore.client()
    db.collection("users").document(uid).set(
        {
            "accountStatus": "disabled",
            "disabledAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return {"status": "disabled"}


def reactivate_user_account(uid: str, db=None) -> dict:
    db = db or firestore.client()
    db.collection("users").document(uid).set(
        {
            "accountStatus": "active",
            "reactivatedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return {"status": "active"}


def _delete_doc_tree(doc_ref) -> int:
    deleted = 0
    for collection_ref in doc_ref.collections():
        for child in collection_ref.stream():
            deleted += _delete_doc_tree(child.reference)
    doc_ref.delete()
    return deleted + 1


def delete_user_account(uid: str, db=None) -> dict:
    db = db or firestore.client()
    deleted_docs = 0

    for exercise in (
        db.collection("exercises")
        .where("createdByUid", "==", uid)
        .stream()
    ):
        deleted_docs += _delete_doc_tree(exercise.reference)

    user_ref = db.collection("users").document(uid)
    if user_ref.get().exists:
        deleted_docs += _delete_doc_tree(user_ref)

    try:
        auth.delete_user(uid)
    except auth.UserNotFoundError:
        logging.info("delete_user_account: auth user already missing uid=%s", uid)

    return {"deletedDocs": deleted_docs, "authDeleted": True}
