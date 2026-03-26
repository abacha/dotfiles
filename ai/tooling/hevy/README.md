# Hevy Tooling

Conjunto de ferramentas consolidadas em um único CLI Ruby para interagir com a API oficial do Hevy.

## Dependências

O script utiliza Ruby puro com as gems definidas no `Gemfile`. Para instalar:
```bash
bundle install
```

As credenciais do Hevy (API Key) são necessárias. O script tentará carregar na seguinte ordem:
1. Variável de ambiente `HEVY_API_KEY` injetada via shell.
2. Arquivo `.env` local contendo `HEVY_API_KEY=sua_chave`.
3. Fallback: Consulta o 1Password CLI (`op item get Hevy --format=json`).

*(Para gerar uma API Key: Acesse `hevy.com/settings?developer`, apenas para usuários Pro).*

## Uso: Hevy CLI

O script principal é o `hevy_cli.rb`.

### 1. Exportar Histórico de Treinos (CSVs)
Busca todos os treinos concluídos e gera um CSV `hevy_workouts.csv` contendo o detalhamento de volume por exercício.
```bash
./hevy_cli.rb export-workouts --outdir .
```

### 2. Exportar Rotinas / Templates
Busca as suas rotinas salvas no Hevy e gera um CSV `hevy_routines.csv` com a ordem dos exercícios e os supersets configurados.
```bash
./hevy_cli.rb export-routines --outdir .
```

## Estrutura do Diretório
- `hevy_cli.rb`: O CLI unificado com a lógica de comunicação e paginação.
- `Gemfile`: Dependências.
