# main.py - VERSÃO FINAL CORRIGIDA

import os
import json
import firebase_admin
from firebase_admin import firestore
from firebase_admin.firestore import DocumentSnapshot
from firebase_functions import firestore_fn
from datetime import datetime, timedelta

from prompet_builder import create_evaluation_prompt
from models import get_parser

# =========================================================================
# INICIALIZAÇÃO E CONFIGURAÇÃO
# =========================================================================
if not firebase_admin._apps:
    firebase_admin.initialize_app()
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")
if not PROJECT_ID:
    config = os.environ.get("FIREBASE_CONFIG")
    if config:
        PROJECT_ID = json.loads(config).get("projectId")
if not PROJECT_ID:
    raise RuntimeError("Não foi possível determinar o Project ID.")
SECRET_ID = 'GEMINI_API_KEY'
firestore_client = firestore.client()

def get_gemini_api_key() -> str:
    from google.cloud import secretmanager
    secret_client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
    response = secret_client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

def get_exercise_db_from_firestore() -> list:
    exercises_ref = firestore_client.collection('exercises')
    return [doc.to_dict() for doc in exercises_ref.stream()]

def get_last_15_days_workouts_from_firestore() -> list:
    fifteen_days_ago = datetime.now() - timedelta(days=15)
    workouts_ref = firestore_client.collection('treinos')
    query = workouts_ref.where('data', '>=', fifteen_days_ago).order_by('data', direction='DESCENDING')
    return [doc.to_dict() for doc in query.stream()]

# =========================================================================
# A CLOUD FUNCTION PRINCIPAL
# =========================================================================
@firestore_fn.on_document_created("treinos/{workoutId}")
def analyze_new_workout(event: firestore_fn.Event[DocumentSnapshot | None]) -> None:
    """Analisa um novo treino usando Gemini e salva o resultado no Firestore."""
    from langchain_google_genai import ChatGoogleGenerativeAI
    from langchain.prompts import PromptTemplate
    from langchain.chains import LLMChain

    if event.data is None: return
    workout_id = event.params["workoutId"]
    current_workout_data = event.data.to_dict()
    if "analise" in current_workout_data: return

    print(f"Iniciando análise para o treino: {workout_id}")
    workout_ref = firestore_client.collection("treinos").document(workout_id)
    try:
        api_key = get_gemini_api_key()
        exercise_db = get_exercise_db_from_firestore()
        past_workouts = get_last_15_days_workouts_from_firestore()
        prompt_text = create_evaluation_prompt(current_workout_data, past_workouts, exercise_db)

        llm = ChatGoogleGenerativeAI(model="gemini-pro", google_api_key=api_key)
        chain = LLMChain(llm=llm, prompt=PromptTemplate.from_template(prompt_text))
        
        print("Enviando requisição para a IA Gemini...")
        raw_output = chain.run({})
        
        clean_output = raw_output.strip()
        if "```json" in clean_output:
            clean_output = clean_output.split("```json")[1].split("```")[0].strip()
            
        print("Resposta recebida. Validando e estruturando o JSON...")
        parser = get_parser()
        structured_analysis = parser.parse(clean_output).dict()

        workout_ref.update({
            "analise": structured_analysis,
            "statusAnalise": "concluida",
            "analisadoEm": firestore.SERVER_TIMESTAMP
        })
        print(f"Análise do treino {workout_id} salva com sucesso!")

    except Exception as e:
        print(f"ERRO durante a análise do treino {workout_id}: {e}")
        try:
            workout_ref.update({"statusAnalise": "erro", "erroMsg": str(e)})
        except Exception as ee:
            print(f"ERRO ao atualizar status de erro no Firestore: {ee}")