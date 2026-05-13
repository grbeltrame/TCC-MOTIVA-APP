from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime, timedelta
from statistics import mean
from typing import Any


_ROUND_MILESTONES = (50, 75, 100, 150, 200, 250, 300, 400, 500)


def _to_float(value: Any) -> float | None:
    try:
        if value is None or value == "":
            return None
        return float(value)
    except (TypeError, ValueError):
        return None


def _to_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


def _date_value(value: Any) -> datetime | None:
    if value is None:
        return None
    if hasattr(value, "to_datetime"):
        value = value.to_datetime()
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        text = value[:10]
        for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
            try:
                return datetime.strptime(text, fmt)
            except ValueError:
                pass
    return None


def _date_key(value: Any) -> str | None:
    dt = _date_value(value)
    return dt.strftime("%Y-%m-%d") if dt else None


def week_label_for_date(value: Any) -> str | None:
    dt = _date_value(value)
    if not dt:
        return None

    days_since_sunday = (dt.weekday() + 1) % 7
    week_start = (
        dt.replace(hour=0, minute=0, second=0, microsecond=0)
        - timedelta(days=days_since_sunday)
    ).replace(tzinfo=None)

    year = week_start.year
    jan1 = datetime(year, 1, 1)
    days_to_first_sunday = (6 - jan1.weekday()) % 7
    first_sunday = jan1 + timedelta(days=days_to_first_sunday)

    if week_start < first_sunday:
        return week_label_for_date(datetime(year - 1, 12, 31))

    week_num = ((week_start - first_sunday).days // 7) + 1
    return f"{year}-W{week_num:02d}"


def _normalize_modality(value: Any) -> str:
    return str(value or "").strip().upper()


def _normalize_wod_type(value: Any) -> str:
    return str(value or "").strip().upper()


def _objective_entry(result: dict) -> dict | None:
    modality = _normalize_modality(result.get("modalidade"))
    date = _date_key(result.get("date"))
    if not date:
        return None

    if "FOR TIME" in modality:
        seconds = _to_float(result.get("forTimeSec"))
        if seconds and seconds > 0:
            return {
                "date": date,
                "modality": modality,
                "kind": "for_time",
                "value": seconds,
                "lowerIsBetter": True,
            }

    if modality == "AMRAP":
        rounds = _to_int(result.get("amrapRounds")) or 0
        reps = _to_int(result.get("amrapReps")) or 0
        if rounds > 0 or reps > 0:
            return {
                "date": date,
                "modality": modality,
                "kind": "amrap",
                "value": rounds * 1000 + reps,
                "rounds": rounds,
                "reps": reps,
                "lowerIsBetter": False,
            }

    return None


def _trend_from_entries(entries: list[dict]) -> dict | None:
    ordered = sorted(entries, key=lambda item: item["date"])
    if len(ordered) < 3:
        return None

    first = ordered[0]["value"]
    last = ordered[-1]["value"]
    lower_is_better = bool(ordered[-1].get("lowerIsBetter"))

    if lower_is_better:
        delta = first - last
        direction = "improving" if delta > 0 else "declining" if delta < 0 else "flat"
    else:
        delta = last - first
        direction = "improving" if delta > 0 else "declining" if delta < 0 else "flat"

    return {
        "direction": direction,
        "sampleSize": len(ordered),
        "firstDate": ordered[0]["date"],
        "lastDate": ordered[-1]["date"],
        "firstValue": first,
        "lastValue": last,
        "delta": round(delta, 1),
        "kind": ordered[-1].get("kind"),
    }


def _completion_rates(results: list[dict]) -> dict:
    grouped: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "completed": 0})
    for result in results:
        modality = _normalize_modality(result.get("modalidade")) or "UNKNOWN"
        grouped[modality]["total"] += 1
        if result.get("completed") is True:
            grouped[modality]["completed"] += 1

    out = {}
    for modality, values in grouped.items():
        total = values["total"]
        completed = values["completed"]
        out[modality] = {
            "total": total,
            "completed": completed,
            "rate": round(completed / total, 2) if total else None,
        }
    return out


