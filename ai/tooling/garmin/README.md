# Garmin Tooling

Consolidated set of tools and scripts to interact with Garmin Connect.

## Dependencies

The tool runs 100% in Ruby using the official \`ruby_garmin_connect\` gem:
```bash
gem install ruby_garmin_connect csv dotenv
```

Garmin credentials are required for all commands that interact with the API (export, weight, resync-weight, workout, etc.). Set them in your environment:
```bash
export GARMIN_EMAIL="your_email"
export GARMIN_PASSWORD="your_password"
```
*(Tip: You can easily pull these from 1Password or a `.env` file)*

## Usage: Garmin CLI

The main script is `garmin_cli.rb`. It aggregates all functionality into a single CLI tool:

### 1. Create and Schedule Workouts
Creates an interval workout and sends it directly via the Garmin API, automatically scheduling it in your Garmin calendar so it syncs to your watch:
```bash
./garmin_cli.rb workout --name "5x1k" \
  --warmup 10 \
  --count 5 \
  --distance 1.0 \
  --pace 4:30 \
  --recovery 2 \
  --cooldown 10 \
  --schedule 2026-04-05
```

### 2. Export Full History (CSVs)
Exports your entire activity history (`activities.csv`) and weight history (`weight.csv`) from Garmin Connect:
```bash
./garmin_cli.rb export --start 2023-01-01 --end 2025-01-01 --outdir ~/exports/
```

### 3. Weight History Summary
Quickly prints your monthly weight and muscle mass progression to the terminal:
```bash
./garmin_cli.rb weight --months 12
```

### 4. Resync Weight History
Forces the API to recalculate your body fat percentage across historical weigh-ins (useful if you updated your height profile):
```bash
./garmin_cli.rb resync-weight --start 2020-01-01 --dry-run
```
*(Remove `--dry-run` and add `--yes` to apply the modifications)*

## Directory Structure
- `garmin_cli.rb`: The unified CLI containing all the API communication logic.

### 5. Sleep History
Exports detailed daily sleep data (sleep score, phase durations, HRV, heart rate, etc.) to a CSV file.
```bash
./garmin_cli.rb sleep --start 2024-01-01 --end 2024-02-01 --outdir ~/exports/
```

### 6. Daily Summary
Exports a daily health summary: steps, active calories, Body Battery, average stress, heart rate (min/max/resting), floors climbed, and intensity minutes.
```bash
./garmin_cli.rb daily --start 2024-01-01 --end 2024-02-01 --outdir ~/exports/
```
