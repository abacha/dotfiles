# Nexus Recall Tool

CLI tool to interact with your Nexus Recall API.

## Location
`~/dotfiles/ai/tooling/nexus-recall`

## Requirements
- `curl`
- `jq`
- Running Nexus Recall API (`http://localhost:8000` by default)

## Env vars
- `NEXUS_RECALL_BASE_URL` (default: `http://localhost:8000`)
- `NEXUS_RECALL_AUTH_TOKEN` (optional)

## Commands
```bash
# health
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh health

# chat (optional model override)
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh chat "What did I discuss about billing?"
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh chat "What did I discuss about billing?" gpt-4o-mini

# search (query, k_lexical, k_vector, optional embedding_model)
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh search "invoice error" 120 120
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh search "invoice error" 120 120 text-embedding-3-small

# ingest export file
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh ingest ~/Downloads/conversations.json

# check/retry job
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh job <job_id>
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh retry <job_id>

# rebuild vector index (optional embedding model)
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh rebuild
~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh rebuild text-embedding-3-small
```

## Optional shell alias
```bash
alias recallctl='~/dotfiles/ai/tooling/nexus-recall/nexus-recall.sh'
```
