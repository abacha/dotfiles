#!/home/abacha/.asdf/installs/python/3.11.13/bin/python
import sys
import time
from pathlib import Path

sys.path.insert(0, "/home/abacha/dotfiles/ai/tooling")

from myfitnesspal.adb_helpers import (
    adb_dump_raw,
    adb_exec,
    adb_prefix,
    adb_shell,
    adb_tap,
    ensure_diary_screen,
)
from myfitnesspal.client import MyFitnessPalClient

BASE_DIR = Path("/home/abacha/dotfiles/ai/tooling/myfitnesspal/tests/fixtures/real")
REMOTE_SCREENSHOT = "/sdcard/__mfp_fixture.png"


def save_xml(name: str) -> None:
    target = BASE_DIR / name / "ui.xml"
    target.parent.mkdir(parents=True, exist_ok=True)
    adb_dump_raw(local_path=str(target))


def save_screenshot(name: str) -> None:
    target = BASE_DIR / name / "screen.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    adb_shell(f"screencap -p {REMOTE_SCREENSHOT}")
    adb_exec(f"{adb_prefix()} pull {REMOTE_SCREENSHOT} {target}")


def capture(name: str, wait_seconds: int = 2) -> None:
    time.sleep(wait_seconds)
    save_xml(name)
    save_screenshot(name)
    print(f"fixture captured: {name}")


def main() -> int:
    client = MyFitnessPalClient()
    ensure_diary_screen()
    capture("diary")

    adb_tap(136, 2275)
    capture("home", wait_seconds=4)

    ensure_diary_screen()
    client._open_food_search("Jantar")
    capture("search", wait_seconds=3)

    client.search_food("banana", target_meal="Jantar", weight_str="120g", limit=5)
    capture("search_results")

    client.cancel_add()
    print(f"fixtures saved under: {BASE_DIR}")
    print("safe flow: no confirm-add was executed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
