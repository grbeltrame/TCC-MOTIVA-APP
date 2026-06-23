#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo


FUNCTIONS_DIR = Path(__file__).resolve().parents[1]
if str(FUNCTIONS_DIR) not in sys.path:
    sys.path.insert(0, str(FUNCTIONS_DIR))

import firebase_admin
from firebase_admin import firestore
from google.cloud import secretmanager

from athlete_insights_module.context_builder import (
    build_evolution_context,
    build_pre_workout_context,
    build_weekly_context,
)
from athlete_insights_module.logic import (
    _aggregate_stimuli_from_results,
    _build_llm,
    _get_gemini_api_key,
    _result_context_fields,
    _summarize_prs,
)
from athlete_insights_module.llm_parser import parse_llm_response
from athlete_insights_module.models import (
    get_evolution_parser,
    get_pre_workout_parser,
    get_weekly_parser,
)
from athlete_insights_module.pre_workout_logic import (
    _extract_workout_summary,
    _fetch_athlete_current_load,
    _fetch_athlete_complementary_load_recent,
    _fetch_athlete_history_for_time_of_day,
    _fetch_athlete_history_same_type,
    _fetch_athlete_profile,
    _fetch_athlete_recent_prs,
)
from athlete_insights_module.prompt_builder import (
    create_evolution_insights_prompt,
    create_pre_workout_insights_prompt,
    create_weekly_insights_prompt,
)


_TZ_BRAZIL = ZoneInfo("America/Sao_Paulo")
_EVOLUTION_WEEKS = 12
_SECRET_ID = "GEMINI_API_KEY"


def _init_firestore(project_id: str | None):
    if project_id:
        os.environ.setdefault("GCLOUD_PROJECT", project_id)
        os.environ.setdefault("GOOGLE_CLOUD_PROJECT", project_id)
    if not firebase_admin._apps:
        firebase_admin.initialize_app()
    return firestore.client()


def _json_default(value):
    if hasattr(value, "to_datetime"):
        return value.to_datetime().isoformat()
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def _fetch_results_since(db, uid: str, since: str, limit: int = 80) -> list[dict]:
    docs = (
        db.collection("users")
        .document(uid)
        .collection("results")
        .where("date", ">=", since)
        .limit(limit)
        .stream()
    )
    return [_result_context_fields(doc.to_dict() or {}) for doc in docs]


def _load_cohort(db, uid: str):
    try:
        from cohort_module import find_athlete_cohort
        return find_athlete_cohort(uid, db)
    except Exception:
        return None


def _weekly_eval(db, uid: str):
    stats_doc = (
        db.collection("users").document(uid)
        .collection("stats").document("summary").get()
    )
    if not stats_doc.exists:
        raise RuntimeError(f"users/{uid}/stats/summary nao existe")
    stats_summary = stats_doc.to_dict() or {}

    week_label = stats_summary.get("weeklyLoadLabel")
    if not week_label:
        raise RuntimeError("stats/summary.weeklyLoadLabel ausente")

    wl_doc = (
        db.collection("users").document(uid)
        .collection("weekly_load").document(week_label).get()
    )
    if not wl_doc.exists:
        raise RuntimeError(f"weekly_load/{week_label} nao existe")
    weekly_load = wl_doc.to_dict() or {}

    week_start = weekly_load.get("weekStart")
    week_end = weekly_load.get("weekEnd")
    recent_results = []
    if week_start and week_end:
        docs = (
            db.collection("users").document(uid).collection("results")
            .where("date", ">=", week_start)
            .where("date", "<=", week_end)
            .limit(30)
            .stream()
        )
        recent_results = [_result_context_fields(doc.to_dict() or {}) for doc in docs]

    hist_docs = list(
        db.collection("users").document(uid).collection("weekly_load")
        .order_by("weekLabel", direction=firestore.Query.DESCENDING)
        .limit(5)
        .stream()
    )
    recent_weeks = []
    for doc in hist_docs:
        data = doc.to_dict() or {}
        if data.get("weekLabel") == week_label:
            continue
        recent_weeks.append({
            "weekLabel": data.get("weekLabel"),
            "weekStart": data.get("weekStart"),
            "weekEnd": data.get("weekEnd"),
            "wodDays": data.get("wodDays"),
            "restDays": data.get("restDays"),
            "avgRpeAll": data.get("avgRpeAll"),
            "monotony": data.get("monotony"),
            "strain": data.get("strain"),
            "totalLoadAll": data.get("totalLoadAll"),
            "icnAll": data.get("icnAll"),
            "acwrRaw": data.get("acwrRaw"),
            "cargaCronica": data.get("cargaCronica"),
            "baselineType": data.get("baselineType"),
            "prsCount": data.get("prsCount"),
            "dailyLoadsCrossfit": data.get("dailyLoadsCrossfit"),
            "stimuli": data.get("stimuli"),
        })
    recent_weeks = recent_weeks[:4]

    since = (datetime.now(tz=_TZ_BRAZIL) - timedelta(days=60)).strftime("%Y-%m-%d")
    performance_results = _fetch_results_since(db, uid, since)
    weekly_context = build_weekly_context(
        stats_summary=stats_summary,
        weekly_load=weekly_load,
        recent_results=recent_results,
        recent_weeks=recent_weeks,
        performance_results=performance_results,
    )
    prompt = create_weekly_insights_prompt(
        stats_summary=stats_summary,
        weekly_load=weekly_load,
        recent_results=recent_results,
        recent_weeks=recent_weeks,
        weekly_context=weekly_context,
        now=datetime.now(tz=_TZ_BRAZIL),
        cohort=_load_cohort(db, uid),
    )
    return {
        "flow": "weekly",
        "prompt": prompt,
        "parser": get_weekly_parser(),
        "summary": {
            "weekLabel": week_label,
            "recentResults": len(recent_results),
            "performanceResults": len(performance_results),
            "weeklyContext": weekly_context,
        },
    }


