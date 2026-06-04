import firebase_admin
from firebase_admin import credentials
cred = credentials.Certificate("/Users/leosaracino/Documents/Pessoal/Faculdade/TCC/motiva-8b82f-firebase-adminsdk-fbsvc-14d8d2b5e8.json")
firebase_admin.initialize_app(cred)
