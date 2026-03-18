import os
import sys
import xml.etree.ElementTree as ET
from unittest.mock import patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from myfitnesspal.adb_helpers import (
    adb_click,
    adb_find_node,
    clear_pending_add,
    describe_pending_add,
    extract_meal_names,
    normalize_meal_name,
    parse_weight_to_servings,
    save_pending_add,
)


def fixture_root():
    fixture_path = os.path.join(os.path.dirname(__file__), "fixtures/ui_dump.xml")
    return ET.parse(fixture_path).getroot()


def test_adb_find_node():
    root = fixture_root()

    node = adb_find_node(root, text_exact="Hoje")
    assert node is not None
    assert node.attrib["text"] == "Hoje"

    node = adb_find_node(root, text_contains="Suco de Uva e Maçã")
    assert node is not None
    assert node.attrib["text"] == "Suco de Uva e Maçã"

    node = adb_find_node(root, resource_id="com.myfitnesspal.android:id/add_food")
    assert node is not None
    assert node.attrib["class"] == "android.widget.Button"


@patch("myfitnesspal.adb_helpers.adb_shell")
def test_adb_click(mock_shell):
    root = fixture_root()
    node = adb_find_node(root, text_exact="Hoje")

    res = adb_click(node)
    assert res is True
    mock_shell.assert_called_with("input tap 540 318")


def test_extract_meal_names():
    meals = extract_meal_names(fixture_root())
    assert meals[:3] == ["Café da manhã", "Lanche da manhã", "Almoço"]


def test_normalize_meal_name_aliases():
    available = ["Café da manhã", "Almoço", "Jantar"]
    assert normalize_meal_name("almoco", available) == "Almoço"
    assert normalize_meal_name("cafe da manha", available) == "Café da manhã"


def test_parse_weight_to_servings():
    assert parse_weight_to_servings("120g", "60 g") == 2
    assert parse_weight_to_servings("100g", "") == 100


def test_pending_add_lifecycle(tmp_path):
    with patch("myfitnesspal.adb_helpers.PENDING_ADD_PATH", tmp_path / "pending.json"):
        info = describe_pending_add()
        assert info["exists"] is False

        path = save_pending_add(
            {
                "query": "banana",
                "meal": "Almoço",
                "weight": "120g",
                "results": [{"name": "Banana"}],
            }
        )
        assert path.exists()

        info = describe_pending_add()
        assert info["exists"] is True
        assert info["query"] == "banana"
        assert info["result_count"] == 1
        assert info["weight"] == "120g"

        assert clear_pending_add() is True
        assert clear_pending_add() is False
