import os
import sys
from unittest.mock import patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))

from myfitnesspal.adb_helpers import is_device_locked


@patch("myfitnesspal.adb_helpers.adb_exec")
def test_is_device_locked_asleep(mock_exec):
    mock_exec.side_effect = [
        "mCurrentFocus=Window{24d0304 u0 com.android.systemui}",
        "mWakefulness=Asleep\\n",
    ]
    assert is_device_locked() is True


@patch("myfitnesspal.adb_helpers.adb_exec")
def test_is_device_locked_keyguard(mock_exec):
    mock_exec.side_effect = [
        "mCurrentFocus=Window{55c110 u0 Keyguard}",
        "mWakefulness=Awake\\n",
    ]
    assert is_device_locked() is True


@patch("myfitnesspal.adb_helpers.adb_exec")
def test_is_device_unlocked_mfp(mock_exec):
    mock_exec.side_effect = [
        "mCurrentFocus=Window{24d0304 u0 com.myfitnesspal.android/com.myfitnesspal.feature.main.ui.MainActivity}",
        "mWakefulness=Awake\\n",
    ]
    assert is_device_locked() is False
