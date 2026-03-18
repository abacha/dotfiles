import datetime
import os
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from myfitnesspal.adb_helpers import load_ui_xml
from myfitnesspal.parsers import extract_search_results
import xml.etree.ElementTree as ET
from myfitnesspal.client import MyFitnessPalClient
from myfitnesspal.app import MyFitnessPalApp

FIXTURES_DIR = Path("/home/abacha/dotfiles/ai/tooling/myfitnesspal/tests/fixtures/real")


def load_fixture(name: str):
    return load_ui_xml(FIXTURES_DIR / name / "ui.xml")


def load_local_fixture_root():
    fixture_path = Path(
        "/home/abacha/dotfiles/ai/tooling/myfitnesspal/tests/fixtures/ui_dump.xml"
    )
    return ET.parse(fixture_path).getroot()


def test_launch_prints_structured_summary(capsys):
    client = MyFitnessPalClient()
    root = load_fixture("search_results")
    with (
        patch.object(MyFitnessPalApp, "go_to_diary"),
        patch("myfitnesspal.client.adb.adb_dump", return_value=root),
    ):
        assert client.launch() is True

    output = capsys.readouterr().out
    assert "screen:" in output
    assert "relevant:" in output
    assert "warnings:" in output
    assert "next:" in output
    assert "results visible:" in output
    assert "search-food --query" in output


def test_view_diary_mentions_requested_date_and_warning(capsys):
    client = MyFitnessPalClient()
    root = load_fixture("search_results")
    with (
        patch.object(MyFitnessPalApp, "go_to_diary"),
        patch("myfitnesspal.client.adb.adb_dump", return_value=root),
    ):
        assert client.view_diary(datetime.date(2026, 3, 18)) is True

    output = capsys.readouterr().out
    assert "requested date: 2026-03-18" in output
    assert "requested date not guaranteed" in output
    assert "top result:" in output


def test_dump_ui_reports_path_screen_and_size(tmp_path, capsys):
    client = MyFitnessPalClient()
    root = load_fixture("search_results")
    out = tmp_path / "dump.xml"
    with patch.object(MyFitnessPalApp, "dump_ui_raw", return_value=(root, "<xml/>")):
        assert client.dump_ui(str(out)) is True

    output = capsys.readouterr().out
    assert f"output path: {out}" in output
    assert "screen: search_results" in output
    assert "xml chars:" in output


def test_search_food_prints_ranked_results_without_adding(capsys):
    client = MyFitnessPalClient()
    results = load_fixture("search_results")
    with (
        patch.object(MyFitnessPalApp, "go_to_diary"),
        patch.object(MyFitnessPalApp, "resolve_meal_name", return_value="Jantar"),
        patch.object(MyFitnessPalApp, "ensure_search_open", return_value=object()),
        patch.object(
            MyFitnessPalApp,
            "search_for",
            return_value=extract_search_results(results, limit=5),
        ),
        patch(
            "myfitnesspal.client.save_pending_add",
            return_value=Path("/tmp/mfp_pending_add.json"),
        ),
    ):
        results = client.search_food(
            "banana", target_meal="Jantar", weight_str="120g", limit=3
        )

    output = capsys.readouterr().out
    assert len(results) == 3
    assert "screen: search_results" in output
    assert "query: banana" in output
    assert "rank 1:" in output
    assert "suggested" in output
    assert "result: no food was added" in output


def test_confirm_add_success_reports_selected_item_and_completion(capsys):
    client = MyFitnessPalClient()
    pending = {
        "query": "banana",
        "meal": "Jantar",
        "weight": "120g",
        "results": [{"name": "Banana"}],
    }
    with (
        patch("myfitnesspal.client.load_pending_add", return_value=pending),
        patch("myfitnesspal.client.clear_pending_add") as mock_clear,
        patch.object(client, "_add_food_via_adb", return_value=True),
    ):
        assert client.confirm_add(pick=1, weight_str=None, target_meal=None) is True
        mock_clear.assert_called_once()

    output = capsys.readouterr().out
    assert "screen: confirm_add" in output
    assert "selected item: Banana" in output
    assert "weight: 120g" in output
    assert "controls found: enough to finish flow" in output
    assert "result: add flow completed" in output


def test_cancel_add_reports_if_pending_state_was_cleared(capsys):
    client = MyFitnessPalClient()
    info = {"exists": True, "path": "/tmp/mfp_pending_add.json"}
    with (
        patch("myfitnesspal.client.describe_pending_add", return_value=info),
        patch("myfitnesspal.client.clear_pending_add", return_value=True),
    ):
        assert client.cancel_add() is True

    output = capsys.readouterr().out
    assert "pending existed: yes" in output
    assert "result: pending state cleared" in output


def test_status_reports_useful_pending_summary(capsys):
    client = MyFitnessPalClient()
    info = {
        "exists": True,
        "path": "/tmp/mfp_pending_add.json",
        "query": "banana",
        "meal": "Jantar",
        "weight": "120g",
        "result_count": 3,
    }
    with patch("myfitnesspal.client.describe_pending_add", return_value=info):
        result = client.status()

    output = capsys.readouterr().out
    assert result == info
    assert "pending query: banana" in output
    assert "pending results: 3" in output
    assert "confirm-add --pick 1" in output


def test_meals_reports_detected_sections(capsys):
    client = MyFitnessPalClient()
    root = load_local_fixture_root()
    with (
        patch.object(MyFitnessPalApp, "go_to_diary"),
        patch("myfitnesspal.client.adb.adb_dump", return_value=root),
    ):
        meals = client.list_meals()

    output = capsys.readouterr().out
    assert meals[:3] == ["Café da manhã", "Lanche da manhã", "Almoço"]
    assert "meal sections:" in output
    assert "sections with visible content:" in output
