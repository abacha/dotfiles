
import argparse
import csv
import json
import os
import requests
import time
from datetime import datetime

# Simple .env loader
def load_env(path):
    if not os.path.exists(path):
        return
    with open(path, "r") as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                key, value = line.strip().split("=", 1)
                os.environ[key] = value

load_env(os.path.expanduser("~/.env"))

# Strava API settings
CLIENT_ID = os.getenv("STRAVA_CLIENT_ID")
CLIENT_SECRET = os.getenv("STRAVA_CLIENT_SECRET")
TOKEN_URL = "https://www.strava.com/oauth/token"
BASE_URL = "https://www.strava.com/"
AUTH_URL = BASE_URL + "oauth/authorize"
SCOPES = "activity:read_all,activity:write"
TOKEN_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "strava_tokens.json")
CSV_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "activities.csv")


def ensure_client_credentials():
    if CLIENT_ID and CLIENT_SECRET:
        return True
    print("Error: STRAVA_CLIENT_ID and STRAVA_CLIENT_SECRET are required.")
    print("Set them in ~/.env or export them before running this script.")
    return False


def get_tokens():
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "r") as f:
            tokens = json.load(f)
        if datetime.now().timestamp() < tokens.get("expires_at", 0):
            return tokens

    return refresh_tokens()


def refresh_tokens(refresh_token=None):
    if not ensure_client_credentials():
        return None

    if not refresh_token:
        if os.path.exists(TOKEN_FILE):
            with open(TOKEN_FILE, "r") as f:
                refresh_token = json.load(f).get("refresh_token")

    if not refresh_token:
        print("No refresh token found. Please run with --get-auth-url and then --code.")
        return None

    try:
        response = requests.post(
            TOKEN_URL,
            data={
                "client_id": CLIENT_ID,
                "client_secret": CLIENT_SECRET,
                "refresh_token": refresh_token,
                "grant_type": "refresh_token",
            },
        )
        response.raise_for_status()
        new_tokens = response.json()
        with open(TOKEN_FILE, "w") as f:
            json.dump(new_tokens, f)
        return new_tokens
    except requests.exceptions.RequestException as e:
        print(f"Error refreshing tokens: {e}")
        return None


def request_initial_authorization(code):
    if not ensure_client_credentials():
        return None

    try:
        response = requests.post(
            TOKEN_URL,
            data={
                "client_id": CLIENT_ID,
                "client_secret": CLIENT_SECRET,
                "code": code,
                "grant_type": "authorization_code",
            },
        )
        response.raise_for_status()
        tokens = response.json()
        with open(TOKEN_FILE, "w") as f:
            json.dump(tokens, f)
        print("Authorization successful. Tokens saved.")
        return tokens
    except requests.exceptions.RequestException as e:
        print(f"Error authorizing: {e}")
        return None


def make_request(url, headers, method="get", data=None):
    retries = 3
    delay = 5
    for i in range(retries):
        try:
            if method == "get":
                response = requests.get(url, headers=headers)
            elif method == "put":
                response = requests.put(url, headers=headers, json=data)
            response.raise_for_status()
            return response
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                print(f"Rate limit exceeded. Retrying in {delay} seconds...")
                time.sleep(delay)
                delay *= 2
            else:
                raise e
        except requests.exceptions.ConnectionError:
             print(f"Connection error. Retrying in {delay} seconds...")
             time.sleep(delay)
    raise Exception("Failed to fetch data from Strava API after multiple retries.")


def get_activities(access_token, after_timestamp):
    page = 1
    all_activities = []
    while True:
        url = f"https://www.strava.com/api/v3/athlete/activities?after={int(after_timestamp)}&per_page=200&page={page}"
        headers = {"Authorization": f"Bearer {access_token}"}
        try:
            response = make_request(url, headers)
            current_activities = response.json()
        except Exception as e:
            print(f"Error fetching activities page {page}: {e}")
            break

        if not current_activities:
            break
        all_activities.extend(current_activities)
        page += 1
    return all_activities


def get_laps(access_token, activity_id):
    url = f"https://www.strava.com/api/v3/activities/{activity_id}/laps"
    headers = {"Authorization": f"Bearer {access_token}"}
    try:
        response = make_request(url, headers)
        return response.json()
    except Exception:
        return []

