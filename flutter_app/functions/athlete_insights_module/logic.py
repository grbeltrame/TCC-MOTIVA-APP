# functions/athlete_insights_module/logic.py
#
# Orquestração da IA do ATLETA.
#
# Dois fluxos:
#   1. run_weekly_insights_logic(uid)   — chamado pelo handler de Cloud Tasks
#      após debounce de 15-20 min do último write em results/. Gera insights
#      semanais e salva em users/{uid}/insights/semanal.
#
#   2. run_evolution_insights_logic(uid) — chamado pelo endpoint onCall
#      get_athlete_evolution_insights. Cache de 4 dias em
#      users/{uid}/insights/evolucao.lastGeneratedAt.

import os
import json
import logging
import statistics
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from firebase_admin import firestore
from google.cloud import secretmanager
from langchain_google_genai import ChatGoogleGenerativeAI

from .prompt_builder import (
    create_weekly_insights_prompt,
    create_evolution_insights_prompt,
)
from .models import get_weekly_parser, get_evolution_parser

_TZ_BRAZIL = ZoneInfo("America/Sao_Paulo")

SECRET_ID = "GEMINI_API_KEY"
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")

# Cache da análise de evolução: 4 dias.
_EVOLUTION_CACHE_DAYS = 4

# Histórico considerado pela análise de evolução.
_EVOLUTION_WEEKS = 12


def _get_gemini_api_key() -> str:
    try:
        project_id = PROJECT_ID
        if not project_id:
            config = os.environ.get("FIREBASE_CONFIG")
            if config:
                project_id = json.loads(config).get("projectId")
        if not project_id:
            raise ValueError("PROJECT_ID não encontrado.")

        name = f"projects/{project_id}/secrets/{SECRET_ID}/versions/latest"
        client = secretmanager.SecretManagerServiceClient()
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")
    except Exception as e:
        logging.error(f"Erro ao buscar API Key: {e}")
        raise


def _build_llm(api_key: str) -> ChatGoogleGenerativeAI:
    return ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.3,
    )


def _parse_llm_json(raw: str) -> str:
    """Remove cercas de markdown caso o modelo adicione."""
    if "```json" in raw:
        return raw.split("```json")[1].split("```")[0].strip()
    if "```" in raw:
        return raw.split("```")[1].strip()
    return raw.strip()


# =============================================================================
# WEEKLY INSIGHTS
# =============================================================================

def run_weekly_insights_logic(uid: str) -> dict:
    """
    Gera e persiste os insights SEMANAIS do atleta.
    Retorna o dict final salvo no Firestore (útil para testes/logs).
    """
    db = firestore.client()
    logging.info(f"[weekly-insights] iniciando para uid={uid}")

    # 1) stats/summary
    stats_ref = db.collection("users").document(uid) \
                  .collection("stats").document("summary")
    stats_doc = stats_ref.get()
    if not stats_doc.exists:
        logging.info(f"[weekly-insights] {uid} sem stats/summary, abortando.")
        return {"skipped": "no_stats"}
    stats_summary = stats_doc.to_dict() or {}

    # 2) weekly_load da semana corrente (via weeklyLoadLabel do summary)
    week_label = stats_summary.get("weeklyLoadLabel")
    weekly_load = {}
    if week_label:
        wl_doc = db.collection("users").document(uid) \
                   .collection("weekly_load").document(week_label).get()
        if wl_doc.exists:
            weekly_load = wl_doc.to_dict() or {}

    if not weekly_load:
        logging.info(
            f"[weekly-insights] {uid} sem weekly_load atual, abortando."
        )
        return {"skipped": "no_weekly_load"}

    # 3) Resultados recentes da semana (leves, só pro contexto)
    recent_results = []
    try:
        week_start_str = weekly_load.get("weekStart")
        week_end_str = weekly_load.get("weekEnd")
        if week_start_str and week_end_str:
            results_ref = db.collection("users").document(uid) \
                            .collection("results")
            docs = results_ref \
                .where("date", ">=", week_start_str) \
                .where("date", "<=", week_end_str) \
                .limit(30) \
                .stream()
            for d in docs:
                r = d.to_dict() or {}
                recent_results.append({
                    "date": r.get("date"),
                    "effort": r.get("effort"),
                    "modalidade": r.get("modalidade"),
                    "keyMetrics": r.get("keyMetrics", []),
                })
    except Exception as e:
        logging.warning(f"[weekly-insights] falha ao carregar results: {e}")

    # 4) Prompt + LLM
    prompt_text = create_weekly_insights_prompt(
        stats_summary=stats_summary,
        weekly_load=weekly_load,
        recent_results=recent_results,
    )

    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)
    parser = get_weekly_parser()

    logging.info(f"[weekly-insights] enviando prompt para Gemini ({uid})")
    ai_message = llm.invoke(prompt_text)
    clean = _parse_llm_json(ai_message.content)
    parsed = parser.parse(clean).dict()

    # 5) Persistência
    final_doc = {
        **parsed,
        "weekLabel": week_label,
        "generatedFor": {
            "weekStart": weekly_load.get("weekStart"),
            "weekEnd": weekly_load.get("weekEnd"),
        },
        "lastGeneratedAt": firestore.SERVER_TIMESTAMP,
    }
    db.collection("users").document(uid) \
      .collection("insights").document("semanal") \
      .set(final_doc)

    logging.info(f"[weekly-insights] ✅ salvo para {uid} ({week_label})")
    return final_doc


