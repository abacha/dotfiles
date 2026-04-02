# Garmin Tooling

Conjunto consolidado de ferramentas e scripts para interagir com o Garmin Connect.

## Dependências

A ferramenta roda 100% em Ruby usando a gem oficial \`ruby_garmin_connect\`:
```bash
gem install ruby_garmin_connect csv dotenv
```

As credenciais do Garmin são necessárias para os comandos que conversam com a API (export, weight, resync-weight). Defina no ambiente:
```bash
export GARMIN_EMAIL="seu_email"
export GARMIN_PASSWORD="sua_senha"
```
*(Dica: podem ser facilmente puxadas do 1Password)*

## Uso: Garmin CLI

O script principal é o `garmin_cli.rb`. Ele agrega todas as funções:

### 1. Criar e Agendar Treinos (Workouts)
Cria um treino intervalado e envia direto via API, agendando-o no seu calendário Garmin para sincronizar com o relógio:
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


### 2. Exportar Todo o Histórico (CSVs)
Exporta um CSV com todas as atividades (`activities.csv`) e outro com o peso (`weight.csv`) do Connect:
```bash
./garmin_cli.rb export --start 2023-01-01 --end 2025-01-01 --outdir ~/exports/
```

### 3. Histórico de Peso Resumido
Imprime rapidamente no terminal a evolução do peso e massa muscular:
```bash
./garmin_cli.rb weight --months 12
```

### 4. Ressincronizar Histórico de Peso
Ferramenta para forçar a API a recalcular percentual de gordura (útil após atualizar a altura no perfil):
```bash
./garmin_cli.rb resync-weight --start 2020-01-01 --dry-run
```
*(Remova a flag `--dry-run` e adicione `--yes` para aplicar as modificações)*

## Estrutura do Diretório
- `garmin_cli.rb`: O CLI unificado contendo toda a lógica de comunicação com a API.

### 5. Histórico de Sono (Sleep Data)
Exporta dados detalhados do seu sono (pontuação, duração das fases do sono, HRV, frequência cardíaca, etc).
```bash
./garmin_cli.rb sleep --start 2024-01-01 --end 2024-02-01 --outdir ~/exports/
```

### 6. Histórico Diário (Daily Summary)
Exporta um resumão de saúde diário: passos, calorias gastas, Body Battery, estresse médio, frequência cardíaca (mín/máx/repouso), andares subidos e minutos de intensidade.
```bash
./garmin_cli.rb daily --start 2024-01-01 --end 2024-02-01 --outdir ~/exports/
```
