# Garmin Workout Generator

Scripts para gerar treinos intervalados no formato TCX para Garmin.

## Scripts

### generate_workout.rb

Gerador Ruby simples e direto.

**Usage:**
```bash
./generate_workout.rb \
  --name "5x1km" \
  --warmup 10 \
  --count 5 \
  --distance 1.0 \
  --pace 4:30 \
  --recovery 2 \
  --cooldown 10 \
  --output workout.tcx
```

### generate_tcx.py

Gerador Python com suporte a JSON config.

**Usage com JSON:**
```bash
./generate_tcx.py --json example_workout.json
```

**Example JSON:**
```json
{
  "name": "Interval Run",
  "warmup_min": 10,
  "intervals": [
    {"distance_km": 1.0, "target_pace": "4:30"},
    {"distance_km": 1.0, "target_pace": "4:30"}
  ],
  "recovery_min": 2.0,
  "cooldown_min": 10
}
```

## Import no Garmin

1. Gere o arquivo `.tcx`
2. Acesse Garmin Connect (web ou app)
3. Training → Workouts → Import
4. Faça upload do arquivo TCX

## Arquivos

- `generate_workout.rb` - Gerador Ruby
- `generate_tcx.py` - Gerador Python
- `example_workout.json` - Exemplo de config
- `Sample_Intervals.tcx` - Exemplo de output
- `README_TCX.md` - Documentação detalhada
