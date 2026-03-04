import datetime
import xml.etree.ElementTree as ET
from xml.dom import minidom
import argparse
import json
import sys

def parse_pace(p_str):
    if not p_str or ':' not in p_str: return 0.0
    try:
        m, s = map(int, p_str.split(':'))
        total_sec = m * 60 + s
        if total_sec == 0: return 0.0
        return 1000.0 / total_sec # m/s
    except:
        return 0.0

def create_tcx_workout(workout_name, steps):
    """
    Generates a Garmin TCX Workout XML file.
    """
    ns_tcx = "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"
    ns_xsi = "http://www.w3.org/2001/XMLSchema-instance"
    
    ET.register_namespace('', ns_tcx)
    
    root = ET.Element(f"{{{ns_tcx}}}TrainingCenterDatabase", {
        f"{{{ns_xsi}}}schemaLocation": "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd"
    })

    workouts = ET.SubElement(root, "Workouts")
    workout = ET.SubElement(workouts, "Workout", Sport="Running")
    
    ET.SubElement(workout, "Name").text = workout_name
    
    for i, step_data in enumerate(steps):
        step = ET.SubElement(workout, "Step", xsi_type="Step_t")
        ET.SubElement(step, "StepId").text = str(i + 1)
        ET.SubElement(step, "Name").text = step_data.get('name', step_data['type'])

        # Duration
        dtype = step_data['duration_type']
        duration_node = ET.SubElement(step, "Duration", xsi_type=f"{dtype}Mode_t")
        if dtype == 'Time':
            ET.SubElement(duration_node, "Seconds").text = str(int(step_data['duration_value']))
        elif dtype == 'Distance':
            ET.SubElement(duration_node, "Meters").text = str(int(step_data['duration_value']))
            
        # Intensity
        ET.SubElement(step, "Intensity").text = step_data.get('intensity', 'Active')

        # Target
        target_type = step_data.get('target_type', 'None')
        target_node = ET.SubElement(step, "Target", xsi_type=f"{target_type}Mode_t" if target_type != 'None' else "NoneMode_t")
        
        if target_type == 'Speed':
            zone = ET.SubElement(target_node, "SpeedZone", xsi_type="CustomSpeedZone_t")
            ET.SubElement(zone, "ViewAs").text = "Pace"
            ET.SubElement(zone, "LowInMetersPerSecond").text = str(step_data['target_min'])
            ET.SubElement(zone, "HighInMetersPerSecond").text = str(step_data['target_max'])
        elif target_type == 'HeartRate':
            zone = ET.SubElement(target_node, "HeartRateZone", xsi_type="CustomHeartRateZone_t")
            ET.SubElement(zone, "Low").text = str(int(step_data['target_min']))
            ET.SubElement(zone, "High").text = str(int(step_data['target_max']))

    # Pretty print
    xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="  ")
    
    filename = f"{workout_name.replace(' ', '_')}.tcx"
    with open(filename, "w") as f:
        f.write(xml_str)
    
    print(f"Workout saved to {filename}")
    return filename

def interactive_mode():
    print("Garmin TCX Workout Generator (Interactive Mode)")
    workout_name = input("Enter workout name: ").strip() or "My_Workout"
    steps = []
    
    # Warmup
    warmup_mins = input("Warmup duration (minutes, 0 to skip): ").strip()
    if warmup_mins and float(warmup_mins) > 0:
        steps.append({
            'type': 'Warmup', 'name': 'Warm Up', 'duration_type': 'Time',
            'duration_value': float(warmup_mins) * 60, 'intensity': 'Active', 'target_type': 'None'
        })

    # Main Set
    while True:
        print("\n--- Add Interval ---")
        print("1. Distance | 2. Time | 3. Rest | 4. Done")
        choice = input("Select: ").strip()
        if choice == '4': break
            
        step = {'intensity': 'Active'}
        if choice == '1':
            dist = float(input("Distance (m): "))
            step.update({'duration_type': 'Distance', 'duration_value': dist, 'name': f"Run {dist}m", 'type': 'Active'})
        elif choice == '2':
            mins = float(input("Duration (min): "))
            step.update({'duration_type': 'Time', 'duration_value': mins*60, 'name': f"Run {mins}m", 'type': 'Active'})
        elif choice == '3':
            mins = float(input("Rest (min): "))
            step.update({'duration_type': 'Time', 'duration_value': mins*60, 'intensity': 'Resting', 'name': "Recover", 'type': 'Rest'})
        else: continue
            
        if choice in ['1', '2']:
            tgt = input("Target (S=Speed, H=HR, N=None): ").strip().upper()
            if tgt == 'S':
                step['target_type'] = 'Speed'
                print("Pace (mm:ss/km)")
                max_p = input("Fastest pace: ")
                min_p = input("Slowest pace: ")
                step['target_max'] = parse_pace(max_p) # High m/s
                step['target_min'] = parse_pace(min_p) # Low m/s
            elif tgt == 'H':
                step['target_type'] = 'HeartRate'
                step['target_min'] = int(input("Min HR: "))
                step['target_max'] = int(input("Max HR: "))
            else: step['target_type'] = 'None'
        else: step['target_type'] = 'None'
        steps.append(step)

    # Cooldown
    cd_mins = input("\nCooldown (min, 0 skip): ").strip()
    if cd_mins and float(cd_mins) > 0:
        steps.append({
            'type': 'Cooldown', 'name': 'Cool Down', 'duration_type': 'Time',
            'duration_value': float(cd_mins) * 60, 'intensity': 'Active', 'target_type': 'None'
        })
        
    return workout_name, steps

def json_mode(json_file):
    with open(json_file, 'r') as f: data = json.load(f)
    workout_name = data.get('workout_name', 'My_Workout')
    steps = []
    
    if data.get('warmup_minutes', 0) > 0:
        steps.append({
            'type': 'Warmup', 'name': 'Warm Up', 'duration_type': 'Time',
            'duration_value': float(data['warmup_minutes']) * 60, 'intensity': 'Active', 'target_type': 'None'
        })
        
    for s in data.get('steps', []):
        step = s.copy()
        step['intensity'] = s.get('intensity', 'Active')
        d_type = s.get('duration_type', 'Time')
        # JSON expects seconds for Time unless we define otherwise. Let's assume input is seconds for precision if not specified.
        # Actually, let's keep it simple: if 'duration_value' is present, use it.
        # But wait, my interactive mode used minutes for Time. 
        # I'll stick to raw values from JSON.
        step['duration_value'] = float(s['duration_value'])
        
        if step.get('target_type') == 'Speed':
             if 'target_min_pace' in s:
                 step['target_min'] = parse_pace(s['target_max_pace']) # slower = low m/s
                 step['target_max'] = parse_pace(s['target_min_pace']) # faster = high m/s
        steps.append(step)

    if data.get('cooldown_minutes', 0) > 0:
        steps.append({
            'type': 'Cooldown', 'name': 'Cool Down', 'duration_type': 'Time',
            'duration_value': float(data['cooldown_minutes']) * 60, 'intensity': 'Active', 'target_type': 'None'
        })
    return workout_name, steps

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--json', help="JSON config file")
    args = parser.parse_args()
    
    if args.json:
        name, steps = json_mode(args.json)
    else:
        name, steps = interactive_mode()
        
    if steps: create_tcx_workout(name, steps)
    else: print("No steps.")

if __name__ == "__main__":
    main()
