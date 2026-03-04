#!/usr/bin/env bash
set -euo pipefail

# Simple CLI for Nexus Recall API
# Usage examples:
#   nexus-recall.sh health
#   nexus-recall.sh chat "what did I say about X?" [model]
#   nexus-recall.sh search "query" [k_lexical] [k_vector]
#   nexus-recall.sh ingest /path/to/conversations.json
#   nexus-recall.sh job <job_id>
#   nexus-recall.sh retry <job_id>
#   nexus-recall.sh rebuild

BASE_URL="${NEXUS_RECALL_BASE_URL:-http://localhost:18080}"
TOKEN="${NEXUS_RECALL_AUTH_TOKEN:-}"

AUTH_ARGS=()
if [[ -n "$TOKEN" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer $TOKEN")
fi

json_headers=(-H "Content-Type: application/json")

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  echo "Usage: $0 <health|chat|search|ingest|job|retry|rebuild|conversation|messages> ..."
  exit 1
fi

case "$cmd" in
  health)
    curl -fsS "${BASE_URL}/health" "${AUTH_ARGS[@]}"
    ;;

  chat)
    q="${2:-}"
    model="${3:-}"
    [[ -z "$q" ]] && { echo "chat requires question"; exit 1; }
    if [[ -n "$model" ]]; then
      body=$(jq -n --arg q "$q" --arg model "$model" '{q:$q, model:$model}')
    else
      body=$(jq -n --arg q "$q" '{q:$q}')
    fi
    curl -fsS "${BASE_URL}/chat" "${AUTH_ARGS[@]}" "${json_headers[@]}" -d "$body"
    ;;

  search)
    q="${2:-}"
    klex="${3:-120}"
    kvec="${4:-120}"
    model="${5:-}"
    [[ -z "$q" ]] && { echo "search requires query"; exit 1; }
    if [[ -n "$model" ]]; then
      body=$(jq -n --arg q "$q" --argjson k_lexical "$klex" --argjson k_vector "$kvec" --arg embedding_model "$model" '{q:$q,k_lexical:$k_lexical,k_vector:$k_vector,embedding_model:$embedding_model}')
    else
      body=$(jq -n --arg q "$q" --argjson k_lexical "$klex" --argjson k_vector "$kvec" '{q:$q,k_lexical:$k_lexical,k_vector:$k_vector}')
    fi
    curl -fsS "${BASE_URL}/search" "${AUTH_ARGS[@]}" "${json_headers[@]}" -d "$body"
    ;;

  ingest)
    path="${2:-}"
    [[ -z "$path" ]] && { echo "ingest requires file path"; exit 1; }
    curl -fsS "${BASE_URL}/ingest/chatgpt" "${AUTH_ARGS[@]}" -F "file=@${path}"
    ;;

  job)
    id="${2:-}"
    [[ -z "$id" ]] && { echo "job requires job_id"; exit 1; }
    curl -fsS "${BASE_URL}/jobs/${id}" "${AUTH_ARGS[@]}"
    ;;

  retry)
    id="${2:-}"
    [[ -z "$id" ]] && { echo "retry requires job_id"; exit 1; }
    curl -fsS -X POST "${BASE_URL}/jobs/${id}/retry" "${AUTH_ARGS[@]}"
    ;;

  rebuild)
    model="${2:-}"
    if [[ -n "$model" ]]; then
      body=$(jq -n --arg embedding_model "$model" '{embedding_model:$embedding_model}')
      curl -fsS -X POST "${BASE_URL}/vector/rebuild" "${AUTH_ARGS[@]}" "${json_headers[@]}" -d "$body"
    else
      curl -fsS -X POST "${BASE_URL}/vector/rebuild" "${AUTH_ARGS[@]}"
    fi
    ;;

  conversation)
    id="${2:-}"
    [[ -z "$id" ]] && { echo "conversation requires id"; exit 1; }
    curl -fsS "${BASE_URL}/conversations/${id}" "${AUTH_ARGS[@]}"
    ;;

  messages)
    id="${2:-}"
    [[ -z "$id" ]] && { echo "messages requires conversation_id"; exit 1; }
    curl -fsS --get "${BASE_URL}/messages" "${AUTH_ARGS[@]}" --data-urlencode "conversation_id=${id}"
    ;;

  *)
    echo "Unknown command: $cmd"
    exit 1
    ;;
esac

echo
