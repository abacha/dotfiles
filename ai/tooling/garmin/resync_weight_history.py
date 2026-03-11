#!/usr/bin/env python3
"""Refresh Garmin Connect weight history after correcting your height.

The Garmin Connect body-composition graphs permanently tie each record to the height
that was configured at the time the entry was created. This script iterates over the
recorded weigh-ins, deletes each entry (to avoid duplicates) and re-adds it using
`garminconnect.add_weigh_in_with_timestamps`, which forces Garmin to recompute
percentages with your current profile height.

Usage example:

    GARMIN_EMAIL=... GARMIN_PASSWORD=... \
      python resync_weight_history.py --start 2020-01-01 --end 2025-03-10 --chunk-days 120 --yes

The script stores OAuth tokens in ~/.garminconnect by default so you can rerun it
without retyping credentials. Set --dry-run to preview what would happen.
"""

from __future__ import annotations

import argparse
import getpass
import logging
import os
import sys
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any

try:
    from garth.exc import GarthHTTPError
    from garminconnect import (
        Garmin,
        GarminConnectAuthenticationError,
        GarminConnectConnectionError,
        GarminConnectTooManyRequestsError,
    )
except ImportError as exc:
    raise SystemExit(
        "garminconnect is not installed. Run `pip install garminconnect` first."
    ) from exc

logger = logging.getLogger("garmin_weight_resync")

DEFAULT_START = date(2000, 1, 1)
DEFAULT_CHUNK_DAYS = 120
VALID_WEIGHT_UNITS = {"kg", "lb"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resave Garmin weigh-ins so their percentages reflect your current height."
    )
    parser.add_argument(
        "--start",
        default=DEFAULT_START.isoformat(),
        help="Start date for the range (YYYY-MM-DD). Default: %(default)s",
    )
    parser.add_argument(
        "--end",
        default=date.today().isoformat(),
        help="End date for the range (YYYY-MM-DD). Default: today",
    )
    parser.add_argument(
        "--chunk-days",
        type=int,
        default=DEFAULT_CHUNK_DAYS,
        help="How many days to request per API call. Garmin is happier with ~90–180d chunks. Default: %(default)s",
    )
    parser.add_argument(
        "--token-store",
        default="~/.garminconnect",
        help="Directory where OAuth tokens are stored/loaded",
    )
    parser.add_argument("--email", help="Garmin login email. Falls back to GARMIN_EMAIL env var.")
    parser.add_argument(
        "--password",
        help="Garmin login password. Falls back to GARMIN_PASSWORD or prompts via getpass.",
    )
    parser.add_argument(
        "--no-delete",
        dest="delete_first",
        action="store_false",
        help="Do not delete the existing weigh-in before re-adding it (default: delete).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would happen without modifying Garmin Connect.",
    )
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip the safety prompt and proceed (required unless --dry-run).",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Log debug information while processing the entries.",
    )
    parser.set_defaults(delete_first=True)
    return parser.parse_args()


def parse_date_or_exit(value: str) -> date:
    try:
        return datetime.fromisoformat(value).date()
    except ValueError as exc:
        raise SystemExit(f"Invalid date '{value}': {exc}") from exc


def chunk_ranges(start: date, end: date, chunk_days: int) -> list[tuple[date, date]]:
    if chunk_days < 1:
        raise SystemExit("--chunk-days must be >= 1")
    ranges = []
    current = start
    step = timedelta(days=chunk_days - 1)
    while current <= end:
        chunk_end = min(end, current + step)
        ranges.append((current, chunk_end))
        current = chunk_end + timedelta(days=1)
    return ranges


def get_weight_records(payload: dict[str, Any]) -> list[dict[str, Any]]:
    if not payload:
        return []
    for key in ("weighIns", "weightList", "dateWeightList", "weightMeasurements", "weights", "weight"):
        candidate = payload.get(key)
        if isinstance(candidate, list):
            return [item for item in candidate if isinstance(item, dict)]
    for value in payload.values():
        if isinstance(value, list) and value and isinstance(value[0], dict):
            if any(
                field in value[0]
                for field in ("weight", "value", "calendarDate", "timestamp", "samplePk")
            ):
                return value
    return []


def to_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return None
        if text.isdigit():
            value = int(text)
        else:
            try:
                if text.endswith("Z"):
                    text = text.replace("Z", "+00:00")
                return datetime.fromisoformat(text)
            except ValueError:
                pass
    if isinstance(value, (int, float)):
        try:
            return datetime.fromtimestamp(value / 1000, tz=timezone.utc)
        except (OverflowError, OSError, ValueError):
            return None
    return None


def normalize_weight(value: Any) -> float | None:
    if value is None:
        return None
    try:
        weight = float(value)
    except (TypeError, ValueError):
        return None
    if weight <= 0:
        return None
    if weight > 1000:
        weight = weight / 1000.0
    return weight


def extract_local_and_gmt(entry: dict[str, Any]) -> tuple[datetime | None, datetime | None]:
    timestamp_candidates = (
        entry.get("timestamp"),
        entry.get("timestampGMT"),
        entry.get("dateTimestamp"),
        entry.get("date"),
        entry.get("dateProcessed"),
    )
    tz_local = datetime.now().astimezone().tzinfo or timezone.utc
    dt_local = None
    dt_gmt = None
    for value in timestamp_candidates:
        dt = to_datetime(value)
        if dt:
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            dt_gmt = dt.astimezone(timezone.utc)
            dt_local = dt.astimezone(tz_local)
            return dt_local, dt_gmt
    calendar_date = entry.get("calendarDate")
    if calendar_date:
        try:
            dt = datetime.fromisoformat(calendar_date)
        except ValueError:
            dt = None
        if dt:
            dt_local = dt.replace(tzinfo=tz_local)
            dt_gmt = dt_local.astimezone(timezone.utc)
            return dt_local, dt_gmt
    return None, None


