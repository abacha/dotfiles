import os
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from myfitnesspal.adb_helpers import (
    clear_pending_add,
    describe_pending_add,
    detect_screen,
    extract_meal_names,
    extract_search_results,
    load_ui_xml,
    normalize_meal_name,
    save_pending_add,
)
from myfitnesspal.client import MyFitnessPalClient

FIXTURES_DIR = Path("/home/abacha/dotfiles/ai/tooling/myfitnesspal/tests/fixtures/real")


def load_fixture(name: str):
    return load_ui_xml(FIXTURES_DIR / name / "ui.xml")


def test_detect_real_screens():
    assert detect_screen(load_fixture("home")) == "search_results"
    assert detect_screen(load_fixture("diary")) == "search_results"
    assert detect_screen(load_fixture("search")) == "search"
    assert detect_screen(load_fixture("search_results")) == "search_results"


def test_real_fixture_still_supports_meal_name_normalization():
    meals = ["Jantar", "Exercício"]
    assert normalize_meal_name("jantar", meals) == "Jantar"
    assert extract_meal_names(load_fixture("diary")) == []


def test_extract_search_results_from_real_fixture():
    results = extract_search_results(load_fixture("search_results"), limit=5)

    assert len(results) == 5
    assert results[0] == {
        "name": "Banana",
        "details": "1,0 medium",
        "calories": "114 cal",
        "resource_id": "com.myfitnesspal.android:id/text_primary",
    }
    assert results[1]["name"] == "Banana - (One)"
    assert results[1]["calories"] == "105 cal"
    assert results[1]["details"] == "Banana - (One), 118,0 gram"


def test_pending_add_metadata_uses_real_fixture_results(tmp_path):
    results = extract_search_results(load_fixture("search_results"), limit=3)
    with patch("myfitnesspal.adb_helpers.PENDING_ADD_PATH", tmp_path / "pending.json"):
        save_pending_add(
            {"query": "banana", "meal": "Jantar", "weight": "120g", "results": results}
        )
        info = describe_pending_add()
        assert info["exists"] is True
        assert info["query"] == "banana"
        assert info["meal"] == "Jantar"
        assert info["result_count"] == 3
        assert clear_pending_add() is True
        assert clear_pending_add() is False


def test_confirm_add_without_pending_is_safe(capsys):
    client = MyFitnessPalClient()
    with (
        patch("myfitnesspal.client.load_pending_add", return_value=None),
        patch("myfitnesspal.client.clear_pending_add") as mock_clear,
    ):
        assert (
            client.confirm_add(pick=1, weight_str="120g", target_meal="Jantar") is False
        )
        mock_clear.assert_not_called()

    output = capsys.readouterr().out
    assert "screen: pending_state" in output
    assert "no pending search to confirm" in output


def test_confirm_add_without_results_is_safe(capsys):
    client = MyFitnessPalClient()
    pending = {"query": "banana", "meal": "Jantar", "weight": "120g", "results": []}
    with (
        patch("myfitnesspal.client.load_pending_add", return_value=pending),
        patch("myfitnesspal.client.clear_pending_add") as mock_clear,
    ):
        assert (
            client.confirm_add(pick=1, weight_str="120g", target_meal="Jantar") is False
        )
        mock_clear.assert_not_called()

    output = capsys.readouterr().out
    assert "pending results: 0" in output
    assert "no confirmable results" in output.lower()