def _evolution_eval(db, uid: str):
    stats_doc = (
        db.collection("users").document(uid)
        .collection("stats").document("summary").get()
    )
    if not stats_doc.exists:
        raise RuntimeError(f"users/{uid}/stats/summary nao existe")
    stats_summary = stats_doc.to_dict() or {}

    wl_docs = list(
        db.collection("users").document(uid).collection("weekly_load")
        .order_by("weekLabel", direction=firestore.Query.DESCENDING)
        .limit(_EVOLUTION_WEEKS)
        .stream()
    )
    last_12_weeks = [doc.to_dict() for doc in wl_docs if doc.to_dict()]
    last_12_weeks.reverse()
    if not last_12_weeks:
        raise RuntimeError("sem weekly_load historico")

    since_date = datetime.now(tz=_TZ_BRAZIL) - timedelta(weeks=_EVOLUTION_WEEKS)
    prs_summary = _summarize_prs(db, uid, since_date)
    stimulus_distribution = _aggregate_stimuli_from_results(db, uid, since_date)
    evolution_context = build_evolution_context(
        last_12_weeks=last_12_weeks,
        prs_summary=prs_summary,
        stimulus_distribution=stimulus_distribution,
    )
    prompt = create_evolution_insights_prompt(
        stats_summary=stats_summary,
        last_12_weeks=last_12_weeks,
        prs_summary=prs_summary,
        stimulus_distribution=stimulus_distribution,
        evolution_context=evolution_context,
        cohort=_load_cohort(db, uid),
    )
    return {
        "flow": "evolution",
        "prompt": prompt,
        "parser": get_evolution_parser(),
        "summary": {
            "weeks": len(last_12_weeks),
            "prs": prs_summary.get("count"),
            "evolutionContext": evolution_context,
        },
    }


def _pre_workout_eval(db, uid: str, workout_id: str):
    if not workout_id:
        raise RuntimeError("--workout-id e obrigatorio para pre_workout")
    workout_doc = db.collection("exercises").document(workout_id).get()
    if not workout_doc.exists:
        raise RuntimeError(f"exercises/{workout_id} nao existe")

    workout_data = workout_doc.to_dict() or {}
    workout_summary = _extract_workout_summary(workout_data)
    workout_summary["workoutId"] = workout_id

    profile = _fetch_athlete_profile(db, uid)
    history = _fetch_athlete_history_same_type(db, uid, workout_summary)
    current_load = _fetch_athlete_current_load(db, uid)
    recent_prs = _fetch_athlete_recent_prs(db, uid)
    time_of_day_history = _fetch_athlete_history_for_time_of_day(db, uid)
    complementary_load = _fetch_athlete_complementary_load_recent(db, uid)
    pre_workout_context = build_pre_workout_context(
        workout=workout_summary,
        athlete_history_same_type=history,
        athlete_current_load=current_load,
        athlete_recent_prs=recent_prs,
        time_of_day_history=time_of_day_history,
        complementary_load_recent=complementary_load,
    )
    prompt = create_pre_workout_insights_prompt(
        workout=workout_summary,
        athlete_profile=profile,
        athlete_history_same_type=history,
        athlete_current_load=current_load,
        athlete_recent_prs=recent_prs,
        pre_workout_context=pre_workout_context,
        now=datetime.now(tz=_TZ_BRAZIL),
        cohort=_load_cohort(db, uid),
    )
    return {
        "flow": "pre_workout",
        "prompt": prompt,
        "parser": get_pre_workout_parser(),
        "summary": {
            "workoutId": workout_id,
            "sameTypeHistory": len(history),
            "timeOfDayHistory": len(time_of_day_history),
            "complementaryLoadRecent": len(complementary_load),
            "recentPrs": len(recent_prs),
            "preWorkoutContext": pre_workout_context,
        },
    }


