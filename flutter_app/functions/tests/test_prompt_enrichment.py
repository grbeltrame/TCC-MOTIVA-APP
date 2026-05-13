import unittest

from athlete_insights_module.prompt_builder import (
    create_evolution_insights_prompt,
    create_pre_workout_insights_prompt,
    create_weekly_insights_prompt,
)


class PromptEnrichmentTest(unittest.TestCase):
    def test_weekly_prompt_includes_non_obviousness_and_new_contexts(self):
        prompt = create_weekly_insights_prompt(
            stats_summary={"totalTrainingDays": 95},
            weekly_load={
                "weekLabel": "2026-W19",
                "weekStart": "2026-05-10",
                "baselineType": "historical_4_weeks",
            },
            recent_results=[],
            recent_weeks=[],
            weekly_context={
                "milestone": {
                    "currentTotal": 95,
                    "target": 100,
                    "remaining": 5,
                },
                "microcycleShift": {
                    "habitualShape": "front_loaded",
                    "currentShape": "back_loaded",
                },
                "modalityPerformanceTrends": {
                    "FOR TIME": {"direction": "improving"},
                },
                "categoryMix": {
                    "totalWithCategory": 8,
                    "rxPercentage": 75.0,
                    "intermediatePercentage": 25.0,
                },
            },
        )

        self.assertIn("TESTE DE NÃO-OBVIEDADE", prompt)
        self.assertIn("CONTRASTE TEMPORAL", prompt)
        self.assertIn("curtas, mas nunca secas", prompt)
        self.assertIn("GLOSSÁRIO DO `weekly_context`", prompt)
        self.assertIn("Milestone detector", prompt)
        self.assertIn("Padrão de microciclo habitual", prompt)
        self.assertIn("modalityPerformanceTrends", prompt)
        self.assertIn("categoryMix × categoria praticada", prompt)
        self.assertIn("intermediatePercentage", prompt)
        self.assertIn("marco_frequencia", prompt)
        self.assertIn("tendencia_tempo", prompt)

    def test_evolution_prompt_includes_peak_profile_and_best_phase(self):
        prompt = create_evolution_insights_prompt(
            stats_summary={},
            last_12_weeks=[
                {"weekLabel": "2026-W01", "icnAll": 55, "wodDays": 4},
                {"weekLabel": "2026-W02", "icnAll": 58, "wodDays": 4},
            ],
            prs_summary={
                "count": 3,
                "byMovement": {"Clean": 2, "Snatch": 1},
                "items": [
                    {"date": "2026-01-07", "weekLabel": "2026-W01", "movementName": "Clean"},
                    {"date": "2026-01-14", "weekLabel": "2026-W02", "movementName": "Clean"},
                ],
            },
            stimulus_distribution={"Forca": 5},
            evolution_context={
                "peakPerformanceProfile": {
                    "status": "available",
                    "dominantZone": "medium",
                },
                "bestFourWeekPhase": {"blockIndex": 1},
                "allFourWeekPhases": [
                    {"blockIndex": 1, "score": 8},
                    {"blockIndex": 2, "score": 5},
                ],
                "prEfficiency": {"prsPerWodDay": 0.2},
            },
        )

        self.assertIn("TESTE DE NÃO-OBVIEDADE", prompt)
        self.assertIn("curtas, mas nunca secas", prompt)
        self.assertIn("GLOSSÁRIO DO `evolution_context`", prompt)
        self.assertIn("Zona ótima de fadiga DESTE atleta", prompt)
        self.assertIn("bestFourWeekPhase", prompt)
        self.assertIn("allFourWeekPhases", prompt)
        self.assertIn("prEfficiency.prsPerWodDay", prompt)
        self.assertIn("zona_otima_rendimento", prompt)
        self.assertIn("melhor_fase_identificada", prompt)

    def test_pre_workout_prompt_includes_anchor_rule_and_load_rule(self):
        prompt = create_pre_workout_insights_prompt(
            workout={
                "modalidade": "FOR TIME",
                "duracaoMinutos": 12,
                "partes": {
                    "WOD": {
                        "exercicios": [
                            {
                                "nome": "Deadlift",
                                "raw": "10 Deadlift (90Kg|50Kg)",
                                "cargaRx": "90Kg",
                                "cargaScaled": "50Kg",
                            }
                        ]
                    }
                },
            },
            athlete_profile={"hasDetailedProfile": True, "gender": "Mulher"},
            athlete_history_same_type=[],
            athlete_current_load={},
            athlete_recent_prs=[{"movementName": "Deadlift"}],
            pre_workout_context={
                "todayAnchors": {
                    "modalidade": "FOR TIME",
                    "duracaoMinutos": 12,
                    "movements": ["Deadlift"],
                },
                "prsInTodayWorkout": [{"movementName": "Deadlift"}],
                "sameWeekdaySameTypePerformance": {
                    "sampleSize": 3,
                    "avgEffort": 7.0,
                },
                "completionRateSameType": {
                    "total": 5,
                    "completed": 3,
                    "rate": 0.6,
                },
            },
        )

        self.assertIn("TESTE DE NÃO-OBVIEDADE", prompt)
        self.assertIn("curtas, mas nunca secas", prompt)
        self.assertIn("GLOSSÁRIO DO `pre_workout_context`", prompt)
        self.assertIn("Ancoragem no treino específico de hoje", prompt)
        self.assertIn("Pelo menos 2 dos 5 insights", prompt)
        self.assertIn("objectiveTrendSameType", prompt)
        self.assertIn("sameWeekdaySameTypePerformance", prompt)
        self.assertIn("completionRateSameType", prompt)
        self.assertIn("prsInTodayWorkout", prompt)
        self.assertIn("segunda carga feminina", prompt)
        self.assertIn("Nunca gere alerta para uma atleta mulher", prompt)


if __name__ == "__main__":
    unittest.main()
