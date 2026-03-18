import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Dict, Optional

from . import adb, parsers, state

MFP_PACKAGE = adb.MFP_PACKAGE
DEFAULT_DEVICE = adb.DEFAULT_DEVICE
PENDING_ADD_PATH = state.PENDING_ADD_PATH
MEAL_ALIASES = parsers.MEAL_ALIASES
SEARCH_RESULT_PRIMARY_IDS = parsers.SEARCH_RESULT_PRIMARY_IDS
SEARCH_RESULT_SECONDARY_IDS = parsers.SEARCH_RESULT_SECONDARY_IDS


load_ui_xml = adb.load_ui_xml
adb_prefix = adb.adb_prefix
adb_exec = adb.adb_exec
adb_connect = adb.adb_connect
parse_bounds = adb.parse_bounds
adb_tap = adb.adb_tap
adb_text = adb.adb_text
adb_keyevent = adb.adb_keyevent
adb_dump = adb.adb_dump
adb_dump_raw = adb.adb_dump_raw
adb_find_node = adb.adb_find_node
adb_find_nodes = adb.adb_find_nodes
wait_for_node = adb.wait_for_node
wake_unlock_device = adb.wake_unlock_device
launch_app = adb.launch_app

node_text = parsers.node_text
has_resource_id = parsers.has_resource_id
split_calories_from_details = parsers.split_calories_from_details
simplify_text = parsers.simplify_text
normalize_meal_name = parsers.normalize_meal_name
extract_meal_names = parsers.extract_meal_names
extract_search_results = parsers.extract_search_results
parse_weight_to_servings = parsers.parse_weight_to_servings
utc_now_iso = state.utc_now_iso
pending_add_exists = state.pending_add_exists


def adb_shell(command: str) -> str:
    return adb_exec(f"{adb_prefix()} shell {command}")


def adb_click(node: Optional[ET.Element]) -> bool:
    if node is None:
        return False
    bounds = node.attrib.get("bounds")
    if not bounds:
        return False
    x, y = parse_bounds(bounds)
    adb_shell(f"input tap {x} {y}")
    return True


def detect_screen(root: Optional[ET.Element]) -> str:
    return parsers.detect_screen(root)


def is_device_locked() -> bool:
    focus = adb_exec(f"{adb_prefix()} shell dumpsys window | grep mCurrentFocus")
    wakefulness = adb_exec(f"{adb_prefix()} shell dumpsys power | grep mWakefulness=")
    if "Asleep" in wakefulness:
        return True
    if (
        "com.android.systemui" in focus
        or "Keyguard" in focus
        or "NotificationShade" in focus
    ):
        return True
    return False


def ensure_diary_screen(force_restart: bool = False) -> None:
    wake_unlock_device()
    launch_app(force_restart=force_restart)
    diary = wait_for_node(text_exact="Diário", timeout=12) or wait_for_node(
        resource_id="buttonDiary", timeout=2
    )
    if diary is not None:
        adb_click(diary)
        wait_for_node(resource_id=f"{MFP_PACKAGE}:id/txtSectionHeader", timeout=4)
        return
    focus = adb_exec(f"{adb_prefix()} shell dumpsys window | grep mCurrentFocus")
    if MFP_PACKAGE in focus:
        adb_shell("input keyevent 4")
        adb_shell("input keyevent 4")
        diary_nav = wait_for_node(resource_id="buttonDiary", timeout=3)
        if diary_nav:
            adb_click(diary_nav)
        else:
            adb_tap(121, 2276)
        wait_for_node(resource_id=f"{MFP_PACKAGE}:id/txtSectionHeader", timeout=4)


def save_pending_add(payload: Dict[str, Any]) -> Path:
    original = state.PENDING_ADD_PATH
    state.PENDING_ADD_PATH = PENDING_ADD_PATH
    try:
        return state.save_pending_add(payload)
    finally:
        state.PENDING_ADD_PATH = original


def load_pending_add() -> Optional[Dict[str, Any]]:
    original = state.PENDING_ADD_PATH
    state.PENDING_ADD_PATH = PENDING_ADD_PATH
    try:
        return state.load_pending_add()
    finally:
        state.PENDING_ADD_PATH = original


def clear_pending_add() -> bool:
    original = state.PENDING_ADD_PATH
    state.PENDING_ADD_PATH = PENDING_ADD_PATH
    try:
        return state.clear_pending_add()
    finally:
        state.PENDING_ADD_PATH = original


def describe_pending_add() -> Dict[str, Any]:
    original = state.PENDING_ADD_PATH
    state.PENDING_ADD_PATH = PENDING_ADD_PATH
    try:
        return state.describe_pending_add()
    finally:
        state.PENDING_ADD_PATH = original
