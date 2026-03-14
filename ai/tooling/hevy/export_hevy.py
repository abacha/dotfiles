#!/usr/bin/env python3
import os
import sys
import argparse
import requests
import csv
from datetime import datetime

# API oficial do Hevy
HEVY_API_URL = "https://api.hevyapp.com/v1"

def get_api_key():
    api_key = os.environ.get("HEVY_API_KEY")
    if api_key:
        return api_key

    print("API Key do Hevy não encontrada nas variáveis de ambiente.")
    print("Para gerar a sua:")
    print(" 1. Acesse https://hevy.com/settings?developer")
    print(" 2. Crie uma chave (Apenas para usuários Hevy Pro)")
    print(" 3. Exporte no terminal: export HEVY_API_KEY='sua_chave'")
    sys.exit(1)

def fetch_workouts(api_key, limit=10):
    print("Buscando histórico de treinos no Hevy...")
    workouts = []
    page = 1
    
    headers = {
        "api-key": api_key,
        "Accept": "application/json"
    }

    while True:
        print(f"Buscando página {page}...")
        resp = requests.get(
            f"{HEVY_API_URL}/workouts", 
            headers=headers, 
            params={"page": page, "pageSize": 10} # pageSize max 10 (fixed)
        )
        
        if resp.status_code != 200:
            print(f"Erro ao acessar API (Status {resp.status_code}): {resp.text}")
            sys.exit(1)
            
        data = resp.json()
        items = data.get("workouts", [])
        
        if not items:
            break
            
        workouts.extend(items)
        
        # O limite max da paginacao oficial (page_count) indica o fim
        page_count = data.get("page_count", 1)
        if page >= page_count:
            break
            
        page += 1

    print(f"Total de treinos encontrados: {len(workouts)}")
    return workouts

def generate_csv(workouts, outdir):
    csv_path = os.path.join(outdir, "hevy_workouts.csv")
    
    # Criar pasta se não existir
    os.makedirs(outdir, exist_ok=True)
    
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        # Cabecalho basico, baseado no modelo do Hevy
        writer.writerow([
            "date", "workout_name", "duration_minutes", 
            "exercise", "sets", "total_volume_kg", "total_reps"
        ])
        
        # Inverter para ficar do mais antigo para o mais novo
        workouts.reverse()
        
        for w in workouts:
            # Data de início do treino (vem em formato ISO)
            start_time = w.get("start_time", "")
            # Converter 2024-03-10T12:00:00Z para YYYY-MM-DD
            date_str = start_time.split("T")[0] if start_time else ""
            
            # Duracao
            start_dt = datetime.fromisoformat(w["start_time"].replace("Z", "+00:00")) if w.get("start_time") else None
            end_dt = datetime.fromisoformat(w["end_time"].replace("Z", "+00:00")) if w.get("end_time") else None
            dur_mins = round((end_dt - start_dt).total_seconds() / 60) if start_dt and end_dt else ""

            name = w.get("name", "Treino")
            
            exercises = w.get("exercises", [])
            for ex in exercises:
                ex_name = ex.get("title", "")
                
                # Resumo do exercício
                sets_count = len(ex.get("sets", []))
                
                volume_kg = 0
                reps_total = 0
                for s in ex.get("sets", []):
                    # Se tiver peso e reps, calcula volume
                    weight = s.get("weight_kg", 0) or 0
                    reps = s.get("reps", 0) or 0
                    volume_kg += (weight * reps)
                    reps_total += reps

                writer.writerow([
                    date_str, name, dur_mins, 
                    ex_name, sets_count, volume_kg, reps_total
                ])
                
    print(f"✅ CSV exportado com sucesso para: {csv_path}")


def main():
    parser = argparse.ArgumentParser(description="Exporta atividades do Hevy via API Oficial")
    parser.add_argument("--outdir", type=str, default=".", help="Diretório para salvar o CSV")
    args = parser.parse_args()

    api_key = get_api_key()
    workouts = fetch_workouts(api_key)
    generate_csv(workouts, args.outdir)

if __name__ == "__main__":
    main()
