import unittest
from pathlib import Path

from pdf_module.parser import (
    parse_single_day_workout,
    split_pdf_into_day_pages,
)


ROOT = Path(__file__).resolve().parents[3]
PDF_PATH = ROOT / "Cronograma 04 - 01 WOD Abril 2026.pdf"


@unittest.skipUnless(PDF_PATH.exists(), "monthly workout PDF not available")
class PdfParserMonthlyImportTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        pdf_bytes = PDF_PATH.read_bytes()
        cls.pages = {
            page["pageNumber"]: parse_single_day_workout(
                page["text"],
                page["pageNumber"],
            )
            for page in split_pdf_into_day_pages(pdf_bytes)
        }

    def _raws(self, page, section):
        workout = self.pages[page]
        self.assertIsNotNone(workout)
        return [
            item["raw"]
            for item in workout["partes"][section]["exercicios"]
        ]

    def test_monthly_pdf_creates_only_wod_workouts(self):
        workouts = [w for w in self.pages.values() if w is not None]
        self.assertEqual(len(workouts), 20)
        self.assertIsNone(self.pages[7])
        self.assertIsNone(self.pages[8])

    def test_preserves_buy_in_rounds_and_buy_out(self):
        raws = self._raws(16, "WARM UP")
        self.assertIn("Buy in - 500m run", raws)
        self.assertIn("3 ROUNDS", raws)
        self.assertIn("Buy out - 500m run", raws)

    def test_parses_pipe_reps_inline(self):
        raws = self._raws(12, "WOD")
        self.assertIn("21|15|9 HSPU strict", raws)
        self.assertIn("21|15|9 Deadlift (100Kg|70Kg)", raws)

    def test_preserves_break_penalty_and_bulleted_penalty_movements(self):
        raws = self._raws(18, "WOD")
        self.assertIn("*Break penalty", raws)
        self.assertIn("- 05 Toes to bar", raws)
        self.assertIn("- 05 Deadlift", raws)

    def test_preserves_tabata_active_rest(self):
        raws = self._raws(17, "EXTRA TRAINING")
        self.assertEqual(raws, ["Active - Sit up", "Rest - Crunch"])

    def test_recognizes_team_warm_up(self):
        raws = self._raws(19, "WARM UP")
        self.assertIn("30 S.U. (friend plank hold)", raws)
        self.assertIn("100m run (together)", raws)


if __name__ == "__main__":
    unittest.main()