def _category_mix(results: list[dict]) -> dict:
    counts = Counter(
        str(result.get("category") or "").strip().lower()
        for result in results
        if str(result.get("category") or "").strip()
    )
    total = sum(counts.values())
    if not total:
        return {}

    def _sum_keys(keys: list[str]) -> int:
        return sum(counts.get(key, 0) for key in keys)

    rx = _sum_keys(["rx"])
    scaled = _sum_keys(["scaled", "scale"])
    intermediate = _sum_keys(["intermediário", "intermediario", "intermediate"])
    other = total - rx - scaled - intermediate

    return {
        "counts": dict(counts),
        "totalWithCategory": total,
        "rxPercentage": round((rx / total) * 100, 1),
        "scaledPercentage": round((scaled / total) * 100, 1),
        "intermediatePercentage": round((intermediate / total) * 100, 1),
        "otherPercentage": round((other / total) * 100, 1),
    }


def _load_shape(daily_loads: dict | None) -> dict:
    if not daily_loads:
        return {"shape": "unknown", "totalLoad": 0.0}

    ordered = sorted(
        ((date, _to_float(load) or 0.0) for date, load in daily_loads.items()),
        key=lambda item: item[0],
    )
    total = sum(load for _, load in ordered)
    if total <= 0:
        return {"shape": "empty", "totalLoad": 0.0}

    first_half = sum(load for _, load in ordered[:3])
    last_half = sum(load for _, load in ordered[-3:])
    heaviest = max(ordered, key=lambda item: item[1])
    positive_days = [date for date, load in ordered if load > 0]

    if len(positive_days) == 1:
        shape = "single_peak"
    elif first_half > last_half * 1.2:
        shape = "front_loaded"
    elif last_half > first_half * 1.2:
        shape = "back_loaded"
    else:
        shape = "balanced"

    return {
        "shape": shape,
        "totalLoad": round(total, 1),
        "heaviestDay": heaviest[0],
        "heaviestLoad": round(heaviest[1], 1),
        "trainingDays": len(positive_days),
    }


def _milestone_context(stats_summary: dict) -> dict | None:
    total = _to_int(stats_summary.get("totalTrainingDays"))
    if total is None:
        return None

    for target in _ROUND_MILESTONES:
        remaining = target - total
        if 0 < remaining <= 5:
            return {
                "currentTotal": total,
                "target": target,
                "remaining": remaining,
            }
        if remaining == 0:
            return {
                "currentTotal": total,
                "target": target,
                "remaining": 0,
                "completedNow": True,
            }
    return None


def _modality_performance_context(results: list[dict]) -> dict:
    grouped_entries: dict[str, list[dict]] = defaultdict(list)
    for result in results:
        entry = _objective_entry(result)
        if entry:
            grouped_entries[entry["modality"]].append(entry)

    trends = {}
    for modality, entries in grouped_entries.items():
        trend = _trend_from_entries(entries)
        if trend:
            trends[modality] = trend
    return trends


def build_weekly_context(
    stats_summary: dict,
    weekly_load: dict,
    recent_results: list[dict],
    recent_weeks: list[dict] | None = None,
    performance_results: list[dict] | None = None,
) -> dict:
    performance_results = performance_results or recent_results
    recent_weeks = recent_weeks or []

    current_shape = _load_shape((weekly_load or {}).get("dailyLoadsCrossfit"))
    prior_shapes = [
        _load_shape(week.get("dailyLoadsCrossfit"))
        for week in recent_weeks
        if isinstance(week, dict)
    ]
    prior_shape_counts = Counter(
        item["shape"] for item in prior_shapes
        if item.get("shape") not in {"unknown", "empty"}
    )
    habitual_shape = (
        prior_shape_counts.most_common(1)[0][0]
        if prior_shape_counts else None
    )

    microcycle_shift = None
    if (
        habitual_shape
        and current_shape.get("shape") not in {"unknown", "empty"}
        and current_shape.get("shape") != habitual_shape
    ):
        microcycle_shift = {
            "habitualShape": habitual_shape,
            "currentShape": current_shape.get("shape"),
            "weeksCompared": sum(prior_shape_counts.values()),
        }

    return {
        "milestone": _milestone_context(stats_summary or {}),
        "currentMicrocycle": current_shape,
        "habitualMicrocycleShape": habitual_shape,
        "microcycleShift": microcycle_shift,
        "modalityPerformanceTrends": _modality_performance_context(performance_results),
        "completionRateByModality": _completion_rates(performance_results),
        "categoryMix": _category_mix(performance_results),
        "performanceResultsAnalyzed": len(performance_results),
    }


