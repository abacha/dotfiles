import os
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Optional, Tuple

MFP_PACKAGE = "com.myfitnesspal.android"
DEFAULT_DEVICE = os.environ.get("MFP_ADB_DEVICE", "192.168.15.58:5555")


def load_ui_xml(path: str | Path) -> ET.Element:
    return ET.parse(str(path)).getroot()


def adb_prefix() -> str:
    return f"adb -s {DEFAULT_DEVICE}"


def adb_exec(cmd: str) -> str:
    return subprocess.run(cmd, shell=True, capture_output=True, text=True).stdout


def adb_shell(command: str) -> str:
    return adb_exec(f"{adb_prefix()} shell {command}")


def adb_connect() -> str:
    return adb_exec(f"adb connect {DEFAULT_DEVICE}")


def parse_bounds(bounds: str) -> Tuple[int, int]:
    parts = bounds.replace("][", ",").replace("[", "").replace("]", "").split(",")
    return (int(parts[0]) + int(parts[2])) // 2, (int(parts[1]) + int(parts[3])) // 2


def adb_click(node: Optional[ET.Element]) -> bool:
    if node is None:
        return False
    bounds = node.attrib.get("bounds")
    if not bounds:
        return False
    x, y = parse_bounds(bounds)
    adb_shell(f"input tap {x} {y}")
    return True


def adb_tap(x: int, y: int) -> str:
    return adb_shell(f"input tap {x} {y}")


def adb_text(text: str) -> str:
    safe = text.replace(" ", "%s")
    return adb_shell(f'input text "{safe}"')


def adb_keyevent(keycode: int) -> str:
    return adb_shell(f"input keyevent {keycode}")


def adb_dump(local_path: str = "/tmp/mfp_dump.xml") -> Optional[ET.Element]:
    for _ in range(5):
        adb_shell("rm /sdcard/window_dump.xml")
        try:
            os.remove(local_path)
        except FileNotFoundError:
            pass
        result = adb_shell("uiautomator dump /sdcard/window_dump.xml")
        if (
            "UI hierchary dumped to" not in result
            and "UI hierarchy dumped to" not in result
        ):
            time.sleep(1)
            continue
        adb_exec(f"{adb_prefix()} pull /sdcard/window_dump.xml {local_path}")
        try:
            return ET.parse(local_path).getroot()
        except Exception:
            time.sleep(1)
    return None


def adb_dump_raw(
    local_path: str = "/tmp/mfp_dump.xml",
) -> Tuple[Optional[ET.Element], str]:
    root = adb_dump(local_path=local_path)
    if root is None:
        return None, ""
    return root, Path(local_path).read_text(encoding="utf-8")


def adb_find_node(
    root: Optional[ET.Element],
    text_contains: Optional[str] = None,
    text_exact: Optional[str] = None,
    resource_id: Optional[str] = None,
    class_name: Optional[str] = None,
    content_desc: Optional[str] = None,
    clickable: Optional[str] = None,
) -> Optional[ET.Element]:
    if root is None:
        return None
    for node in root.iter("node"):
        if text_exact and text_exact != node.attrib.get("text", ""):
            continue
        if text_contains and text_contains not in node.attrib.get("text", ""):
            continue
        if resource_id and resource_id != node.attrib.get("resource-id", ""):
            continue
        if class_name and class_name != node.attrib.get("class", ""):
            continue
        if content_desc and content_desc != node.attrib.get("content-desc", ""):
            continue
        if clickable and clickable != node.attrib.get("clickable", ""):
            continue
        if (
            text_exact
            or text_contains
            or resource_id
            or class_name
            or content_desc
            or clickable
        ):
            return node
    return None


def adb_find_nodes(
    root: Optional[ET.Element], resource_id: Optional[str] = None
) -> List[ET.Element]:
    if root is None:
        return []
    return [
        node
        for node in root.iter("node")
        if resource_id is None or node.attrib.get("resource-id", "") == resource_id
    ]


def wait_for_node(
    text_exact=None, text_contains=None, resource_id=None, class_name=None, timeout=10
):
    start = time.time()
    while time.time() - start < timeout:
        root = adb_dump()
        node = adb_find_node(
            root,
            text_exact=text_exact,
            text_contains=text_contains,
            resource_id=resource_id,
            class_name=class_name,
        )
        if node is not None:
            return node
        time.sleep(1)
    return None


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


def wake_unlock_device() -> None:
    adb_connect()
    adb_keyevent(224)
    time.sleep(1)
    if is_device_locked():
        adb_shell("input swipe 540 2000 540 500")
        time.sleep(1)
        adb_text("1262")
        time.sleep(1)
        adb_keyevent(66)
        time.sleep(2)


def launch_app(force_restart: bool = False) -> None:
    if force_restart:
        adb_exec(f"{adb_prefix()} shell am force-stop {MFP_PACKAGE}")
        time.sleep(1)
    adb_exec(
        f"{adb_prefix()} shell monkey -p {MFP_PACKAGE} -c android.intent.category.LAUNCHER 1"
    )
    time.sleep(8)


def wait_for_screen(resource_id: str, timeout: int = 4):
    return wait_for_node(resource_id=resource_id, timeout=timeout)