# =============================================================================
# EVOLUTION INSIGHTS
# =============================================================================

def _is_cache_fresh(last_generated_at) -> bool:
    if not last_generated_at:
        return False
    try:
        # Firestore Timestamp → datetime (UTC)
        dt = (
            last_generated_at
            if isinstance(last_generated_at, datetime)
            else last_generated_at.to_datetime()
        )
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        age = datetime.now(tz=timezone.utc) - dt
        return age < timedelta(days=_EVOLUTION_CACHE_DAYS)
    except Exception:
        return False


def _aggregate_stimuli_from_results(db, uid: str, since_date: datetime) -> dict:
    """Conta keyMetrics dos últimos ~12 semanas."""
    counts = {}
    try:
        results_ref = db.collection("users").document(uid).collection("results")
        since_str = since_date.strftime("%Y-%m-%d")
        docs = results_ref.where("date", ">=", since_str).stream()
        for d in docs:
            r = d.to_dict() or {}
            for m in (r.get("keyMetrics") or []):
                if isinstance(m, str) and m.strip():
                    key = m.strip()
                    counts[key] = counts.get(key, 0) + 1
    except Exception as e:
        logging.warning(f"[evolution] falha ao agregar estímulos: {e}")
    return counts


def _summarize_prs(db, uid: str, since_date: datetime) -> dict:
    """Retorna {'count': int, 'byMovement': {movement: count}}."""
    out = {"count": 0, "byMovement": {}}
    try:
        prs_ref = db.collection("users").document(uid).collection("prs")
        docs = prs_ref.where("date", ">=", since_date).stream()
        for d in docs:
            p = d.to_dict() or {}
            out["count"] += 1
            mov = p.get("movementName") or p.get("movement") or "desconhecido"
            out["byMovement"][mov] = out["byMovement"].get(mov, 0) + 1
    except Exception as e:
        logging.warning(f"[evolution] falha ao sumarizar PRs: {e}")
    return out


def run_evolution_insights_logic(uid: str, force: bool = False) -> dict:
    """
    Chamado pelo onCall. Se cache < 4 dias, retorna o doc existente.
    Caso contrário, gera nova análise com base nas últimas 12 semanas.
    """
    db = firestore.client()
    logging.info(f"[evolution-insights] iniciando para uid={uid} force={force}")

    evolution_ref = db.collection("users").document(uid) \
                      .collection("insights").document("evolucao")
    existing = evolution_ref.get()
    existing_data = existing.to_dict() if existing.exists else None

    if (
        not force
        and existing_data
        and _is_cache_fresh(existing_data.get("lastGeneratedAt"))
    ):
        logging.info(f"[evolution-insights] cache quente para {uid}, reusando.")
        return {**existing_data, "fromCache": True}

    # stats/summary
    stats_doc = db.collection("users").document(uid) \
                  .collection("stats").document("summary").get()
    if not stats_doc.exists:
        return {"skipped": "no_stats"}
    stats_summary = stats_doc.to_dict() or {}

    # últimas 12 semanas de weekly_load (ordem cronológica asc)
    wl_ref = db.collection("users").document(uid).collection("weekly_load")
    wl_docs = list(
        wl_ref.order_by("weekLabel", direction=firestore.Query.DESCENDING)
              .limit(_EVOLUTION_WEEKS)
              .stream()
    )
    last_12_weeks = [d.to_dict() for d in wl_docs if d.to_dict()]
    last_12_weeks.reverse()  # asc

    if not last_12_weeks:
        return {"skipped": "no_history"}

    # PRs + estímulos das últimas 12 semanas
    since_date = datetime.now(tz=_TZ_BRAZIL) - timedelta(weeks=_EVOLUTION_WEEKS)
    prs_summary = _summarize_prs(db, uid, since_date)
    stimulus_distribution = _aggregate_stimuli_from_results(db, uid, since_date)

    # Prompt + LLM
    prompt_text = create_evolution_insights_prompt(
        stats_summary=stats_summary,
        last_12_weeks=last_12_weeks,
        prs_summary=prs_summary,
        stimulus_distribution=stimulus_distribution,
    )

    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)
    parser = get_evolution_parser()

    logging.info(f"[evolution-insights] enviando prompt ({uid})")
    ai_message = llm.invoke(prompt_text)
    clean = _parse_llm_json(ai_message.content)
    parsed = parser.parse(clean).dict()

    final_doc = {
        **parsed,
        "weeksAnalyzed": len(last_12_weeks),
        "lastGeneratedAt": firestore.SERVER_TIMESTAMP,
    }
    evolution_ref.set(final_doc)

    logging.info(f"[evolution-insights] ✅ salvo para {uid}")
    # Retorno imediato: substitui o sentinel por timestamp real
    return {
        **parsed,
        "weeksAnalyzed": len(last_12_weeks),
        "fromCache": False,
    }
