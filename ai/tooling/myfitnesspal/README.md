# MyFitnessPal Tooling

CLI de automação do MyFitnessPal via ADB, com foco em:
- interface curta
- estado explícito
- idempotência
- ordem de uso imprevisível
- retorno textual consistente por subcomando

## Princípios

- Nada adiciona alimento por acidente.
- `search-food` e `confirm-add` são separados.
- `launch`, `view-diary`, `dump-ui`, `status`, `meals` e `cancel-add` são seguros para repetir.
- `search-food` pode ser repetido; ele só sobrescreve o estado pendente.
- `confirm-add` falha com erro útil se não houver estado pendente válido.
- `cancel-add` é no-op seguro quando não existe nada pendente.
- Todo subcomando retorna um resumo textual curto e consistente neste formato:
  - `screen:` tela/estado detectado
  - `relevant:` elementos ou dados principais visíveis
  - `warnings:` limitações, incertezas ou ausência de dados
  - `next:` próximos comandos/ações seguras

## Requisitos

- Python 3.11+
- `adb` no PATH
- Dispositivo conectado em `192.168.15.58:5555` por padrão
- App Android `com.myfitnesspal.android` instalado

Para sobrescrever o device:

```bash
export MFP_ADB_DEVICE='192.168.15.58:5555'
```

## Comandos finais

### launch

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py launch
```

Abre o app e deixa no diário. Pode repetir.
Retorna a tela detectada, elementos importantes visíveis e próximos passos.

### view-diary

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py view-diary --date 2026-03-18
```

Auto-prepara o app e abre o diário. Não adiciona nada.
Retorna data solicitada, refeições/elementos detectados e warning explícito quando a data não pode ser garantida.

### dump-ui

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py dump-ui --output /tmp/mfp_dump.xml
```

Gera XML da UI atual para inspeção/calibração.
Retorna path salvo, tela detectada e contagem/resumo útil do dump.

### meals

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py meals
```

Lista refeições detectadas no diário atual.
Retorna seções detectadas e, quando possível, quantas têm conteúdo visível.

### status

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py status
```

Mostra o estado pendente atual, se existir.
Retorna resumo textual do pending state e próximos passos seguros.

### search-food

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py search-food \
  --query "banana" \
  --meal "Café da manhã" \
  --weight 120g
```

Busca sem adicionar nada. Salva estado pendente em `/tmp/mfp_pending_add.json`.
Retorna ranking textual dos resultados, sugestão implícita do melhor item e deixa explícito que nada foi adicionado ainda.

### confirm-add

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py confirm-add \
  --pick 1 \
  --weight 120g \
  --meal "Café da manhã"
```

Confirma explicitamente uma opção da última busca. Se der certo, limpa o estado pendente.
Retorna item/refeição/peso escolhidos, se os controles esperados foram encontrados e se o fluxo concluiu ou parou com segurança.

### cancel-add

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py cancel-add
```

Limpa o estado pendente sem adicionar nada. Repetir é seguro.
Retorna se havia pending state e se ele foi limpo.

## Fluxo recomendado

```bash
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py search-food --query "whey" --meal "Lanche da tarde" --weight 30g
python /home/abacha/dotfiles/ai/tooling/myfitnesspal/mfp-sync.py confirm-add --pick 1 --weight 30g --meal "Lanche da tarde"
```

## Fluxos tolerados

- `view-diary` antes de `launch`: funciona, porque auto-prepara o app.
- `launch` repetido: funciona.
- `search-food` repetido: só troca o estado pendente.
- `cancel-add` repetido: no-op seguro.
- `confirm-add` sem busca recente: erro útil, sem efeito colateral.
- estado pendente inexistente ou sem resultados: erro útil, sem efeito colateral.

## O que foi removido

- `--add-food`
- `--public-user`
- fallback legado de adição imediata
- modo “summary” não relacionado ao fluxo ADB
- compatibilidade ambígua baseada em flags soltas fora dos subcomandos

## Arquitetura

### `cli.py`
Parser enxuto, só com subcomandos explícitos.

### `client.py`
`MyFitnessPalClient` orquestra o fluxo, mantém o contrato textual da CLI e delega UI/ADB/state para módulos específicos.

### `app.py`
`MyFitnessPalApp` encapsula as telas e interações do app com métodos orientados ao fluxo humano (`open_app`, `go_to_diary`, `open_food_search`, `search_for`, `quick_add`, `detailed_add`).

### `adb.py`
Operações puras de ADB e utilitários de dump/click/wait. Zero regra de negócio do MyFitnessPal.

### `parsers.py`
Funções puras para detectar tela, normalizar refeição, extrair refeições/resultados e parsear macros HTML.

### `state.py`
Persistência e metadata de `/tmp/mfp_pending_add.json`.

### `adb_helpers.py`
Shim de compatibilidade para imports legados/tests antigos.

## Fixtures reais

Fixtures reais do app ficam em:

```bash
/home/abacha/dotfiles/ai/tooling/myfitnesspal/tests/fixtures/real/
```

Estrutura atual:

- `home/ui.xml` + `home/screen.png`
- `diary/ui.xml` + `diary/screen.png`
- `search/ui.xml` + `search/screen.png`
- `search_results/ui.xml` + `search_results/screen.png`

### Regenerar fixtures

Fluxo seguro, sem `confirm-add`:

```bash
/home/abacha/.asdf/installs/python/3.11.13/bin/python /home/abacha/dotfiles/ai/tooling/myfitnesspal/capture_real_fixtures.py
```

O script:
- abre o app
- captura diário
- captura painel
- abre a tela de busca
- executa uma busca por `banana` apenas para obter resultados reais
- salva XML + screenshot
- limpa o estado pendente com `cancel-add`
- **não executa `confirm-add`**

## Testes

Rodar suíte focada no tooling local:

```bash
cd /home/abacha/dotfiles/ai/tooling/myfitnesspal
/home/abacha/.asdf/installs/python/3.11.13/bin/python -m pytest tests/test_cli.py tests/test_adb.py tests/test_parser.py tests/test_real_fixtures.py
```

## Pendências conhecidas

- O fluxo de confirmação ainda depende dos ids/layouts atuais do app.
- `view-diary --date` continua conservador: abre o diário, mas não faz navegação robusta entre datas.
- O script limpa o campo de busca por keyevents; se o teclado/layout do Android mudar, pode exigir recalibração.
