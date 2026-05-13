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
from .context_builder import (
    build_evolution_context,
    build_weekly_context,
    week_label_for_date,
)
from .llm_parser import extract_json_object, parse_llm_response
from .models import get_weekly_parser, get_evolution_parser

_TZ_BRAZIL = ZoneInfo("America/Sao_Paulo")

SECRET_ID = "GEMINI_API_KEY"
PROJECT_ID = os.environ.get("GCLOUD_PROJECT")

# Cache da análise de evolução: 4 dias.
_EVOLUTION_CACHE_DAYS = 4

# Histórico considerado pela análise de evolução.
_EVOLUTION_WEEKS = 12


def _result_context_fields(data: dict) -> dict:
    return {
        "date": data.get("date"),
        "effort": data.get("effort"),
        "modalidade": data.get("modalidade"),
        "wodType": data.get("wodType"),
        "completed": data.get("completed"),
        "forTimeSec": data.get("forTimeSec"),
        "amrapRounds": data.get("amrapRounds"),
        "amrapReps": data.get("amrapReps"),
        "trainingTime": data.get("trainingTime"),
        "category": data.get("category"),
        "keyMetrics": data.get("keyMetrics", []),
    }


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
    """Backward-compatible wrapper around the robust JSON extractor."""
    return extract_json_object(raw)


