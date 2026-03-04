# Strava Activity Manager

A unified script to sync, manage, and view Strava activities locally.

## Files
- `run.py` — Main CLI tool.
- `activities.csv` — Local database of activities (auto-generated).
- `strava_tokens.json` — OAuth tokens (auto-managed).

## Usage

Run from the workspace root:

### Sync Activities
Fetch new activities since the last sync:
```bash
python3 scripts/strava/run.py --sync
```

Force fetch from the beginning of the year:
```bash
python3 scripts/strava/run.py --force-sync
```

### View Activities
Show details of the most recent activity:
```bash
python3 scripts/strava/run.py --latest
```

Show details of a specific activity by ID:
```bash
python3 scripts/strava/run.py --details 123456789
```

### Maintenance
Rename "Evening Workout" activities to "Judo" (last 30 days):
```bash
python3 scripts/strava/run.py --update-name
```

### Authentication
If tokens expire or are missing:
1. Get the auth URL:
   ```bash
   python3 scripts/strava/run.py --get-auth-url
   ```
2. Authorize in browser and copy the `code` parameter.
3. Exchange code for tokens:
   ```bash
   python3 scripts/strava/run.py --code <your_code_here>
   ```

## Dependencies
- Python 3.10+
- `requests`

Install: `pip install requests`
