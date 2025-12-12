# functions/main.py

import firebase_admin
from firebase_functions import storage_fn, firestore_fn, options

# ==============================================================================
# IMPORTAÇÃO DOS SEUS MÓDULOS
# ==============================================================================
# Graças aos arquivos __init__.py, podemos importar direto da pasta
from pdf_module import run_pdf_parser_logic
from ia_module import run_ai_analysis_logic

# Inicialização do App (obrigatório fazer uma vez aqui no topo)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

# ==============================================================================
# FUNÇÃO 1: LEITOR DE PDF (Gatilho: Storage)
# ==============================================================================
@storage_fn.on_object_finalized(
    region="us-central1",
    memory=options.MemoryOption.MB_512,
    timeout_sec=60
)
def process_workout_pdf(event: storage_fn.CloudEvent[storage_fn.StorageObjectData]):
    """
    Acionado quando um arquivo é enviado ao Storage.
    Verifica se é PDF, extrai os dados e salva na coleção 'exercises'.
    """
    # Toda a lógica complexa está isolada dentro da pasta pdf_module
    run_pdf_parser_logic(event)


# ==============================================================================
# FUNÇÃO 2: ANALISTA DE IA (Gatilho: Firestore)
# ==============================================================================
@firestore_fn.on_document_written(
    document="exercises/{workoutId}",
    region="us-central1",
    memory=options.MemoryOption.MB_512
)
def analyze_workout_with_ai(event: firestore_fn.Event[firestore_fn.Change]):
    """
    Acionado quando um treino é criado ou atualizado no Firestore.
    A IA lê os dados, analisa e atualiza o documento com insights.
    """
    # Toda a lógica complexa está isolada dentro da pasta ia_module
    run_ai_analysis_logic(event)