def _record_insight_event(
    kind: str,
    status: str,
    *,
    reason: str | None = None,
    with_cohort: bool = False,
    prompt_chars: int = 0,
    response_chars: int = 0,
) -> None:
    try:
        from telemetry_module import record_insight_event
        record_insight_event(
            kind,
            status=status,
            reason=reason,
            with_cohort=with_cohort,
            prompt_chars=prompt_chars,
            response_chars=response_chars,
        )
    except Exception:
        pass


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

    from user_settings_module import athlete_ai_enabled
    if not athlete_ai_enabled(db, uid):
        logging.info(f"[weekly-insights] {uid}: IA desativada ou conta inativa.")
        _record_insight_event("weekly", "skipped", reason="ai_disabled")
        return {"skipped": "ai_disabled"}

    # 1) stats/summary
    stats_ref = db.collection("users").document(uid) \
                  .collection("stats").document("summary")
    stats_doc = stats_ref.get()
    if not stats_doc.exists:
        logging.info(f"[weekly-insights] {uid} sem stats/summary, abortando.")
        _record_insight_event("weekly", "skipped", reason="no_stats")
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
        _record_insight_event("weekly", "skipped", reason="no_weekly_load")
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
                recent_results.append(_result_context_fields(r))
    except Exception as e:
        logging.warning(f"[weekly-insights] falha ao carregar results: {e}")

    # 3b) Resultados recentes ampliados para tendencias objetivas
    performance_results = []
    try:
        results_ref = db.collection("users").document(uid).collection("results")
        since_str = (
            datetime.now(tz=_TZ_BRAZIL) - timedelta(days=60)
        ).strftime("%Y-%m-%d")
        docs = results_ref.where("date", ">=", since_str).limit(80).stream()
        for d in docs:
            r = d.to_dict() or {}
            performance_results.append(_result_context_fields(r))
    except Exception as e:
        logging.warning(
            f"[weekly-insights] falha ao carregar performance recente: {e}"
        )

    # 4) Histórico das últimas 4 semanas (exclui a semana atual)
    recent_weeks = []
    try:
        wl_ref = db.collection("users").document(uid).collection("weekly_load")
        hist_docs = list(
            wl_ref.order_by("weekLabel", direction=firestore.Query.DESCENDING)
                  .limit(5)
                  .stream()
        )
        for d in hist_docs:
            data = d.to_dict() or {}
            if data.get("weekLabel") != week_label:
                recent_weeks.append({
                    "weekLabel":     data.get("weekLabel"),
                    "weekStart":     data.get("weekStart"),
                    "weekEnd":       data.get("weekEnd"),
                    "wodDays":       data.get("wodDays"),
                    "restDays":      data.get("restDays"),
                    "avgRpeAll":     data.get("avgRpeAll"),
                    "monotony":      data.get("monotony"),
                    "strain":        data.get("strain"),
                    "totalLoadAll":  data.get("totalLoadAll"),
                    "icnAll":        data.get("icnAll"),
                    "acwrRaw":       data.get("acwrRaw"),
                    "cargaCronica":  data.get("cargaCronica"),
                    "baselineType":  data.get("baselineType"),
                    "prsCount":      data.get("prsCount"),
                    "dailyLoadsCrossfit": data.get("dailyLoadsCrossfit"),
                    "stimuli":       data.get("stimuli"),
                })
        recent_weeks = sorted(
            recent_weeks[:4],
            key=lambda week: str(
                week.get("weekLabel") or week.get("weekStart") or ""
            ),
        )
    except Exception as e:
        logging.warning(f"[weekly-insights] falha ao carregar histórico: {e}")

    # 5) Coorte do atleta (se elegível)
    cohort = None
    try:
        from cohort_module import find_athlete_cohort
        cohort = find_athlete_cohort(uid, db)
    except Exception as e:
        logging.warning(f"[weekly-insights] {uid}: cohort lookup falhou: {e}")

    # 6) Prompt + LLM
    weekly_context = build_weekly_context(
        stats_summary=stats_summary,
        weekly_load=weekly_load,
        recent_results=recent_results,
        recent_weeks=recent_weeks,
        performance_results=performance_results,
    )

    prompt_text = create_weekly_insights_prompt(
        stats_summary=stats_summary,
        weekly_load=weekly_load,
        recent_results=recent_results,
        recent_weeks=recent_weeks,
        weekly_context=weekly_context,
        now=datetime.now(tz=_TZ_BRAZIL),
        cohort=cohort,
    )

    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)
    parser = get_weekly_parser()

    logging.info(f"[weekly-insights] enviando prompt para Gemini ({uid})")
    try:
        ai_message = llm.invoke(prompt_text)
        parsed = parse_llm_response(
            ai_message.content,
            parser,
            flow="weekly-insights",
            uid=uid,
        )
    except Exception:
        _record_insight_event(
            "weekly",
            "failed",
            reason="llm_or_parse_error",
            with_cohort=cohort is not None,
            prompt_chars=len(prompt_text),
            response_chars=len(
                getattr(locals().get("ai_message", None), "content", "") or ""
            ),
        )
        raise

    _record_insight_event(
        "weekly",
        "generated",
        with_cohort=cohort is not None,
        prompt_chars=len(prompt_text),
        response_chars=len(ai_message.content or ''),
    )

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

    try:
        from notification_module import create_user_notification
        create_user_notification(
            db=db,
            uid=uid,
            role="athlete",
            type_="athlete_weekly_insights_ready",
            title="Seu resumo semanal está pronto",
            body="A análise da sua semana foi finalizada e já está disponível.",
            dedupe_key=f"athlete-weekly-insights:{uid}:{week_label}",
            route_name="/athlete_insight",
            source_id=week_label,
        )
    except Exception as e:
        logging.warning(f"[weekly-insights] falha ao notificar {uid}: {e}")

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


def _stream_date_docs_since(collection_ref, since_date: datetime):
    """
    Reads docs whose `date` may be either Firestore Timestamp/datetime or legacy
    YYYY-MM-DD string. The app currently writes PR dates as Timestamp, while
    results use string day keys; supporting both avoids silent historical gaps.
    """
    seen = {}
    bounds = (since_date, since_date.strftime("%Y-%m-%d"))
    for bound in bounds:
        try:
            for doc in collection_ref.where("date", ">=", bound).stream():
                seen[doc.id] = doc
        except Exception as e:
            logging.warning(
                f"[insights] falha ao consultar date >= {type(bound).__name__}: {e}"
            )
    return list(seen.values())