def update_activity_name(access_token, activity_id, new_name):
    url = f"https://www.strava.com/api/v3/activities/{activity_id}"
    headers = {"Authorization": f"Bearer {access_token}"}
    data = {"name": new_name}
    try:
        make_request(url, headers, method="put", data=data)
        print(f"Updated activity {activity_id} to name '{new_name}'")
    except Exception as e:
        print(f"Failed to update activity {activity_id}: {e}")


def load_csv_activities():
    if not os.path.exists(CSV_FILE) or os.stat(CSV_FILE).st_size == 0:
        return []

    with open(CSV_FILE, "r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        return list(reader)

def save_csv_activities(activities):
    # Sort by date descending
    activities.sort(key=lambda x: x.get("Date", ""), reverse=True)

    fieldnames = [
        "ID", "Name", "Date", "Distance (km)", "Active Time", "Average Heartrate",
        "Idle Time", "Idle %", "Average Speed (km/h)", "Max Speed (km/h)",
        "Average Cadence", "Max Heartrate", "Laps"
    ]

    with open(CSV_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(activities)

def process_activity(activity, access_token):
    # Format a raw API activity object into our CSV row format
    row = {
        "ID": activity["id"],
        "Name": activity["name"],
        "Date": activity["start_date_local"].split("T")[0],
        "Distance (km)": f"{activity['distance'] / 1000:.2f}",
        "Active Time": f"{activity['moving_time'] // 3600:02}:{activity['moving_time'] // 60 % 60:02}:{activity['moving_time'] % 60:02}",
        "Average Heartrate": activity.get("average_heartrate", ""),
        "Max Heartrate": activity.get("max_heartrate", ""),
        "Average Cadence": activity.get("average_cadence", ""),
        "Average Speed (km/h)": f"{activity.get('average_speed', 0) * 3.6:.2f}",
        "Max Speed (km/h)": f"{activity.get('max_speed', 0) * 3.6:.2f}",
        "Idle Time": "",
        "Idle %": "",
        "Laps": ""
    }

    if activity["type"] == "Run":
        idle_time = activity["elapsed_time"] - activity["moving_time"]
        row["Idle Time"] = f"{idle_time // 3600:02}:{idle_time // 60 % 60:02}:{idle_time % 60:02}"
        row["Idle %"] = f"{(idle_time / activity['elapsed_time']) * 100:.2f}%" if activity["elapsed_time"] > 0 else "0.00%"

        laps_data = get_laps(access_token, activity["id"])
        laps_str_list = []
        for lap in laps_data:
            dist = lap["distance"] / 1000
            m_time = lap["moving_time"]
            m_time_str = f"{m_time // 3600:02}:{m_time // 60 % 60:02}:{m_time % 60:02}"

            pace_str = "N/A"
            if dist > 0:
                pace_min_km = (m_time / 60) / dist
                pace_str = f"{int(pace_min_km)}:{int((pace_min_km * 60) % 60):02}"

            avg_hr = lap.get("average_heartrate", "N/A")
            # Format: Lap 1: 1.00km, 00:06:23, 6:23/km, 138.8bpm
            laps_str_list.append(f"Lap {lap['lap_index']}: {dist:.2f}km, {m_time_str}, {pace_str}/km, {avg_hr}bpm")

        row["Laps"] = "\n".join(laps_str_list)

    return row

def print_activity_details(row):
    print(f"**Activity:** {row['Name']}")
    print(f"**Date:** {row['Date']}")
    print(f"**Distance:** {row['Distance (km)']} km")
    print(f"**Moving Time:** {row['Active Time']}")
    print(f"**Avg Heart Rate:** {row['Average Heartrate']} bpm")
    if row.get('Max Heartrate'):
        print(f"**Max Heart Rate:** {row['Max Heartrate']} bpm")

    try:
        speed_kmh = float(row['Average Speed (km/h)'])
        if speed_kmh > 0:
            pace_decimal = 60 / speed_kmh
            pace_min = int(pace_decimal)
            pace_sec = int((pace_decimal - pace_min) * 60)
            print(f"**Avg Pace:** {pace_min}:{pace_sec:02d} /km")
    except (ValueError, TypeError):
        pass

    if row.get('Laps'):
        print(f"\n**Laps / Splits:**")
        # Handle both newline and comma separated formats just in case
        laps_text = row['Laps'].replace(", Lap", "\nLap")
        for line in laps_text.split('\n'):
            clean_line = line.strip()
            if clean_line:
                 print(clean_line)

def sync_activities(force_all=False):
    tokens = get_tokens()
    if not tokens:
        return

    existing_rows = load_csv_activities()
    existing_ids = {str(r["ID"]) for r in existing_rows}

    last_date_ts = 0
    if not force_all and existing_rows:
        # Assuming sorted desc, first item is latest
        try:
            last_date_obj = datetime.strptime(existing_rows[0]["Date"], "%Y-%m-%d")
            last_date_ts = last_date_obj.timestamp()
        except ValueError:
            pass

    # If force_all or no existing data, fetch from beginning of year (or arbitrary past)
    if force_all or last_date_ts == 0:
        last_date_ts = datetime(datetime.now().year, 1, 1).timestamp()

    print(f"Fetching activities since {datetime.fromtimestamp(last_date_ts)}...")
    new_api_activities = get_activities(tokens["access_token"], last_date_ts)

    added_count = 0
    new_rows = []

    # Process new activities
    # Note: API returns oldest first usually if paginated by date? Or we need to check order.
    # Actually Strava API `after` returns chronologically (oldest after date to newest).
    # So we iterate and add.

    for act in new_api_activities:
        if str(act["id"]) not in existing_ids:
            try:
                processed_row = process_activity(act, tokens["access_token"])
                existing_rows.append(processed_row)
                existing_ids.add(str(act["id"]))
                added_count += 1
                print(f"Added: {processed_row['Name']} ({processed_row['Date']})")
            except Exception as e:
                print(f"Failed to process activity {act['id']}: {e}")

    if added_count > 0:
        save_csv_activities(existing_rows)
        print(f"Successfully synced {added_count} new activities.")
    else:
        print("No new activities found.")

def main():
    parser = argparse.ArgumentParser(description="Strava Activity Manager")
    parser.add_argument("--sync", action="store_true", help="Fetch new activities from Strava.")
    parser.add_argument("--force-sync", action="store_true", help="Force fetch from start of year.")
    parser.add_argument("--latest", action="store_true", help="Show details of the most recent activity.")
    parser.add_argument("--details", metavar="ID", help="Show details for a specific activity ID.")
    parser.add_argument("--update-name", action="store_true", help="Rename 'Evening Workout' to 'Judo'.")
    parser.add_argument("--get-auth-url", action="store_true", help="Print auth URL.")
    parser.add_argument("--code", help="Exchange auth code for tokens.")

    args = parser.parse_args()

    # Auth flows
    if args.get_auth_url:
        if not ensure_client_credentials():
            return
        print(f"Auth URL:\n{AUTH_URL}?client_id={CLIENT_ID}&response_type=code&redirect_uri=http://localhost&approval_prompt=force&scope={SCOPES}")
        return

    if args.code:
        request_initial_authorization(args.code)
        return

    # Operational flows
    if args.update_name:
        tokens = get_tokens()
        if tokens:
            print("Checking recent workouts...")
            since = datetime.now().timestamp() - (30 * 86400)
            acts = get_activities(tokens["access_token"], since)
            for act in acts:
                if act["name"] == "Evening Workout" and act["type"] == "Workout":
                    update_activity_name(tokens["access_token"], act["id"], "Judo")
        return

    if args.sync or args.force_sync:
        sync_activities(force_all=args.force_sync)

    if args.latest:
        rows = load_csv_activities()
        if rows:
            print_activity_details(rows[0])
        else:
            print("No activities found locally. Try --sync first.")

    if args.details:
        rows = load_csv_activities()
        found = False
        for row in rows:
            if row["ID"] == args.details:
                print_activity_details(row)
                found = True
                break
        if not found:
            print(f"Activity ID {args.details} not found locally.")

    # Default behavior if no args provided?
    if not any(vars(args).values()):
        parser.print_help()

if __name__ == "__main__":
    main()
