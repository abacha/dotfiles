# Garmin Tooling

Conjunto consolidado de ferramentas e scripts para interagir com o Garmin Connect.

## Dependências

A extração de dados da API requer a biblioteca Python `garminconnect`:
```bash
pip install garminconnect
```

O gerador de TCX usa Ruby:
```bash
gem install builder
```

As credenciais do Garmin são necessárias para os comandos que conversam com a API (export e weight). Defina no ambiente:
```bash
export GARMIN_EMAIL="seu_email"
export GARMIN_PASSWORD="sua_senha"
```
*(Dica: podem ser facilmente puxadas do 1Password)*

## Uso: Garmin CLI

O script principal é o `garmin_cli.rb`. Ele agrega as funções mais usadas:

### 1. Gerar Treinos TCX (Intervalados)
Gera treinos no formato suportado para upload no Garmin Connect:
```bash
./garmin_cli.rb tcx --name "5x1k" \
  --warmup 10 \
  --count 5 \
  --distance 1.0 \
  --pace 4:30 \
  --recovery 2 \
  --cooldown 10 \
  --output treino.tcx
```

### 2. Exportar Todo o Histórico (CSVs)
Exporta um CSV com todas as atividades (`activities.csv`) e outro com o peso (`weight.csv`) do Connect:
```bash
./garmin_cli.rb export --start 2023-01-01 --outdir ~/exports/
```

### 3. Histórico de Peso Resumido
Imprime rapidamente no terminal a evolução do peso e massa muscular:
```bash
./garmin_cli.rb weight --months 12
```

## Estrutura do Diretório
- `garmin_cli.rb`: O ponto central de entrada (CLI).
- `export_garmin_csv.py` / `fetch_weight_history.py`: Módulos em Python delegados pelo CLI Ruby para interagir com as rotas não-oficiais do Garmin.
- `resync_weight_history.py`: Ferramenta para forçar a API a recalcular percentual de gordura após atualizar a altura no perfil.
