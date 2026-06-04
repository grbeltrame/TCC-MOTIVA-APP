import json
import unittest
from datetime import datetime
from unittest.mock import patch

from athlete_insights_module.llm_parser import extract_json_object, parse_llm_response
from athlete_insights_module.logic import _stream_date_docs_since
from athlete_insights_module.models import (
    PreWorkoutInsights,
    WeeklyInsights,
)


class _PreWorkoutParser:
    def parse(self, text):
        return PreWorkoutInsights.model_validate_json(text)


class _Snapshot:
    def __init__(self, id_, data=None):
        self.id = id_
        self._data = data or {}

    def to_dict(self):
        return dict(self._data)


class _Query:
    def __init__(self, docs):
        self._docs = docs

    def stream(self):
        return iter(self._docs)


class _DateCollection:
    def __init__(self):
        self.bounds = []
        self._docs_by_type = {
            datetime: [_Snapshot("timestamp-pr", {"date": datetime(2026, 5, 1)})],
            str: [
                _Snapshot("legacy-pr", {"date": "2026-05-02"}),
                _Snapshot("timestamp-pr", {"date": "2026-05-01"}),
            ],
        }

    def where(self, field, op, bound):
        self.bounds.append((field, op, bound))
        return _Query(self._docs_by_type.get(type(bound), []))


class _FakeDoc:
    def __init__(self):
        self.last_set = None

    def set(self, updates, merge=False):
        self.last_set = (updates, merge)


class _FakeDb:
    def __init__(self):
        self.doc = _FakeDoc()

    def collection(self, _name):
        return self

    def document(self, _doc_id):
        return self.doc


class AthleteInsightOutputContractTest(unittest.TestCase):
    def test_pre_workout_output_is_capped_and_long_text_is_clipped(self):
        long_text = (
            "Este insight veio maior do que o carrossel suporta e precisa ser "
            "normalizado no backend antes de chegar no aplicativo. "
        ) * 6

        payload = {
            "alertas": {
                "Alerta Muito Estranho!!!": {"message": long_text},
                "alerta_2": {"message": "Comece controlando o ritmo."},
                "alerta_3": {"message": "Respire melhor nas transições."},
                "alerta_4": {"message": "Este excedente deve cair."},
            },
            "informacoes": {
                "info_1": {"detail": long_text},
                "info_2": {"detail": "Seu histórico ajuda hoje."},
                "info_3": {"detail": "Este excedente deve cair."},
            },
        }

        parsed = PreWorkoutInsights(**payload)
        total = len(parsed.alertas) + len(parsed.informacoes)

        self.assertEqual(total, 5)
        self.assertLessEqual(len(parsed.alertas), 3)
        self.assertIn("alerta_muito_estranho", parsed.alertas)
        for item in parsed.alertas.values():
            self.assertLessEqual(len(item.message), 240)
        for item in parsed.informacoes.values():
            self.assertLessEqual(len(item.detail), 240)

    def test_empty_output_is_rejected(self):
        with self.assertRaises(ValueError):
            WeeklyInsights(alertas={}, informacoes={})

    def test_parser_extracts_json_from_markdown_and_surrounding_text(self):
        raw = """
        Claro, segue:
        ```json
        {"alertas": {}, "informacoes": {"ok": {"detail": "Pronto."}}}
        ```
        """

        self.assertEqual(
            json.loads(extract_json_object(raw)),
            {"alertas": {}, "informacoes": {"ok": {"detail": "Pronto."}}},
        )

    def test_parser_validates_with_pydantic_contract(self):
        raw = (
            "texto antes "
            '{"alertas": {}, "informacoes": {"ok": {"detail": "Tudo certo."}}}'
            " texto depois"
        )

        parsed = parse_llm_response(
            raw,
            _PreWorkoutParser(),
            flow="test-pre-workout",
            uid="athlete",
        )

        self.assertEqual(parsed["informacoes"]["ok"]["detail"], "Tudo certo.")

    def test_date_query_supports_timestamp_and_legacy_string_dates(self):
        collection = _DateCollection()
        docs = _stream_date_docs_since(collection, datetime(2026, 5, 1))

        self.assertEqual({doc.id for doc in docs}, {"timestamp-pr", "legacy-pr"})
        self.assertIsInstance(collection.bounds[0][2], datetime)
        self.assertIsInstance(collection.bounds[1][2], str)

    def test_telemetry_records_status_and_reason(self):
        db = _FakeDb()

        with patch("firebase_admin.firestore.client", lambda: db), patch(
            "firebase_admin.firestore.Increment", lambda value: ("inc", value)
        ), patch(
            "firebase_admin.firestore.SERVER_TIMESTAMP", "SERVER_TS"
        ):
            from telemetry_module import record_insight_event

            record_insight_event(
                "weekly",
                status="skipped",
                reason="no_weekly_load",
            )

        updates, merge = db.doc.last_set
        self.assertTrue(merge)
        self.assertEqual(updates["insights.weekly.skipped"], ("inc", 1))
        self.assertEqual(
            updates["insights.weekly.reasons.no_weekly_load"],
            ("inc", 1),
        )


if __name__ == "__main__":
    unittest.main()
