Garmin TCX Workout Generator
============================

This tool allows you to generate Garmin-compatible `.tcx` workout files using a Python script. You can run it interactively or with a JSON configuration file.

## Usage

### 1. Interactive Mode
Run the script without arguments:
```bash
python3 generate_tcx.py
```
Follow the prompts to define your workout.

### 2. JSON Mode (Recommended for Automation)
Create a JSON file (e.g., `my_workout.json`) and run:
```bash
python3 generate_tcx.py --json my_workout.json
```

## JSON Configuration Format

```json
{
  "workout_name": "My_Awesome_Workout",
  "warmup_minutes": 10,
  "steps": [
    {
      "type": "Active",
      "name": "Interval 1",
      "duration_type": "Distance", 
      "duration_value": 1000, 
      "target_type": "Speed",
      "target_min_pace": "3:50", 
      "target_max_pace": "4:30"
    },
    {
      "type": "Rest",
      "name": "Recovery",
      "duration_type": "Time",
      "duration_value": 90, 
      "intensity": "Resting"
    }
  ],
  "cooldown_minutes": 5
}
```
*Note: `duration_value` for Time is in seconds.*

## Importing into Garmin Connect

Garmin Connect's modern web interface sometimes rejects direct `.tcx` WORKOUT uploads (it prefers `.fit` for workouts), but you can try the following:

1.  **Direct Upload:** Go to [Garmin Connect Import](https://connect.garmin.com/modern/import-data) and upload the `.tcx` file.
2.  **Device Drop:** Connect your Garmin device to your computer via USB.
    *   Open the file explorer for the Garmin drive.
    *   Place the `.tcx` file into the `Garmin/NewFiles` folder.
    *   Safely eject the device.
    *   The device should process the file and add it to your "Workouts" list upon restart/sync.

*Note: The `NewFiles` method is the most reliable way to get custom workouts onto a device without using the web builder.*
