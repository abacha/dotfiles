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

## Re-sincronizar o histórico de peso

O script `resync_weight_history.py` usa a biblioteca `garminconnect` para iterar pelas leituras de peso dentro de um intervalo, apagar o registro original e reaplicar o mesmo valor com os mesmos timestamps. Isso força o Garmin a recalcular percentuais e IMC usando a altura atualizada.

### Exemplo de uso

```bash
GARMIN_EMAIL=seu-email GARMIN_PASSWORD=senha python resync_weight_history.py \
  --start 2020-01-01 --end 2026-03-10 --chunk-days 90 --yes
```

- `--chunk-days` controla quantos dias são lidos por chamada API (padrão 120).
- `--dry-run` mostra o que seria feito sem tocar a conta.
- Por padrão o script apaga cada registro antes de reimportá-lo; passe `--no-delete` se quiser manter os originais.
- Tokens OAuth ficam em `~/.garminconnect` para agilizar execuções futuras.

## Arquivos

- `generate_workout.rb` - Gerador Ruby
- `generate_tcx.py` - Gerador Python
- `resync_weight_history.py` - Reaplica leituras para recalcular percentuais após mudança de altura
- `example_workout.json` - Exemplo de config
- `Sample_Intervals.tcx` - Exemplo de output
- `README_TCX.md` - Documentação detalhada
