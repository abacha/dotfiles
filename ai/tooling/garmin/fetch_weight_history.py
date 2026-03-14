#!/usr/bin/env python3
import os, sys, argparse
from datetime import datetime, timedelta
from collections import defaultdict

try:
    import garminconnect
except ImportError:
    print("Por favor, instale a biblioteca: pip install garminconnect")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Busca histórico de peso do Garmin Connect")
    parser.add_argument("--months", type=int, default=6, help="Quantidade de meses para trás")
    parser.add_argument("--email", type=str, default=os.environ.get("GARMIN_EMAIL"), help="Email do Garmin Connect")
    parser.add_argument("--password", type=str, default=os.environ.get("GARMIN_PASSWORD"), help="Senha do Garmin Connect")
    args = parser.parse_args()

    end_date = datetime.today()
    start_date = end_date - timedelta(days=30 * args.months)

    print(f"Buscando histórico do Garmin de {start_date.date()} a {end_date.date()}...")
    try:
        # Tenta conectar. O garminconnect cacheia os tokens OAuth2 em ~/.garminconnect
        client = garminconnect.Garmin(args.email, args.password)
        client.login()
    except Exception as e:
        print(f"Erro no login (verifique as credenciais ou o token salvo): {e}")
        print("Dica: Use 'op item get Garmin --format=json' para extrair as credenciais do 1Password.")
        sys.exit(1)

    try:
        weights = client.get_body_composition(start_date.date().isoformat(), end_date.date().isoformat())
    except Exception as e:
        print(f"Erro ao buscar dados de composição corporal: {e}")
        sys.exit(1)

    weight_list = weights.get("dateWeightList", [])
    if not weight_list:
        print("Nenhum dado de peso encontrado no período.")
        return

    monthly = defaultdict(list)
    for w in sorted(weight_list, key=lambda x: x["date"]):
        dt = datetime.fromtimestamp(w["date"] / 1000)
        
        weight = w.get("weight")
        weight = (weight / 1000.0) if weight else 0
        
        fat = w.get("bodyFat")
        
        muscle = w.get("muscleMass")
        muscle = (muscle / 1000.0) if muscle else 0
        
        monthly[dt.strftime("%Y-%m")].append({
            "date": dt.strftime("%d/%m"),
            "weight": weight,
            "fat": fat,
            "muscle": muscle,
        })

    print(f"\n📊 **Histórico de Peso (Últimos {args.months} meses)**\n")
    for month, entries in sorted(monthly.items()):
        print(f"**{month}**")
        for e in entries:
            fat_str = f", Gordura: {e['fat']}%" if e['fat'] else ""
            muscle_str = f", Músculo: {e['muscle']:.1f}kg" if e['muscle'] else ""
            print(f" - {e['date']}: {e['weight']:.1f}kg{fat_str}{muscle_str}")
        print("")

if __name__ == "__main__":
    main()
