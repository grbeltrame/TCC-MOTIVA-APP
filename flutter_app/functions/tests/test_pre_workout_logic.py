import unittest
from unittest.mock import patch

from athlete_insights_module import pre_workout_logic
from athlete_insights_module.prompt_builder import create_pre_workout_insights_prompt


class _Snapshot:
    def __init__(self, id_, data=None, exists=True):
        self.id = id_
        self._data = data or {}
        self.exists = exists

    def to_dict(self):
        return dict(self._data)


class _Doc:
    def __init__(self, collection, doc_id):
        self._collection = collection
        self.id = doc_id

    def get(self):
        if self.id not in self._collection:
            return _Snapshot(self.id, exists=False)
        return _Snapshot(self.id, self._collection[self.id], exists=True)

    def set(self, data):
        self._collection[self.id] = dict(data)

    def update(self, data):
        self._collection.setdefault(self.id, {}).update(data)

    def collection(self, name):
        doc = self._collection.setdefault(self.id, {})
        subcollections = doc.setdefault("_subcollections", {})
        return _Collection(subcollections.setdefault(name, {}))


class _Collection:
    def __init__(self, store):
        self._store = store

    def document(self, doc_id):
        return _Doc(self._store, doc_id)

    def stream(self):
        for doc_id, data in self._store.items():
            yield _Snapshot(doc_id, data, exists=True)


class _Db:
    def __init__(self):
        self.users = {}
        self.exercises = {}

    def collection(self, name):
        if name == "users":
            return _Collection(self.users)
        if name == "exercises":
            return _Collection(self.exercises)
        raise AssertionError(f"unexpected collection {name}")


def _user(profile):
    return {"profile": profile, "_subcollections": {}}


def _pre_workout_items(db, uid):
    return (
        db.users[uid]
        .setdefault("_subcollections", {})
        .setdefault("insights", {})
        .setdefault("pre_workout", {"_subcollections": {}})
        .setdefault("_subcollections", {})
        .setdefault("items", {})
    )


