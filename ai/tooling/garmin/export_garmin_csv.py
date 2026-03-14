#!/usr/bin/env python3
import os
import sys
import argparse
import json
import csv
from datetime import datetime, date
from pathlib import Path

try:
    import garminconnect
except ImportError:
    print("Por favor, instale a biblioteca: pip install garminconnect")
    sys.exit(1)

def get_credentials():
    email = os.environ.get("GARMIN_EMAIL")
    password = os.environ.get("GARMIN_PASSWORD")
    if email and password:
        return email, password

    print("Credenciais não encontradas nas variáveis de ambiente.")
    print("Dica: Use 'op item get Garmin --format=json' para extrair e definir:")
    print("export GARMIN_EMAIL=... \nexport GARMIN_PASSWORD=...")
    sys.exit(1)

def export_weight(client, start_date_str, end_date_str, target_dir):
    print(f"Buscando composição corporal de {start_date_str} a {end_date_str}...")
    try:
        weights_data = client.get_body_composition(start_date_str, end_date_str)
    except Exception as e:
        print(f"Erro ao buscar dados de peso: {e}")
        return

    weight_list = weights_data.get("dateWeightList", [])
    if not weight_list:
        print("Nenhum dado de peso encontrado no período.")
        return

    csv_path = target_dir / "weight.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["date", "weight_kg", "body_fat_percent", "muscle_mass_kg", "bone_mass_kg", "body_water_percent", "bmr"])
        
        for w in sorted(weight_list, key=lambda x: x["date"]):
            dt = datetime.fromtimestamp(w["date"] / 1000)
            date_str = dt.strftime("%Y-%m-%d")
            
            weight = round(w.get("weight") / 1000.0, 1) if w.get("weight") else ""
            fat = w.get("bodyFat") or ""
            muscle = round(w.get("muscleMass") / 1000.0, 1) if w.get("muscleMass") else ""
            bone = round(w.get("boneMass") / 1000.0, 1) if w.get("boneMass") else ""
            water = w.get("bodyWater") or ""
            bmr = w.get("bmr") or ""
            
            writer.writerow([date_str, weight, fat, muscle, bone, water, bmr])
            
    print(f"✅ Salvo {len(weight_list)} registros de peso em {csv_path}")

def map_activity_type(raw_type, activity_name):
    if "judo" in activity_name.lower():
        return "Judo"
        
    type_map = {
        "running": "Run",
        "strength_training": "Strength",
        "walking": "Walk",
        "cycling": "Cycling",
        "indoor_cycling": "Cycling"
    }
    
    if raw_type in type_map:
        return type_map[raw_type]
    return raw_type.replace("_", " ").title()

def export_activities(client, start_date_str, target_dir):
    print("Buscando histórico de atividades (isso pode demorar dependendo do volume)...")
    activities = []
    start = 0
    limit = 100
    
    while True:
        chunk = client.get_activities(start, limit)
        if not chunk:
            break
        
        reached_end = False
        for act in chunk:
            act_date_str = act.get("startTimeLocal", "").split(" ")[0]
            if act_date_str < start_date_str:
                reached_end = True
                break
            activities.append(act)
            
        if reached_end:
            break
        start += limit

    if not activities:
        print("Nenhuma atividade encontrada no período.")
        return

    # Ordem cronológica
    activities.reverse()
    
    csv_path = target_dir / "activities.csv"
    with open(csv_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "date", "activity_type", "duration_minutes", "calories", 
            "distance_km", "avg_heart_rate", "max_heart_rate", 
            "aerobic_training_effect", "anaerobic_training_effect", "training_load"
        ])
        
        for act in activities:
            date_str = act.get("startTimeLocal", "").split(" ")[0]
            raw_type = act.get("activityType", {}).get("typeKey", "other")
            act_name = act.get("activityName", "")
            
            final_type = map_activity_type(raw_type, act_name)
                
            dur = act.get("duration")
            duration_minutes = round(dur / 60.0) if dur else ""
            
            cal = act.get("calories")
            calories = round(cal) if cal else ""
            
            dist = act.get("distance")
            distance_km = round(dist / 1000.0, 2) if dist else ""
            
            avg_hr = act.get("averageHR") or ""
            max_hr = act.get("maxHR") or ""
            ae_te = round(act.get("aerobicTrainingEffect"), 1) if act.get("aerobicTrainingEffect") else ""
            an_te = round(act.get("anaerobicTrainingEffect"), 1) if act.get("anaerobicTrainingEffect") else ""
            load = act.get("activityTrainingLoad")
            training_load = round(load) if load else ""
            
            writer.writerow([
                date_str, final_type, duration_minutes, calories, 
                distance_km, avg_hr, max_hr, ae_te, an_te, training_load
            ])
            
    print(f"✅ Salvo {len(activities)} atividades em {csv_path}")

def main():
    parser = argparse.ArgumentParser(description="Exporta atividades e peso do Garmin em CSV")
    parser.add_argument("--start", type=str, default="2024-01-01", help="Data de início (YYYY-MM-DD)")
    parser.add_argument("--end", type=str, default=date.today().isoformat(), help="Data de fim (YYYY-MM-DD)")
    parser.add_argument("--outdir", type=str, default=".", help="Diretório para salvar os CSVs")
    args = parser.parse_args()

    email, password = get_credentials()
    target_dir = Path(args.outdir)
    target_dir.mkdir(parents=True, exist_ok=True)

    print("Conectando ao Garmin Connect...")
    client = garminconnect.Garmin(email, password)
    client.login()
    print("Login concluído!")

    export_weight(client, args.start, args.end, target_dir)
    export_activities(client, args.start, target_dir)

if __name__ == "__main__":
    main()
