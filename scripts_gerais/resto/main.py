# # main.py - FINAL VERSION

# import os
# import json
# import firebase_admin
# from firebase_admin import firestore
# from firebase_admin.firestore import DocumentSnapshot
# from firebase_functions import firestore_fn
# from datetime import datetime, timedelta

# # Local modules
# from flutter_app.functions.ia_module.prompt_builder import create_evaluation_prompt
# from models import get_parser

# # =========================================================================
# # INITIALIZATION & CONFIG
# # =========================================================================
# if not firebase_admin._apps:
#     firebase_admin.initialize_app()

# PROJECT_ID = os.environ.get("GCLOUD_PROJECT")
# if not PROJECT_ID:
#     config = os.environ.get("FIREBASE_CONFIG")
#     if config:
#         PROJECT_ID = json.loads(config).get("projectId")
# if not PROJECT_ID:
#     raise RuntimeError("Could not determine Project ID from environment variables.")

# SECRET_ID = 'GEMINI_API_KEY'
# firestore_client = firestore.client()

# # =========================================================================
# # HELPER FUNCTIONS
# # =========================================================================
# def get_gemini_api_key() -> str:
#     """Lazily fetches the Gemini API key from Secret Manager."""
#     from google.cloud import secretmanager
    
#     secret_client = secretmanager.SecretManagerServiceClient()
#     name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
#     response = secret_client.access_secret_version(request={"name": name})
#     return response.payload.data.decode("UTF-8")

# def get_exercise_db_from_firestore() -> list:
#     """Fetches the exercise database from Firestore."""
#     exercises_ref = firestore_client.collection('exercises')
#     return [doc.to_dict() for doc in exercises_ref.stream()]

# def get_last_15_days_workouts_from_firestore() -> list:
#     """Fetches workout history from the last 15 days."""
#     fifteen_days_ago = datetime.now() - timedelta(days=15)
#     workouts_ref = firestore_client.collection('treinos')
#     query = workouts_ref.where('data', '>=', fifteen_days_ago).order_by('data', direction='DESCENDING')
#     return [doc.to_dict() for doc in query.stream()]

# # =========================================================================
# # THE MAIN CLOUD FUNCTION
# # =========================================================================
# # A CLOUD FUNCTION PRINCIPAL (VERSÃO CORRIGIDA)
# # =========================================================================
# @firestore_fn.on_document_created(document="treinos/{workoutId}")
# def analyze_new_workout(event: firestore_fn.Event[DocumentSnapshot | None]) -> None:
#     """Analisa um novo treino usando Gemini e salva o resultado no Firestore."""
    
#     # Lazy load para as bibliotecas pesadas
#     from langchain_google_genai import ChatGoogleGenerativeAI
    
#     if event.data is None:
#         print("Evento sem dados. Ignorando.")
#         return

#     workout_id = event.params["workoutId"]
#     current_workout_data = event.data.to_dict()

#     if "analise" in current_workout_data:
#         print(f"O treino {workout_id} já possui uma análise. Ignorando.")
#         return

#     print(f"Iniciando análise para o treino: {workout_id}")
#     workout_ref = firestore_client.collection("treinos").document(workout_id)
#     try:
#         api_key = get_gemini_api_key()
#         exercise_db = get_exercise_db_from_firestore()
#         past_workouts = get_last_15_days_workouts_from_firestore()
        
#         # 1. O prompt é criado, já completo. (Isto está perfeito)
#         prompt_text = create_evaluation_prompt(current_workout_data, past_workouts, exercise_db)

#         # 2. O modelo LLM é inicializado.
#         llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", google_api_key=api_key)
        
#         print("Enviando requisição para a IA Gemini...")
        
#         # 3. MUDANÇA PRINCIPAL: Chamamos o modelo DIRETAMENTE com o prompt.
#         #    Isso evita o erro de "Missing some input keys".
#         ai_message = llm.invoke(prompt_text)
#         raw_output = ai_message.content
        
#         # Limpa a saída da IA para garantir que é um JSON válido
#         if "```json" in raw_output:
#             clean_output = raw_output.split("```json")[1].split("```")[0].strip()
#         else:
#             clean_output = raw_output.strip()
            
#         print("Resposta recebida. Validando e estruturando o JSON...")
        
#         # Obtém o parser e estrutura a saída
#         parser = get_parser()
#         structured_analysis = parser.parse(clean_output).dict()

#         # Salva a análise de volta no documento do Firestore
#         workout_ref.update({
#             "analise": structured_analysis,
#             "statusAnalise": "concluida",
#             "analisadoEm": firestore.SERVER_TIMESTAMP
#         })
#         print(f"Análise do treino {workout_id} salva com sucesso!")

#     except Exception as e:
#         print(f"ERRO durante a análise do treino {workout_id}: {e}")
#         try:
#             workout_ref.update({"statusAnalise": "erro", "erroMsg": str(e)})
#         except Exception as ee:
#             print(f"ERRO ao atualizar status de erro no Firestore: {ee}")