def _zone_for_icn(icn: float | None) -> str | None:
    if icn is None:
        return None
    if icn < 45:
        return "low"
    if icn <= 65:
        return "medium"
    return "high"


def build_evolution_context(
    last_12_weeks: list[dict],
    prs_summary: dict,
    stimulus_distribution: dict,
) -> dict:
    weeks = [week for week in (last_12_weeks or []) if isinstance(week, dict)]
    week_map = {week.get("weekLabel"): week for week in weeks if week.get("weekLabel")}

    blocks = []
    for idx in range(0, len(weeks), 4):
        chunk = weeks[idx:idx + 4]
        if not chunk:
            continue
        prs = sum(_to_int(week.get("prsCount")) or 0 for week in chunk)
        wod_days = sum(_to_int(week.get("wodDays")) or 0 for week in chunk)
        icns = [
            value for value in (_to_float(week.get("icnAll")) for week in chunk)
            if value is not None
        ]
        healthy_weeks = sum(1 for value in icns if 40 <= value <= 75)
        high_weeks = sum(1 for value in icns if value > 75)
        score = (prs * 4) + (wod_days * 0.5) + healthy_weeks - high_weeks
        blocks.append({
            "blockIndex": (idx // 4) + 1,
            "weekStart": chunk[0].get("weekStart"),
            "weekEnd": chunk[-1].get("weekEnd"),
            "prsCount": prs,
            "wodDays": wod_days,
            "avgIcnAll": round(mean(icns), 1) if icns else None,
            "healthyWeeks": healthy_weeks,
            "score": round(score, 2),
        })

    best_block = max(blocks, key=lambda block: block["score"]) if blocks else None

    pr_items = [
        item for item in (prs_summary or {}).get("items", [])
        if isinstance(item, dict)
    ]
    zones = Counter()
    matched_icns = []
    for item in pr_items:
        week_label = item.get("weekLabel") or week_label_for_date(item.get("date"))
        week = week_map.get(week_label)
        if not week:
            continue
        icn = _to_float(week.get("icnAll"))
        zone = _zone_for_icn(icn)
        if zone:
            zones[zone] += 1
            matched_icns.append(icn)

    peak_profile = {
        "status": "insufficient_data",
        "prsMatchedToWeeks": len(matched_icns),
        "minimumRequired": 3,
    }
    if len(matched_icns) >= 3:
        dominant_zone, count = zones.most_common(1)[0]
        peak_profile = {
            "status": "available",
            "dominantZone": dominant_zone,
            "zoneCounts": dict(zones),
            "prsMatchedToWeeks": len(matched_icns),
            "avgIcnOnPrWeeks": round(mean(matched_icns), 1),
            "dominantZoneShare": round(count / len(matched_icns), 2),
        }

    total_prs = _to_int((prs_summary or {}).get("count")) or 0
    total_wod_days = sum(_to_int(week.get("wodDays")) or 0 for week in weeks)

    return {
        "bestFourWeekPhase": best_block,
        "allFourWeekPhases": blocks,
        "peakPerformanceProfile": peak_profile,
        "prEfficiency": {
            "prsCount": total_prs,
            "wodDays": total_wod_days,
            "prsPerWodDay": round(total_prs / total_wod_days, 3)
            if total_wod_days else None,
        },
        "stimulusDistribution": stimulus_distribution or {},
        "gapAnalysisPolicy": (
            "Use gaps conservatively: only mention a stimulus gap when the "
            "stimulus exists in stimulus_distribution and the PR evidence is "
            "clearly absent. Do not invent a movement-to-stimulus mapping."
        ),
    }


def _workout_movements(workout: dict) -> list[str]:
    parts = (workout or {}).get("partes") or {}
    movements = []
    if isinstance(parts, dict):
        for section in parts.values():
            if not isinstance(section, dict):
                continue
            for item in section.get("exercicios") or []:
                if not isinstance(item, dict):
                    continue
                text = item.get("nome") or item.get("raw")
                if text:
                    movements.append(str(text))
    return movements


def _recent_result_anchor(history: list[dict]) -> dict | None:
    if not history:
        return None
    ordered = sorted(
        [item for item in history if _date_key(item.get("date"))],
        key=lambda item: _date_key(item.get("date")) or "",
        reverse=True,
    )
    if not ordered:
        return None
    item = ordered[0]
    return {
        "date": item.get("date"),
        "effort": item.get("effort"),
        "modalidade": item.get("modalidade"),
        "completed": item.get("completed"),
        "forTimeSec": item.get("forTimeSec"),
        "amrapRounds": item.get("amrapRounds"),
        "amrapReps": item.get("amrapReps"),
        "trainingTime": item.get("trainingTime"),
    }


def _matches_workout_type(item: dict, target_modality: str, target_wod_type: str) -> bool:
    modality_matches = (
        bool(target_modality)
        and _normalize_modality(item.get("modalidade")) == target_modality
    )
    wod_type_matches = (
        bool(target_wod_type)
        and _normalize_wod_type(item.get("wodType")) == target_wod_type
    )
    return modality_matches or wod_type_matches


def _aggregate_completion_rate(results: list[dict]) -> dict | None:
    if not results:
        return None

    total = len(results)
    completed = sum(1 for item in results if item.get("completed") is True)
    return {
        "total": total,
        "completed": completed,
        "rate": round(completed / total, 2) if total else None,
    }


def build_pre_workout_context(
    workout: dict,
    athlete_history_same_type: list[dict],
    athlete_current_load: dict,
    athlete_recent_prs: list[dict],
    same_weekday_history: list[dict] | None = None,
) -> dict:
    movements = _workout_movements(workout)
    workout_text = " ".join(movements).lower()
    prs_in_workout = []
    for pr in athlete_recent_prs or []:
        movement = str(pr.get("movementName") or pr.get("movement") or "").strip()
        if movement and movement.lower() in workout_text:
            prs_in_workout.append(pr)

    weekday_efforts = [
        _to_float(item.get("effort"))
        for item in (same_weekday_history or [])
        if _to_float(item.get("effort")) is not None
    ]
    target_modality = _normalize_modality((workout or {}).get("modalidade"))
    target_wod_type = _normalize_wod_type((workout or {}).get("wodType"))
    same_weekday_same_type = [
        item for item in (same_weekday_history or [])
        if _matches_workout_type(item, target_modality, target_wod_type)
    ] if (target_modality or target_wod_type) else []
    weekday_same_type_efforts = [
        _to_float(item.get("effort"))
        for item in same_weekday_same_type
        if _to_float(item.get("effort")) is not None
    ]
    same_type_history = [
        item for item in (athlete_history_same_type or [])
        if _matches_workout_type(item, target_modality, target_wod_type)
    ] if (target_modality or target_wod_type) else []

    return {
        "todayAnchors": {
            "modalidade": (workout or {}).get("modalidade"),
            "duracaoMinutos": (workout or {}).get("duracaoMinutos"),
            "keyMetrics": (workout or {}).get("keyMetrics") or [],
            "movements": movements[:12],
        },
        "latestSimilarResult": _recent_result_anchor(athlete_history_same_type),
        "objectiveTrendSameType": _modality_performance_context(
            athlete_history_same_type or []
        ),
        "sameWeekdayPerformance": {
            "sampleSize": len(weekday_efforts),
            "avgEffort": round(mean(weekday_efforts), 1) if weekday_efforts else None,
            "recentItems": (same_weekday_history or [])[:3],
        },
        "sameWeekdaySameTypePerformance": {
            "sampleSize": len(weekday_same_type_efforts),
            "avgEffort": round(mean(weekday_same_type_efforts), 1)
            if weekday_same_type_efforts else None,
            "recentItems": same_weekday_same_type[:3],
        },
        "completionRateSameType": _aggregate_completion_rate(same_type_history),
        "prsInTodayWorkout": prs_in_workout[:5],
        "currentLoadSummary": {
            "icnAll": (athlete_current_load or {}).get("icnAll"),
            "wodDays": (athlete_current_load or {}).get("wodDays"),
            "restDays": (athlete_current_load or {}).get("restDays"),
            "dailyLoadsCrossfit": (athlete_current_load or {}).get("dailyLoadsCrossfit"),
        },
    }