def entry_id(entry: dict[str, Any]) -> str | None:
    for field in ("samplePk", "id", "pk", "weightPk", "weightId", "uuid"):
        if entry.get(field):
            return str(entry[field])
    timestamp = entry.get("timestamp") or entry.get("timestampGMT") or entry.get("date")
    weight = entry.get("weight") or entry.get("value")
    calendar_date = entry.get("calendarDate")
    if timestamp and calendar_date and weight is not None:
        return f"{calendar_date}-{timestamp}-{weight}"
    return None


def get_calendar_date(entry: dict[str, Any], local_dt: datetime | None) -> str | None:
    if entry.get("calendarDate"):
        return entry["calendarDate"]
    if local_dt:
        return local_dt.date().isoformat()
    return None


def login_with_tokens(token_store: Path) -> Garmin | None:
    try:
        api = Garmin(return_on_mfa=True)
        api.login(str(token_store))
        logger.info("Reused tokens from %s", token_store)
        return api
    except (FileNotFoundError, GarminConnectAuthenticationError, GarminConnectConnectionError, GarminConnectTooManyRequestsError, GarthHTTPError) as exc:
        logger.debug("Token reuse failed: %s", exc)
        return None


def login_with_credentials(args: argparse.Namespace, token_store: Path) -> Garmin:
    email = args.email or os.getenv("GARMIN_EMAIL")
    password = args.password or os.getenv("GARMIN_PASSWORD")
    if not email:
        email = input("Garmin email: ").strip()
    if not password:
        password = getpass.getpass("Garmin password: ")
    api = Garmin(email=email, password=password, return_on_mfa=True)
    status, challenge = api.login()
    if status == "needs_mfa":
        code = input("Garmin MFA code: ").strip()
        api.resume_login(challenge, code)
    api.garth.dump(str(token_store))
    logger.info("Saved tokens to %s", token_store)
    return api


def build_client(args: argparse.Namespace) -> Garmin:
    token_store = Path(args.token_store).expanduser()
    token_store.mkdir(parents=True, exist_ok=True)
    client = login_with_tokens(token_store)
    if client:
        return client
    return login_with_credentials(args, token_store)


def main() -> None:
    args = parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(levelname)s: %(message)s",
    )

    if not args.dry_run and not args.yes:
        logger.warning("Dry-run disabled — pass --yes to proceed with live updates.")
        sys.exit(0)

    start_date = parse_date_or_exit(args.start)
    end_date = parse_date_or_exit(args.end)
    if start_date > end_date:
        raise SystemExit("--start must be before or equal to --end")

    ranges = chunk_ranges(start_date, end_date, args.chunk_days)
    client = build_client(args)

    processed_ids: set[str] = set()
    stats = {
        "total": 0,
        "skipped": 0,
        "deleted": 0,
        "added": 0,
        "errors": 0,
    }

    for chunk_start, chunk_end in ranges:
        logger.info("Fetching weigh-ins %s → %s", chunk_start, chunk_end)
        try:
            payload = client.get_weigh_ins(chunk_start.isoformat(), chunk_end.isoformat())
        except Exception as exc:
            logger.error("Failed to fetch weigh-ins for %s → %s: %s", chunk_start, chunk_end, exc)
            stats["errors"] += 1
            break
        records = get_weight_records(payload)
        logger.info("Found %d entries in this slice", len(records))
        for entry in records:
            stats["total"] += 1
            rec_id = entry_id(entry)
            if rec_id and rec_id in processed_ids:
                logger.debug("Skipping already processed entry %s", rec_id)
                continue
            if rec_id:
                processed_ids.add(rec_id)
            weight = normalize_weight(entry.get("weight") or entry.get("value"))
            if weight is None:
                logger.warning("Skipping entry without usable weight: %s", entry)
                stats["skipped"] += 1
                continue
            local_dt, gmt_dt = extract_local_and_gmt(entry)
            if local_dt is None or gmt_dt is None:
                logger.warning("Skipping entry without timestamps: %s", entry)
                stats["skipped"] += 1
                continue
            unit = (entry.get("unitKey") or entry.get("unit") or "kg").lower()
            if unit not in VALID_WEIGHT_UNITS:
                unit = "kg"
            date_for_delete = get_calendar_date(entry, local_dt)

            try:
                if args.delete_first and rec_id and date_for_delete and not args.dry_run:
                    client.delete_weigh_in(rec_id, date_for_delete)
                    stats["deleted"] += 1
                    logger.debug("Deleted old weigh-in %s (%s)", rec_id, date_for_delete)
                elif args.delete_first and rec_id and date_for_delete:
                    stats["deleted"] += 1
                if not args.dry_run:
                    client.add_weigh_in_with_timestamps(
                        weight=weight,
                        unitKey=unit,
                        dateTimestamp=local_dt.isoformat(),
                        gmtTimestamp=gmt_dt.isoformat(),
                    )
                stats["added"] += 1
                logger.info(
                    "Re-added weigh-in %s on %s %s %s",
                    rec_id or "(no id)",
                    local_dt.date(),
                    weight,
                    unit,
                )
            except Exception as exc:
                logger.error("Failed to resync entry %s: %s", rec_id or "(no id)", exc)
                stats["errors"] += 1

    logger.info("Done. Summary: %s", stats)


if __name__ == "__main__":
    main()
