import os
import sys
from unittest.mock import MagicMock, patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from myfitnesspal.cli import main


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "launch"])
@patch("myfitnesspal.cli.get_client")
def test_cli_launch(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.launch.assert_called_once_with()


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "view-diary", "--date", "2023-10-10"])
@patch("myfitnesspal.cli.get_client")
def test_cli_view_diary(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.view_diary.assert_called_once()
    args, _ = mock_client.view_diary.call_args
    assert args[0].strftime("%Y-%m-%d") == "2023-10-10"


@patch(
    "myfitnesspal.cli.sys.argv",
    [
        "cli.py",
        "search-food",
        "--query",
        "Banana",
        "--meal",
        "Café da manhã",
        "--weight",
        "120g",
        "--limit",
        "3",
        "--tab",
        "meals",
    ],
)
@patch("myfitnesspal.cli.get_client")
def test_cli_search_food(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.search_food.assert_called_once_with(
        "Banana", target_meal="Café da manhã", weight_str="120g", limit=3, tab="meals"
    )


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "confirm-add", "--pick", "2"])
@patch("myfitnesspal.cli.get_client")
def test_cli_confirm_add_quick(mock_get_client):
    mock_client = MagicMock()
    mock_client.confirm_add.return_value = True
    mock_get_client.return_value = mock_client

    main()

    mock_client.confirm_add.assert_called_once_with(
        pick=2, weight_str=None, target_meal=None
    )


@patch(
    "myfitnesspal.cli.sys.argv",
    ["cli.py", "confirm-add", "--pick", "2", "--weight", "150g", "--meal", "Jantar"],
)
@patch("myfitnesspal.cli.get_client")
def test_cli_confirm_add(mock_get_client):
    mock_client = MagicMock()
    mock_client.confirm_add.return_value = True
    mock_get_client.return_value = mock_client

    main()

    mock_client.confirm_add.assert_called_once_with(
        pick=2, weight_str="150g", target_meal="Jantar"
    )


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "cancel-add"])
@patch("myfitnesspal.cli.get_client")
def test_cli_cancel_add(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.cancel_add.assert_called_once_with()


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "status"])
@patch("myfitnesspal.cli.get_client")
def test_cli_status(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.status.assert_called_once_with()


@patch("myfitnesspal.cli.sys.argv", ["cli.py", "meals", "--date", "2023-10-10"])
@patch("myfitnesspal.cli.get_client")
def test_cli_meals(mock_get_client):
    mock_client = MagicMock()
    mock_get_client.return_value = mock_client

    main()

    mock_client.view_diary.assert_called_once()
    mock_client.list_meals.assert_called_once_with()