class PreWorkoutLogicTest(unittest.TestCase):
    def test_prompt_teaches_gendered_load_interpretation_for_saved_workouts(self):
        prompt = create_pre_workout_insights_prompt(
            workout={
                "workoutId": "WOD (12-05-2026)",
                "partes": {
                    "WOD": {
                        "exercicios": [
                            {
                                "raw": "10 Deadlift (90Kg|50Kg)",
                                "nome": "Deadlift",
                                "cargaRx": "90Kg",
                                "cargaScaled": "50Kg",
                            },
                            {
                                "raw": "8 Clean (90Kg/50Kg)",
                                "nome": "Clean",
                                "cargaRx": "90Kg/50Kg",
                                "cargaScaled": None,
                            },
                        ]
                    }
                },
            },
            athlete_profile={"hasDetailedProfile": True, "gender": "Mulher"},
            athlete_history_same_type=[],
            athlete_current_load={},
            athlete_recent_prs=[],
        )

        self.assertIn("primeira carga masculina", prompt)
        self.assertIn("segunda carga feminina", prompt)
        self.assertIn("cargaRx=90Kg", prompt)
        self.assertIn("cargaScaled=50Kg", prompt)
        self.assertIn("90Kg/50Kg", prompt)
        self.assertIn("Nunca gere alerta para uma atleta mulher", prompt)

    def test_root_athlete_profile_is_eligible_without_detailed_profile(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")
        db.users["athlete_coach"] = _user("athleteCoach")
        db.users["athlete_intern"] = _user("athleteIntern")
        db.users["coach"] = _user("coach")
        db.users["missing_profile"] = {"_subcollections": {}}

        self.assertTrue(
            pre_workout_logic._is_athlete_user(
                _Snapshot("athlete", db.users["athlete"]), db
            )
        )
        self.assertTrue(
            pre_workout_logic._is_athlete_user(
                _Snapshot("athlete_coach", db.users["athlete_coach"]), db
            )
        )
        self.assertTrue(
            pre_workout_logic._is_athlete_user(
                _Snapshot("athlete_intern", db.users["athlete_intern"]), db
            )
        )
        self.assertFalse(
            pre_workout_logic._is_athlete_user(
                _Snapshot("coach", db.users["coach"]), db
            )
        )
        self.assertFalse(
            pre_workout_logic._is_athlete_user(
                _Snapshot("missing_profile", db.users["missing_profile"]), db
            )
        )

    def test_missing_detailed_profile_is_explicit_optional_context(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")

        self.assertEqual(
            pre_workout_logic._fetch_athlete_profile(db, "athlete"),
            {"hasDetailedProfile": False},
        )

    def test_existing_detailed_profile_is_returned_as_optional_context(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")
        db.users["athlete"]["_subcollections"]["profiles"] = {
            "athlete": {
                "category": "scaled",
                "gender": "female",
                "practiceYears": 2,
                "weight": 64,
                "height": 168,
                "ignored": "not exported",
            }
        }

        self.assertEqual(
            pre_workout_logic._fetch_athlete_profile(db, "athlete"),
            {
                "hasDetailedProfile": True,
                "category": "scaled",
                "gender": "female",
                "practiceYears": 2,
                "weight": 64,
                "height": 168,
            },
        )

    def test_athlete_without_minimum_data_is_skipped(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")

        with patch(
            "athlete_insights_module.pre_workout_logic.create_pre_workout_insights_prompt",
            side_effect=AssertionError("prompt should not be built"),
        ):
            result = pre_workout_logic._generate_insights_for_athlete(
                db,
                "athlete",
                {"workoutId": "WOD (12-05-2026)", "partes": {}},
                "hash",
                llm=object(),
            )

        self.assertEqual(result, {})

    def test_hash_unchanged_generates_only_missing_insights(self):
        db = _Db()
        db.users["missing"] = _user("athlete")
        db.users["existing"] = _user("athlete")
        db.users["coach"] = _user("coach")

        workout_id = "WOD (12-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": []}},
            "dataTreinoIso": "2026-05-12",
        }
        workout_hash = pre_workout_logic._compute_workout_hash(workout_data)
        workout_data["_preWorkoutInsightsHash"] = workout_hash
        db.exercises[workout_id] = {}

        _pre_workout_items(db, "existing")[workout_id] = {
            "workoutHash": workout_hash,
        }

        generated_for = []
        notified = []

        def fake_generate(_db, uid, _summary, _hash, _llm):
            generated_for.append(uid)
            return {
                "alertas": {},
                "informacoes": {"ok": {"detail": "Insight gerado."}},
            }

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "user_settings_module.athlete_ai_enabled",
            lambda _db, _uid: True,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            lambda: "key",
        ), patch(
            "athlete_insights_module.logic._build_llm",
            lambda _key: object(),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            fake_generate,
        ), patch(
            "notification_module.create_user_notification",
            lambda **kwargs: notified.append(kwargs["uid"]) or True,
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertEqual(generated_for, ["missing"])
        self.assertEqual(notified, ["missing"])
        self.assertIn(workout_id, _pre_workout_items(db, "missing"))
        self.assertEqual(result["athletesVisited"], 2)
        self.assertEqual(result["insightsExisting"], 1)
        self.assertEqual(result["insightsGenerated"], 1)
        self.assertEqual(result["insightsFailed"], 0)
        self.assertTrue(result["hashUnchanged"])

    def test_hash_unchanged_with_all_insights_does_not_call_llm(self):
        db = _Db()
        db.users["one"] = _user("athlete")
        db.users["two"] = _user("athlete")

        workout_id = "WOD (13-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": []}},
            "dataTreinoIso": "2026-05-13",
        }
        workout_hash = pre_workout_logic._compute_workout_hash(workout_data)
        workout_data["_preWorkoutInsightsHash"] = workout_hash
        db.exercises[workout_id] = {"keep": True}

        _pre_workout_items(db, "one")[workout_id] = {"workoutHash": workout_hash}
        _pre_workout_items(db, "two")[workout_id] = {"workoutHash": workout_hash}

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "user_settings_module.athlete_ai_enabled",
            lambda _db, _uid: True,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            side_effect=AssertionError("llm should not be built"),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            side_effect=AssertionError("insight should not be regenerated"),
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertEqual(result["athletesVisited"], 2)
        self.assertEqual(result["insightsExisting"], 2)
        self.assertEqual(result["insightsGenerated"], 0)
        self.assertEqual(result["insightsFailed"], 0)
        self.assertTrue(result["hashUnchanged"])
        self.assertNotIn("_preWorkoutInsightsGeneratedAt", db.exercises[workout_id])

    def test_hash_changed_regenerates_existing_and_missing_insights(self):
        db = _Db()
        db.users["existing"] = _user("athlete")
        db.users["missing"] = _user("athlete")

        workout_id = "WOD (14-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": [{"raw": "10 Burpees"}]}},
            "dataTreinoIso": "2026-05-14",
            "_preWorkoutInsightsHash": "old-hash",
        }
        db.exercises[workout_id] = {}
        _pre_workout_items(db, "existing")[workout_id] = {
            "workoutHash": "old-hash",
            "informacoes": {"old": True},
        }

        generated_for = []

        def fake_generate(_db, uid, _summary, new_hash, _llm):
            generated_for.append(uid)
            return {
                "workoutHash": new_hash,
                "informacoes": {"uid": uid},
                "alertas": {},
            }

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "user_settings_module.athlete_ai_enabled",
            lambda _db, _uid: True,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            lambda: "key",
        ), patch(
            "athlete_insights_module.logic._build_llm",
            lambda _key: object(),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            fake_generate,
        ), patch(
            "notification_module.create_user_notification",
            lambda **_kwargs: True,
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertEqual(generated_for, ["existing", "missing"])
        self.assertEqual(result["insightsExisting"], 0)
        self.assertEqual(result["insightsGenerated"], 2)
        self.assertEqual(result["insightsFailed"], 0)
        self.assertFalse(result["hashUnchanged"])
        self.assertEqual(
            _pre_workout_items(db, "existing")[workout_id]["informacoes"],
            {"uid": "existing"},
        )
        self.assertIn("_preWorkoutInsightsHash", db.exercises[workout_id])

    def test_hybrid_athlete_is_generated_and_ai_opt_out_is_skipped(self):
        db = _Db()
        db.users["hybrid"] = _user("athleteCoach")
        db.users["opt_out"] = _user("athlete")
        db.users["disabled"] = _user("athlete")
        db.users["disabled"]["accountStatus"] = "disabled"
        db.users["opt_out"]["_subcollections"]["settings"] = {
            "privacy": {"aiPersonalizationEnabled": False}
        }

        workout_id = "WOD (15-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": []}},
            "dataTreinoIso": "2026-05-15",
        }
        db.exercises[workout_id] = {}

        generated_for = []

        def fake_generate(_db, uid, _summary, _hash, _llm):
            generated_for.append(uid)
            return {
                "alertas": {},
                "informacoes": {"ok": {"detail": "Insight gerado."}},
            }

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            lambda: "key",
        ), patch(
            "athlete_insights_module.logic._build_llm",
            lambda _key: object(),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            fake_generate,
        ), patch(
            "notification_module.create_user_notification",
            lambda **_kwargs: True,
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertEqual(generated_for, ["hybrid"])
        self.assertIn(workout_id, _pre_workout_items(db, "hybrid"))
        self.assertEqual(result["athletesVisited"], 1)
        self.assertEqual(result["insightsGenerated"], 1)
        self.assertEqual(result["insightsFailed"], 0)

    def test_generation_failures_are_counted_in_summary(self):
        db = _Db()
        db.users["ok"] = _user("athlete")
        db.users["fail"] = _user("athlete")

        workout_id = "WOD (18-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": []}},
            "dataTreinoIso": "2026-05-18",
        }
        db.exercises[workout_id] = {}

        def fake_generate(_db, uid, _summary, _hash, _llm):
            if uid == "fail":
                return {}
            return {
                "alertas": {},
                "informacoes": {"ok": {"detail": "Insight gerado."}},
            }

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "user_settings_module.athlete_ai_enabled",
            lambda _db, _uid: True,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            lambda: "key",
        ), patch(
            "athlete_insights_module.logic._build_llm",
            lambda _key: object(),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            fake_generate,
        ), patch(
            "notification_module.create_user_notification",
            lambda **_kwargs: True,
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertEqual(result["athletesVisited"], 2)
        self.assertEqual(result["insightsExisting"], 0)
        self.assertEqual(result["insightsGenerated"], 1)
        self.assertEqual(result["insightsFailed"], 1)
        self.assertIn(workout_id, _pre_workout_items(db, "ok"))
        self.assertNotIn(workout_id, _pre_workout_items(db, "fail"))

    def test_unpublished_workout_is_skipped_before_building_llm(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            side_effect=AssertionError("llm should not be built"),
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                "WOD (16-05-2026)",
                {
                    "status": "rascunho",
                    "partes": {"WOD": {"exercicios": []}},
                    "dataTreinoIso": "2026-05-16",
                },
            )

        self.assertEqual(result, {"skipped": "not_published"})

    def test_pre_workout_notification_opt_out_does_not_block_generation(self):
        db = _Db()
        db.users["athlete"] = _user("athlete")
        db.users["athlete"]["_subcollections"]["settings"] = {
            "athlete": {"preWorkoutInsights": False}
        }

        workout_id = "WOD (17-05-2026)"
        workout_data = {
            "status": "publicado",
            "partes": {"WOD": {"exercicios": []}},
            "dataTreinoIso": "2026-05-17",
        }
        db.exercises[workout_id] = {}

        def fake_generate(_db, _uid, _summary, _hash, _llm):
            return {
                "alertas": {},
                "informacoes": {"ok": {"detail": "Insight gerado."}},
            }

        with patch(
            "athlete_insights_module.pre_workout_logic.firestore.client",
            lambda: db,
        ), patch(
            "athlete_insights_module.logic._get_gemini_api_key",
            lambda: "key",
        ), patch(
            "athlete_insights_module.logic._build_llm",
            lambda _key: object(),
        ), patch(
            "athlete_insights_module.pre_workout_logic._generate_insights_for_athlete",
            fake_generate,
        ):
            result = pre_workout_logic.run_pre_workout_insights_logic(
                workout_id, workout_data
            )

        self.assertIn(workout_id, _pre_workout_items(db, "athlete"))
        notifications = (
            db.users["athlete"]
            .setdefault("_subcollections", {})
            .setdefault("notifications", {})
        )
        self.assertEqual(notifications, {})
        self.assertEqual(result["insightsGenerated"], 1)
        self.assertEqual(result["insightsFailed"], 0)


if __name__ == "__main__":
    unittest.main()
