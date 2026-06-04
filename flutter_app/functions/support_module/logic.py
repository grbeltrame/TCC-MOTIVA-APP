import os

from firebase_admin import firestore

_ALLOWED_TYPES = {"support", "feedback", "bug_report"}


def _subject(type_: str) -> str:
    if type_ == "feedback":
        return "Motiva - novo feedback"
    if type_ == "bug_report":
        return "Motiva - novo relato de erro"
    return "Motiva - nova mensagem de suporte"


def submit_support_ticket(uid: str, payload: dict, db=None) -> dict:
    db = db or firestore.client()
    type_ = (payload or {}).get("type", "support")
    if type_ not in _ALLOWED_TYPES:
        type_ = "support"

    message = str((payload or {}).get("message", "")).strip()
    if not message:
        raise ValueError("Mensagem vazia.")

    steps = (payload or {}).get("steps")
    rating = (payload or {}).get("rating")
    support_email = os.environ.get("SUPPORT_EMAIL", "suporte@motiva.app")

    user_doc = db.collection("users").document(uid).get()
    user_data = user_doc.to_dict() if user_doc.exists else {}
    user_email = (user_data or {}).get("email")
    user_name = (user_data or {}).get("name")

    ticket_ref = db.collection("supportTickets").document()
    ticket = {
        "uid": uid,
        "userEmail": user_email,
        "userName": user_name,
        "type": type_,
        "message": message,
        "steps": steps,
        "rating": rating,
        "status": "open",
        "createdAt": firestore.SERVER_TIMESTAMP,
    }
    ticket_ref.set(ticket)

    text = (
        f"Tipo: {type_}\n"
        f"UID: {uid}\n"
        f"Nome: {user_name or '-'}\n"
        f"Email: {user_email or '-'}\n"
        f"Nota: {rating if rating is not None else '-'}\n\n"
        f"Mensagem:\n{message}\n\n"
        f"Passos:\n{steps or '-'}"
    )

    db.collection("mail").document(ticket_ref.id).set(
        {
            "to": [support_email],
            "message": {
                "subject": _subject(type_),
                "text": text,
            },
            "createdAt": firestore.SERVER_TIMESTAMP,
        }
    )

    return {"ticketId": ticket_ref.id}
