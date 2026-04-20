# main.py
import json
import logging
import os
import firebase_admin
from firebase_functions import (
    storage_fn,
    firestore_fn,
    https_fn,
    options,
)

# inicializa app firebase (leve)
if not firebase_admin._apps:
    firebase_admin.initialize_app()


# =============================================================================
# CONFIG Cloud Tasks — debounce dos insights semanais do atleta
# =============================================================================

_REGION = "us-central1"
_TASK_QUEUE_ID = os.environ.get("WEEKLY_INSIGHTS_QUEUE", "weekly-insights-queue")
_TASK_DELAY_SECONDS = int(os.environ.get("WEEKLY_INSIGHTS_DELAY_SEC", "1080"))  # 18 min

# URL do handler HTTPS registrado abaixo (`run_weekly_insights_task`).
# Preenchida em runtime: depende de PROJECT_ID da função.
def _weekly_insights_handler_url() -> str:
    project = os.environ.get("GCLOUD_PROJECT") or json.loads(
        os.environ.get("FIREBASE_CONFIG", "{}")
    ).get("projectId")
    if not project:
        raise RuntimeError("PROJECT_ID ausente — não é possível montar URL.")
    # padrão das Cloud Functions 2nd gen
    return f"https://{_REGION}-{project}.cloudfunctions.net/run_weekly_insights_task"


def _enqueue_weekly_insights_task(uid: str) -> None:
    """
    Enfileira uma Cloud Task que, após `_TASK_DELAY_SECONDS`, chama o handler
    HTTP para gerar os insights semanais do atleta. Se já existir uma task
    com o mesmo nome determinístico, o Cloud Tasks RECUSA a duplicata — é
    exatamente o comportamento de debounce que queremos (sempre criamos
    com um nome que inclui um bucket de tempo).
    """
    try:
        from google.cloud import tasks_v2
        from google.protobuf import timestamp_pb2
        import datetime as _dt

        project = os.environ.get("GCLOUD_PROJECT") or json.loads(
            os.environ.get("FIREBASE_CONFIG", "{}")
        ).get("projectId")
        if not project:
            logging.warning("Sem PROJECT_ID — não é possível enfileirar task.")
            return

        client = tasks_v2.CloudTasksClient()
        parent = client.queue_path(project, _REGION, _TASK_QUEUE_ID)

        scheduled = _dt.datetime.utcnow() + _dt.timedelta(
            seconds=_TASK_DELAY_SECONDS
        )
        ts = timestamp_pb2.Timestamp()
        ts.FromDatetime(scheduled)

        # Nome determinístico por janela de ~18 min — garante que escritas
        # em sequência sejam coalescidas em UMA única execução.
        bucket = int(_dt.datetime.utcnow().timestamp() // _TASK_DELAY_SECONDS)
        task_name = f"{parent}/tasks/weekly-{uid}-{bucket}"

        task = {
            "name": task_name,
            "schedule_time": ts,
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": _weekly_insights_handler_url(),
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"uid": uid}).encode(),
            },
        }

        client.create_task(request={"parent": parent, "task": task})
        logging.info(f"[cloud-tasks] enqueued weekly insights for {uid}")

    except Exception as e:
        # AlreadyExists = debounce funcionou, não é erro.
        msg = str(e)
        if "ALREADY_EXISTS" in msg or "already exists" in msg.lower():
            logging.info(f"[cloud-tasks] debounce ativo para {uid}")
            return
        logging.warning(f"[cloud-tasks] falha ao enfileirar ({uid}): {e}")


# =============================================================================
# Triggers já existentes
# =============================================================================

@storage_fn.on_object_finalized(
    region=_REGION,
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
    region=_REGION,
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
    region=_REGION,
    memory=options.MemoryOption.MB_256,
    timeout_sec=60
)
def update_athlete_stats(event):
    """
    Dispara quando um resultado é criado/atualizado/deletado.
    1) Atualiza stats/summary e weekly_load (matemática pura).
    2) Enfileira Cloud Task com debounce de ~18 min para gerar os
       insights semanais do atleta pela IA.
    """
    logging.info("update_athlete_stats triggered (results)")
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

    # Debounce — enfileira tarefa para gerar insights da IA
    uid = event.params.get("uid")
    if uid:
        _enqueue_weekly_insights_task(uid)


@firestore_fn.on_document_written(
    document="users/{uid}/prs/{prId}",
    region=_REGION,
    memory=options.MemoryOption.MB_256,
    timeout_sec=60
)
def update_athlete_stats_on_pr(event):
    """Recalcula stats/summary e weekly_load quando um PR muda."""
    logging.info("update_athlete_stats_on_pr triggered (prs)")
    try:
        from athlete_stats_module import update_athlete_stats_logic
    except Exception:
        logging.exception("Falha ao importar athlete_stats_module")
        return

    try:
        update_athlete_stats_logic(event)
    except Exception:
        logging.exception("Erro ao executar update_athlete_stats_logic (pr)")
        raise


# =============================================================================
# NOVO: handler HTTPS do Cloud Tasks — gera insights semanais do atleta
# =============================================================================

@https_fn.on_request(
    region=_REGION,
    memory=options.MemoryOption.MB_512,
    timeout_sec=120,
)
def run_weekly_insights_task(req: https_fn.Request) -> https_fn.Response:
    """
    Endpoint HTTP chamado pelo Cloud Tasks após o debounce.
    Body esperado: {"uid": "..."}.
    """
    try:
        payload = req.get_json(silent=True) or {}
        uid = payload.get("uid")
        if not uid:
            return https_fn.Response("missing uid", status=400)

        from athlete_insights_module import run_weekly_insights_logic
        run_weekly_insights_logic(uid)
        return https_fn.Response("ok", status=200)
    except Exception as e:
        logging.exception("Erro em run_weekly_insights_task")
        return https_fn.Response(f"error: {e}", status=500)


# =============================================================================
# NOVO: onCall para insights de evolução (12 semanas) com cache de 4 dias
# =============================================================================

@https_fn.on_call(
    region=_REGION,
    memory=options.MemoryOption.MB_512,
    timeout_sec=120,
)
def get_athlete_evolution_insights(req: https_fn.CallableRequest):
    """
    Chamado pelo app quando o atleta abre a tela de evolução.
    - Usa req.auth.uid (nunca confia em uid vindo do cliente).
    - Cache de 4 dias em users/{uid}/insights/evolucao (o próprio módulo cuida).
    - `data.force = true` força regeneração (para debug/admin).
    """
    if not req.auth or not req.auth.uid:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Autenticação necessária.",
        )

    uid = req.auth.uid
    force = bool((req.data or {}).get("force", False))

    try:
        from athlete_insights_module import run_evolution_insights_logic
        return run_evolution_insights_logic(uid, force=force)
    except Exception as e:
        logging.exception("Erro em get_athlete_evolution_insights")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=str(e),
        )
