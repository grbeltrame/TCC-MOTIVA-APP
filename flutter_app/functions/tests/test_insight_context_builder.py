import unittest

from athlete_insights_module.context_builder import (
    build_evolution_context,
    build_pre_workout_context,
    build_weekly_context,
)


class InsightContextBuilderTest(unittest.TestCase):
    def test_weekly_context_classifies_single_training_day_as_single_peak(self):
        context = build_weekly_context(
            stats_summary={},
            weekly_load={
                "dailyLoadsCrossfit": {
                    "2026-05-10": 84,
                    "2026-05-11": 0,
                    "2026-05-12": 0,
                    "2026-05-13": 0,
                }
            },
            recent_results=[],
            performance_results=[],
        )

        self.assertEqual(context["currentMicrocycle"]["shape"], "single_peak")
        self.assertEqual(context["currentMicrocycle"]["trainingDays"], 1)

    def test_weekly_context_category_mix_splits_rx_scaled_intermediate_and_other(self):
        context = build_weekly_context(
            stats_summary={},
            weekly_load={},
            recent_results=[],
            performance_results=[
                {"category": "RX"},
                {"category": "rx"},
                {"category": "Scaled"},
                {"category": "scale"},
                {"category": "Intermediário"},
                {"category": "intermediario"},
                {"category": "intermediate"},
                {"category": "Masters"},
            ],
        )

        mix = context["categoryMix"]
        self.assertEqual(mix["counts"]["rx"], 2)
        self.assertEqual(mix["counts"]["intermediário"], 1)
        self.assertEqual(mix["counts"]["intermediario"], 1)
        self.assertEqual(mix["rxPercentage"], 25.0)
        self.assertEqual(mix["scaledPercentage"], 25.0)
        self.assertEqual(mix["intermediatePercentage"], 37.5)
        self.assertEqual(mix["otherPercentage"], 12.5)

    def test_weekly_context_detects_for_time_improvement_and_milestone(self):
        context = build_weekly_context(
            stats_summary={"totalTrainingDays": 95},
            weekly_load={"dailyLoadsCrossfit": {"2026-05-10": 100, "2026-05-11": 20}},
            recent_results=[],
            recent_weeks=[],
            performance_results=[
                {"date": "2026-04-01", "modalidade": "FOR TIME", "forTimeSec": 720, "completed": True},
                {"date": "2026-04-15", "modalidade": "FOR TIME", "forTimeSec": 680, "completed": True},
                {"date": "2026-05-01", "modalidade": "FOR TIME", "forTimeSec": 640, "completed": True},
            ],
        )

        self.assertEqual(context["milestone"]["target"], 100)
        self.assertEqual(context["milestone"]["remaining"], 5)
        trend = context["modalityPerformanceTrends"]["FOR TIME"]
        self.assertEqual(trend["direction"], "improving")
        self.assertEqual(trend["delta"], 80)

    def test_weekly_context_detects_amrap_improvement(self):
        context = build_weekly_context(
            stats_summary={},
            weekly_load={},
            recent_results=[],
            performance_results=[
                {"date": "2026-04-01", "modalidade": "AMRAP", "amrapRounds": 4, "amrapReps": 10},
                {"date": "2026-04-15", "modalidade": "AMRAP", "amrapRounds": 5, "amrapReps": 5},
                {"date": "2026-05-01", "modalidade": "AMRAP", "amrapRounds": 6, "amrapReps": 0},
            ],
        )

        trend = context["modalityPerformanceTrends"]["AMRAP"]
        self.assertEqual(trend["direction"], "improving")
        self.assertEqual(trend["kind"], "amrap")

    def test_evolution_context_detects_best_phase_and_peak_profile(self):
        weeks = [
            {"weekLabel": "2026-W01", "weekStart": "2026-01-04", "weekEnd": "2026-01-10", "prsCount": 0, "wodDays": 2, "icnAll": 80},
            {"weekLabel": "2026-W02", "weekStart": "2026-01-11", "weekEnd": "2026-01-17", "prsCount": 0, "wodDays": 2, "icnAll": 78},
            {"weekLabel": "2026-W03", "weekStart": "2026-01-18", "weekEnd": "2026-01-24", "prsCount": 0, "wodDays": 1, "icnAll": 76},
            {"weekLabel": "2026-W04", "weekStart": "2026-01-25", "weekEnd": "2026-01-31", "prsCount": 0, "wodDays": 2, "icnAll": 82},
            {"weekLabel": "2026-W05", "weekStart": "2026-02-01", "weekEnd": "2026-02-07", "prsCount": 1, "wodDays": 4, "icnAll": 55},
            {"weekLabel": "2026-W06", "weekStart": "2026-02-08", "weekEnd": "2026-02-14", "prsCount": 1, "wodDays": 4, "icnAll": 58},
            {"weekLabel": "2026-W07", "weekStart": "2026-02-15", "weekEnd": "2026-02-21", "prsCount": 1, "wodDays": 5, "icnAll": 60},
            {"weekLabel": "2026-W08", "weekStart": "2026-02-22", "weekEnd": "2026-02-28", "prsCount": 0, "wodDays": 4, "icnAll": 62},
        ]
        context = build_evolution_context(
            last_12_weeks=weeks,
            prs_summary={
                "count": 3,
                "byMovement": {"Clean": 2, "Snatch": 1},
                "items": [
                    {"date": "2026-02-02", "weekLabel": "2026-W05", "movementName": "Clean"},
                    {"date": "2026-02-09", "weekLabel": "2026-W06", "movementName": "Clean"},
                    {"date": "2026-02-16", "weekLabel": "2026-W07", "movementName": "Snatch"},
                ],
            },
            stimulus_distribution={"Forca": 8},
        )

        self.assertEqual(context["bestFourWeekPhase"]["blockIndex"], 2)
        self.assertEqual(context["peakPerformanceProfile"]["status"], "available")
        self.assertEqual(context["peakPerformanceProfile"]["dominantZone"], "medium")

    def test_pre_workout_context_keeps_same_weekday_history(self):
        context = build_pre_workout_context(
            workout={
                "modalidade": "FOR TIME",
                "wodType": "WOD",
                "partes": {"WOD": {"exercicios": [{"nome": "Clean"}, {"nome": "Burpee"}]}},
                "keyMetrics": ["Forca"],
            },
            athlete_history_same_type=[
                {"date": "2026-04-01", "modalidade": "FOR TIME", "wodType": "WOD", "forTimeSec": 500, "completed": True},
                {"date": "2026-04-08", "modalidade": "FOR TIME", "wodType": "WOD", "forTimeSec": 480, "completed": True},
                {"date": "2026-04-15", "modalidade": "FOR TIME", "wodType": "WOD", "forTimeSec": 460, "completed": False},
            ],
            athlete_current_load={},
            athlete_recent_prs=[{"movementName": "Clean", "value": 80}],
            same_weekday_history=[
                {"date": "2026-04-01", "modalidade": "FOR TIME", "wodType": "WOD", "effort": 8},
                {"date": "2026-04-08", "modalidade": "AMRAP", "wodType": "WOD", "effort": 6},
                {"date": "2026-04-15", "modalidade": "FOR TIME", "wodType": "WOD", "effort": 7},
            ],
        )

        self.assertEqual(context["sameWeekdayPerformance"]["sampleSize"], 3)
        self.assertEqual(context["sameWeekdayPerformance"]["avgEffort"], 7.0)
        self.assertEqual(context["sameWeekdaySameTypePerformance"]["sampleSize"], 3)
        self.assertEqual(context["sameWeekdaySameTypePerformance"]["avgEffort"], 7.0)
        self.assertEqual(context["completionRateSameType"]["total"], 3)
        self.assertEqual(context["completionRateSameType"]["completed"], 2)
        self.assertEqual(context["completionRateSameType"]["rate"], 0.67)
        self.assertEqual(context["prsInTodayWorkout"][0]["movementName"], "Clean")
        self.assertEqual(
            context["objectiveTrendSameType"]["FOR TIME"]["direction"],
            "improving",
        )

    def test_pre_workout_context_completion_rate_is_none_without_same_type(self):
        context = build_pre_workout_context(
            workout={"modalidade": "FOR TIME"},
            athlete_history_same_type=[
                {"date": "2026-04-01", "modalidade": "AMRAP", "completed": True},
            ],
            athlete_current_load={},
            athlete_recent_prs=[],
            same_weekday_history=[],
        )

        self.assertIsNone(context["completionRateSameType"])


if __name__ == "__main__":
    unittest.main()
