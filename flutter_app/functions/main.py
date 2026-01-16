# main.py
import logging
import firebase_admin
from firebase_functions import storage_fn, firestore_fn, options

# inicializa app firebase (leve)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

@storage_fn.on_object_finalized(
    region="us-central1",
    memory=options.MemoryOption.MB_512,
    timeout_sec=60
)
def process_workout_pdf(event):
    logging.info("process_workout_pdf triggered")
    try:
        # import lazy da lógica de parsing — evita crash na inicialização
        from pdf_module import run_pdf_parser_logic
    except Exception:
        logging.exception("Falha ao importar pdf_module")
        raise

    try:
        run_pdf_parser_logic(event)
    except Exception:
        logging.exception("Erro ao executar run_pdf_parser_logic")
        raise

@firestore_fn.on_document_written(
    document="exercises/{workoutId}",
    region="us-central1",
    memory=options.MemoryOption.MB_512
)
def analyze_workout_with_ai(event):
    logging.info("analyze_workout_with_ai triggered")
    try:
        # import lazy do módulo de IA — pode falhar sem quebrar outras funções
        from ia_module import run_ai_analysis_logic
    except Exception:
        logging.exception("Falha ao importar ia_module; pulando análise de IA")
        return

    try:
        run_ai_analysis_logic(event)
    except Exception:
        logging.exception("Erro ao executar run_ai_analysis_logic")
        raise
