import json
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional

PENDING_ADD_PATH = Path(tempfile.gettempdir()) / "mfp_pending_add.json"


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def pending_add_exists() -> bool:
    return PENDING_ADD_PATH.exists()


def save_pending_add(payload: Dict[str, Any]) -> Path:
    data = dict(payload)
    data.setdefault("created_at", utc_now_iso())
    data["updated_at"] = utc_now_iso()
    PENDING_ADD_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    return PENDING_ADD_PATH


def load_pending_add() -> Optional[Dict[str, Any]]:
    if not PENDING_ADD_PATH.exists():
        return None
    return json.loads(PENDING_ADD_PATH.read_text(encoding="utf-8"))


def clear_pending_add() -> bool:
    try:
        PENDING_ADD_PATH.unlink()
        return True
    except FileNotFoundError:
        return False


def describe_pending_add() -> Dict[str, Any]:
    payload = load_pending_add()
    if not payload:
        return {"exists": False, "path": str(PENDING_ADD_PATH)}
    return {
        "exists": True,
        "path": str(PENDING_ADD_PATH),
        "query": payload.get("query"),
        "meal": payload.get("meal"),
        "weight": payload.get("weight"),
        "result_count": len(payload.get("results") or []),
        "created_at": payload.get("created_at"),
        "updated_at": payload.get("updated_at"),
    }