def _api_key(project_id: str | None) -> str:
    env_key = os.environ.get("GEMINI_API_KEY")
    if env_key:
        return env_key

    effective_project_id = (
        project_id
        or os.environ.get("GCLOUD_PROJECT")
        or os.environ.get("GOOGLE_CLOUD_PROJECT")
    )
    if effective_project_id:
        name = (
            f"projects/{effective_project_id}/secrets/"
            f"{_SECRET_ID}/versions/latest"
        )
        client = secretmanager.SecretManagerServiceClient()
        response = client.access_secret_version(request={"name": name})
        return response.payload.data.decode("UTF-8")

    return _get_gemini_api_key()


def _messages_from_parsed(parsed: dict) -> list[str]:
    messages = []
    for bucket in ("alertas", "informacoes"):
        values = parsed.get(bucket) or {}
        if isinstance(values, dict):
            for value in values.values():
                if isinstance(value, dict):
                    text = value.get("message") or value.get("detail")
                    if text:
                        messages.append(str(text))
    return messages


def _quality_check(parsed: dict, flow: str, summary: dict) -> dict:
    messages = _messages_from_parsed(parsed)
    joined = "\n".join(messages).lower()
    generic_markers = [
        "treinou bem",
        "consistência foi boa",
        "precisa descansar",
        "cuidado com o descanso",
        "continue assim",
    ]
    workout_anchors = []
    if flow == "pre_workout":
        context = summary.get("preWorkoutContext") or {}
        anchors = (context.get("todayAnchors") or {}).get("movements") or []
        workout_anchors = [
            anchor for anchor in anchors
            if anchor and str(anchor).lower() in joined
        ]

    return {
        "messageCount": len(messages),
        "hasConcreteNumber": bool(re.search(r"\d", joined)),
        "hasTemporalContrast": any(
            marker in joined for marker in [
                "semana passada", "ultimos", "últimos", "antes", "agora",
                "da ultima vez", "da última vez", "dessa vez",
            ]
        ),
        "genericMarkersFound": [
            marker for marker in generic_markers if marker in joined
        ],
        "preWorkoutAnchorsFound": workout_anchors[:5],
    }


def _run_llm(item: dict, no_llm: bool, project_id: str | None):
    if no_llm:
        return None, None
    llm = _build_llm(_api_key(project_id))
    raw = llm.invoke(item["prompt"]).content
    parsed = parse_llm_response(
        raw,
        item["parser"],
        flow=f"evaluate-{item['flow']}",
    )
    return raw, parsed


def _print_section(title: str, payload):
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)
    if isinstance(payload, str):
        print(payload)
    else:
        print(json.dumps(payload, ensure_ascii=False, indent=2, default=_json_default))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Avalia prompts reais do athlete_insights_module sem escrever no Firestore."
    )
    parser.add_argument("--uid", required=True)
    parser.add_argument("--flow", choices=["weekly", "evolution", "pre_workout", "all"], required=True)
    parser.add_argument("--workout-id")
    parser.add_argument("--project-id")
    parser.add_argument("--no-llm", action="store_true", help="Monta prompt sem chamar Gemini.")
    parser.add_argument("--hide-prompt", action="store_true")
    parser.add_argument("--prompt-max-chars", type=int, default=12000)
    args = parser.parse_args()

    db = _init_firestore(args.project_id)
    flows = ["weekly", "evolution", "pre_workout"] if args.flow == "all" else [args.flow]

    builders = {
        "weekly": lambda: _weekly_eval(db, args.uid),
        "evolution": lambda: _evolution_eval(db, args.uid),
        "pre_workout": lambda: _pre_workout_eval(db, args.uid, args.workout_id),
    }

    for flow in flows:
        item = builders[flow]()
        _print_section(f"{flow.upper()} - resumo dos dados", item["summary"])
        if not args.hide_prompt:
            prompt = item["prompt"]
            if args.prompt_max_chars > 0 and len(prompt) > args.prompt_max_chars:
                prompt = (
                    prompt[:args.prompt_max_chars]
                    + f"\n\n...[prompt truncado: {len(item['prompt'])} chars totais]"
                )
            _print_section(f"{flow.upper()} - prompt", prompt)

        raw, parsed = _run_llm(item, args.no_llm, args.project_id)
        if args.no_llm:
            continue
        _print_section(f"{flow.upper()} - resposta crua Gemini", raw)
        _print_section(f"{flow.upper()} - JSON parseado", parsed)
        _print_section(
            f"{flow.upper()} - checklist de qualidade",
            _quality_check(parsed, flow, item["summary"]),
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
