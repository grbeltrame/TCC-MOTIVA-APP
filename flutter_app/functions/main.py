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
        from ia_module import run_ai_analysis_logic
    except Exception:
        logging.exception("Falha ao importar ia_module; pulando análise de IA")
        return

    try:
        run_ai_analysis_logic(event)
    except Exception:
        logging.exception("Erro ao executar run_ai_analysis_logic")
        raise


@firestore_fn.on_document_written(
    document="users/{uid}/results/{resultId}",
    region="us-central1",
    memory=options.MemoryOption.MB_256,
    timeout_sec=60
)
def update_athlete_stats(event):
    """
    Dispara sempre que um resultado de atleta é criado ou atualizado.
    Recalcula users/{uid}/stats/summary com frequência, esforço médio,
    estímulos e calendário da semana — sem LLM, só matemática.
    """
    logging.info("update_athlete_stats triggered")
    try:
        from athlete_stats_module import update_athlete_stats_logic
    except Exception:
        logging.exception("Falha ao importar athlete_stats_module")
        return

    try:
        update_athlete_stats_logic(event)
    except Exception:
        logging.exception("Erro ao executar update_athlete_stats_logic")
        raise