def _summarize_prs(db, uid: str, since_date: datetime) -> dict:
    """Retorna contagem de PRs, movimentos e itens datados para contexto."""
    out = {"count": 0, "byMovement": {}, "items": []}
    try:
        prs_ref = db.collection("users").document(uid).collection("prs")
        docs = _stream_date_docs_since(prs_ref, since_date)
        for d in docs:
            p = d.to_dict() or {}
            out["count"] += 1
            mov = p.get("movementName") or p.get("movement") or "desconhecido"
            out["byMovement"][mov] = out["byMovement"].get(mov, 0) + 1
            out["items"].append({
                "date": p.get("date"),
                "weekLabel": p.get("weekLabel") or week_label_for_date(p.get("date")),
                "movementName": mov,
                "value": p.get("value"),
                "unit": p.get("unit"),
                "prType": p.get("prType"),
            })
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
        _record_insight_event("evolution", "from_cache", reason="cache_fresh")
        return {**existing_data, "fromCache": True}

    from user_settings_module import athlete_ai_enabled
    if not athlete_ai_enabled(db, uid):
        logging.info(f"[evolution-insights] {uid}: IA desativada ou conta inativa.")
        _record_insight_event("evolution", "skipped", reason="ai_disabled")
        return {"skipped": "ai_disabled"}

    # stats/summary
    stats_doc = db.collection("users").document(uid) \
                  .collection("stats").document("summary").get()
    if not stats_doc.exists:
        _record_insight_event("evolution", "skipped", reason="no_stats")
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
        _record_insight_event("evolution", "skipped", reason="no_history")
        return {"skipped": "no_history"}

    # PRs + estímulos das últimas 12 semanas
    since_date = datetime.now(tz=_TZ_BRAZIL) - timedelta(weeks=_EVOLUTION_WEEKS)
    prs_summary = _summarize_prs(db, uid, since_date)
    stimulus_distribution = _aggregate_stimuli_from_results(db, uid, since_date)
    evolution_context = build_evolution_context(
        last_12_weeks=last_12_weeks,
        prs_summary=prs_summary,
        stimulus_distribution=stimulus_distribution,
    )

    # Coorte (se elegível)
    cohort = None
    try:
        from cohort_module import find_athlete_cohort
        cohort = find_athlete_cohort(uid, db)
    except Exception as e:
        logging.warning(f"[evolution-insights] {uid}: cohort lookup falhou: {e}")

    # Prompt + LLM
    prompt_text = create_evolution_insights_prompt(
        stats_summary=stats_summary,
        last_12_weeks=last_12_weeks,
        prs_summary=prs_summary,
        stimulus_distribution=stimulus_distribution,
        evolution_context=evolution_context,
        cohort=cohort,
    )

    api_key = _get_gemini_api_key()
    llm = _build_llm(api_key)
    parser = get_evolution_parser()

    logging.info(f"[evolution-insights] enviando prompt ({uid})")
    try:
        ai_message = llm.invoke(prompt_text)
        parsed = parse_llm_response(
            ai_message.content,
            parser,
            flow="evolution-insights",
            uid=uid,
        )
    except Exception:
        _record_insight_event(
            "evolution",
            "failed",
            reason="llm_or_parse_error",
            with_cohort=cohort is not None,
            prompt_chars=len(prompt_text),
            response_chars=len(
                getattr(locals().get("ai_message", None), "content", "") or ""
            ),
        )
        raise

    _record_insight_event(
        "evolution",
        "generated",
        with_cohort=cohort is not None,
        prompt_chars=len(prompt_text),
        response_chars=len(ai_message.content or ''),
    )

    final_doc = {
        **parsed,
        "weeksAnalyzed": len(last_12_weeks),
        "lastGeneratedAt": firestore.SERVER_TIMESTAMP,
    }
    evolution_ref.set(final_doc)

    try:
        from notification_module import create_user_notification
        create_user_notification(
            db=db,
            uid=uid,
            role="athlete",
            type_="athlete_evolution_insights_ready",
            title="Sua análise de evolução está pronta",
            body="A leitura das suas últimas semanas foi finalizada.",
            dedupe_key=f"athlete-evolution-insights:{uid}:{datetime.now(tz=_TZ_BRAZIL).strftime('%Y-%m-%d')}",
            route_name="/athlete_evolution",
            source_id="evolucao",
        )
    except Exception as e:
        logging.warning(f"[evolution-insights] falha ao notificar {uid}: {e}")

    logging.info(f"[evolution-insights] ✅ salvo para {uid}")
    # Retorno imediato: substitui o sentinel por timestamp real
    return {
        **parsed,
        "weeksAnalyzed": len(last_12_weeks),
        "fromCache": False,
    }
