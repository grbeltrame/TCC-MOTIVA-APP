# functions/ia_module/logic.py

import os
import json
import logging
from firebase_admin import firestore
from google.cloud import secretmanager
from langchain_google_genai import ChatGoogleGenerativeAI

# AJUSTE 1: Nome do arquivo corrigido para prompt_builder
from .prompt_builder import create_evaluation_prompt
from .models import get_parser


SECRET_ID = 'GEMINI_API_KEY'
# Tenta pegar o ID do projeto automaticamente
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")

def get_gemini_api_key() -> str:
    """Busca a API Key no Secret Manager."""
    try:
        if not PROJECT_ID:
            # Fallback para tentar ler de config se a var de ambiente falhar
            config = os.environ.get("FIREBASE_CONFIG")
            if config:
                proj_id = json.loads(config).get("projectId")
                if proj_id:
                    # Precisamos definir a variável para o uso no client abaixo
                    # Mas aqui vamos passar direto na string
                    name = f"projects/{proj_id}/secrets/{SECRET_ID}/versions/latest"
            else:
                raise ValueError("PROJECT_ID não encontrado.")
        else:
            name = f"projects/{PROJECT_ID}/secrets/{SECRET_ID}/versions/latest"
            
        client = secretmanager.SecretManagerServiceClient()
        # Sintaxe correta para as libs mais novas do Google Cloud
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        logging.error(f"Erro ao buscar API Key: {e}")
        raise e

def run_ai_analysis_logic(event):
    """
    Função principal.
    Recebe o evento do Firestore (Gen 2).
    """
    # --- MUDANÇA: Inicialize o cliente AQUI DENTRO ---
    firestore_client = firestore.client()
    # -------------------------------------------------
    
    # 1. Obter o documento atual
    document_snapshot = event.data.after
    if not document_snapshot:
        logging.info("Documento foi deletado. Nada a fazer.")
        return

    # AJUSTE 2: Pegar o ID usando event.params (Mais seguro na Gen 2)
    # Isso funciona porque no main.py definimos "exercises/{workoutId}"
    workout_id = event.params.get('workoutId')
    
    # Fallback caso params falhe por algum motivo
    if not workout_id:
        workout_id = event.document.split("/")[-1]

    logging.info(f"Iniciando checagem para treino: {workout_id}")

    current_data = document_snapshot.to_dict() or {}

    # 2. Evita Loop Infinito (Verifica status)
    status = current_data.get('statusAnalise')
    if status in ['concluida', 'processando', 'erro']:
        logging.info(f"Treino {workout_id} ignorado (Status: {status})")
        return

    # 3. Verifica se o PDF já terminou de ser processado
    # Se não tiver 'partes' ou 'materiais', o PDF parser ainda não acabou.
    if not current_data.get('partes'):
        logging.info("Aguardando o processamento do PDF terminar (campo 'partes' vazio).")
        return

    # Referência para atualizar
    workout_ref = firestore_client.collection("exercises").document(workout_id)

    try:
        # Marca como processando imediatamente
        workout_ref.update({"statusAnalise": "processando"})
        
        box_id = current_data.get('boxId')
        
        # Busca histórico (apenas campos necessários para economizar leitura se o doc for gigante)
        # Nota: O Firestore sempre lê o doc todo, mas ajuda na memória do python
        history_docs = (
            firestore_client.collection("exercises")
            #.where("boxId", "==", box_id)
            .order_by("criadoEm", direction=firestore.Query.DESCENDING)
            .limit(15)
            .stream()
        )
        past_workouts = [d.to_dict() for d in history_docs if d.id != workout_id]

        # Base de exercícios (Mock por enquanto)
        exercise_db = [] 

        # Monta Prompt
        prompt_text = create_evaluation_prompt(current_data, past_workouts, exercise_db)

        # Chama Gemini
        api_key = get_gemini_api_key()
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash", 
            google_api_key=api_key,
            temperature=0.2
        )

        logging.info("Enviando prompt para o Gemini...")
        ai_message = llm.invoke(prompt_text)
        raw_output = ai_message.content

        # Limpeza do JSON (Markdown strip)
        clean_output = raw_output
        if "```json" in raw_output:
            clean_output = raw_output.split("```json")[1].split("```")[0].strip()
        elif "```" in raw_output: # Caso venha sem 'json' escrito
            clean_output = raw_output.split("```")[1].strip()
        
        parser = get_parser()
        structured_analysis = parser.parse(clean_output).dict()

        # Salva
        workout_ref.update({
            "analise": structured_analysis,
            "statusAnalise": "concluida",
            "analisadoEm": firestore.SERVER_TIMESTAMP
        })
        logging.info(f"Sucesso! Treino {workout_id} analisado.")

    except Exception as e:
        logging.error(f"Erro na análise do treino {workout_id}: {e}")
        # Importante: Salvar erro como string para não quebrar o banco
        workout_ref.update({
            "statusAnalise": "erro", 
            "erroMsg": str(e)
        })