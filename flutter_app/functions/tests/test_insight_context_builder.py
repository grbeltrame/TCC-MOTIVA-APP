import unittest

from athlete_insights_module.context_builder import (
    build_evolution_context,
    build_pre_workout_context,
    build_weekly_context,
)


class InsightContextBuilderTest(unittest.TestCase):
    def test_weekly_context_single_training_day_raw_loads(self):
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

        daily = context["currentWeekDailyLoads"]
        self.assertEqual(daily["trainingDays"], 1)
        self.assertEqual(daily["firstHalfLoad"], 84.0)
        self.assertEqual(daily["secondHalfLoad"], 0.0)
        self.assertEqual(daily["heaviestDay"], "2026-05-10")
        self.assertEqual(len(daily["loadsOrdered"]), 4)
        self.assertNotIn("currentMicrocycle", context)
        self.assertNotIn("microcycleShift", context)
        self.assertNotIn("habitualMicrocycleShape", context)

    def test_weekly_context_recent_weeks_are_chronological_when_input_is_desc(self):
        context = build_weekly_context(
            stats_summary={},
            weekly_load={},
            recent_results=[],
            recent_weeks=[
                {
                    "weekLabel": "2026-W18",
                    "dailyLoadsCrossfit": {"2026-05-03": 18},
                },
                {
                    "weekLabel": "2026-W17",
                    "dailyLoadsCrossfit": {"2026-04-26": 17},
                },
                {
                    "weekLabel": "2026-W16",
                    "dailyLoadsCrossfit": {"2026-04-19": 16},
                },
                {
                    "weekLabel": "2026-W15",
                    "dailyLoadsCrossfit": {"2026-04-12": 15},
                },
                {
                    "weekLabel": "2026-W14",
                    "dailyLoadsCrossfit": {"2026-04-05": 14},
                },
            ],
            performance_results=[],
        )

        self.assertEqual(
            [week["weekLabel"] for week in context["recentWeeksDailyLoads"]],
            ["2026-W15", "2026-W16", "2026-W17", "2026-W18"],
        )

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

        self.assertNotIn("bestFourWeekPhase", context)
        phases = context["allFourWeekPhases"]
        # Bloco 2 (semanas 5-8): ICN 55,58,60,62 — todas em zona saudável
        block2 = phases[1]
        self.assertEqual(block2["blockIndex"], 2)
        self.assertEqual(block2["weeksInHealthyIcnZone"], 4)
        self.assertEqual(block2["weeksInHighIcnZone"], 0)
        self.assertEqual(block2["prsCount"], 3)
        self.assertNotIn("score", block2)
        self.assertEqual(context["peakPerformanceProfile"]["status"], "available")
        self.assertEqual(context["peakPerformanceProfile"]["dominantZone"], "medium")

    def test_pre_workout_context_time_of_day_performance(self):
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
            time_of_day_history=[
                {"date": "2026-04-01", "effort": 8, "trainingTime": "19:00", "completed": True},
                {"date": "2026-04-08", "effort": 7, "trainingTime": "19:30", "completed": True},
                {"date": "2026-04-15", "effort": 9, "trainingTime": "20:00", "completed": False},
                {"date": "2026-04-22", "effort": 8, "trainingTime": "19:00", "completed": True},
                {"date": "2026-03-01", "effort": 6, "trainingTime": "09:00", "completed": True},
                {"date": "2026-03-08", "effort": 5, "trainingTime": "08:30", "completed": True},
            ],
        )

        tod = context["timeOfDayPerformance"]
        self.assertIsNotNone(tod)
        self.assertEqual(tod["dominantPeriod"], "noite")
        self.assertNotIn("hasContrast", tod)
        self.assertNotIn("bestPerformancePeriod", tod)
        self.assertIn("noite", tod["periodBreakdown"])
        self.assertIn("manha", tod["periodBreakdown"])
        self.assertEqual(tod["periodBreakdown"]["noite"]["sampleSize"], 4)
        self.assertEqual(tod["periodBreakdown"]["noite"]["avgEffort"], 8.0)
        self.assertEqual(tod["periodBreakdown"]["manha"]["sampleSize"], 2)
        self.assertIsNone(tod["todayPeriod"])
        self.assertNotIn("sameWeekdayPerformance", context)
        self.assertNotIn("sameWeekdaySameTypePerformance", context)
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
        )

        self.assertIsNone(context["completionRateSameType"])


if __name__ == "__main__":
    unittest.main()
