#!/usr/bin/env python3
import os
import sys
import argparse
import requests
import csv
from datetime import datetime

# Hevy Unofficial Web API
HEVY_LOGIN_URL = "https://api.hevyapp.com/login"
HEVY_FEED_URL = "https://api.hevyapp.com/user_workouts_paged"  # we will use the correct one later if needed, but feed_workouts_paged works for own feed too maybe? No, let's use the one from hevyapp-api

def get_credentials():
    email = os.environ.get("HEVY_EMAIL")
    password = os.environ.get("HEVY_PASSWORD")
    if email and password:
        return email, password

    print("Credenciais não encontradas nas variáveis de ambiente.")
    print("Dica: Use 'op item get Hevy --format=json' para extrair e definir:")
    print("export HEVY_EMAIL=... \nexport HEVY_PASSWORD=...")
    sys.exit(1)

def login(email, password):
    print("Autenticando no Hevy (Unofficial API)...")
    headers = {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'x-api-key': 'shelobs_hevy_web',
    }
    
    resp = requests.post(HEVY_LOGIN_URL, headers=headers, json={
        'emailOrUsername': email,
        'password': password
    })
    
    if resp.status_code != 200:
        print(f"Falha no login: {resp.text}")
        sys.exit(1)
        
    data = resp.json()
    return data.get('auth_token')

def fetch_workouts(auth_token):
    print("Buscando treinos...")
    headers = {
        'accept': 'application/json, text/plain, */*',
        'x-api-key': 'shelobs_hevy_web',
        'auth-token': auth_token,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    }
    
    # Try fetching workouts from routine sync or feed.
    # The unofficial way to get ALL workouts reliably is by getting routine history
    # Let's try feed_workouts_paged first
    # Actually, a better approach if they use Hevy Web is:
    # hevy.com has an endpoint: GET https://api.hevyapp.com/workouts_count
    # GET https://api.hevyapp.com/user_workouts?offset=0&limit=100
    
    offset = 0
    limit = 50
    all_workouts = []
    
    while True:
        print(f"Buscando offset {offset}...")
        resp = requests.get(f"https://api.hevyapp.com/workouts?offset={offset}&limit={limit}", headers=headers)
        
        if resp.status_code != 200:
            print("Tentando endpoint alternativo (user_workouts)...")
            resp = requests.get(f"https://api.hevyapp.com/feed_workouts_paged", headers=headers) # fallback
            
        data = resp.json()
        workouts = data if isinstance(data, list) else data.get("workouts", [])
        
        if not workouts:
            break
            
        all_workouts.extend(workouts)
        if len(workouts) < limit:
            break
        offset += limit
        
    return all_workouts

def generate_csv(workouts, outdir):
    csv_path = os.path.join(outdir, "hevy_workouts.csv")
    os.makedirs(outdir, exist_ok=True)
    
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "date", "workout_name", "duration_minutes", 
            "exercise", "sets", "total_volume_kg", "total_reps"
        ])
        
        workouts.reverse()
        
        for w in workouts:
            start_ts = w.get("start_time", 0)
            end_ts = w.get("end_time", 0)
            
            if start_ts:
                dt = datetime.fromtimestamp(start_ts)
                date_str = dt.strftime("%Y-%m-%d")
                dur_mins = round((end_ts - start_ts) / 60) if end_ts else ""
            else:
                date_str = ""
                dur_mins = ""

            name = w.get("name", "Treino")
            
            exercises = w.get("exercises", [])
            for ex in exercises:
                ex_name = ex.get("title", "")
                
                sets = ex.get("sets", [])
                sets_count = len(sets)
                
                volume_kg = 0
                reps_total = 0
                for s in sets:
                    weight = s.get("weight_kg") or 0
                    reps = s.get("reps") or 0
                    volume_kg += (weight * reps)
                    reps_total += reps

                writer.writerow([
                    date_str, name, dur_mins, 
                    ex_name, sets_count, volume_kg, reps_total
                ])
                
    print(f"✅ CSV exportado com sucesso para: {csv_path}")

def main():
    parser = argparse.ArgumentParser(description="Exporta atividades do Hevy via Login Web")
    parser.add_argument("--outdir", type=str, default=".", help="Diretório para salvar o CSV")
    args = parser.parse_args()

    email, password = get_credentials()
    token = login(email, password)
    workouts = fetch_workouts(token)
    generate_csv(workouts, args.outdir)

if __name__ == "__main__":
    main()
