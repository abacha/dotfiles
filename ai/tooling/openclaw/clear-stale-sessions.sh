#!/bin/bash
# clear-stale-sessions.sh
# Automated midnight cleanup of OpenClaw sessions and zombies.
set -euo pipefail

echo "==> Killing hanging ACPX/Claude zombie processes..."
# Pkill any claude-agent-acp or acpx process that has been running for more than 1 hour (3600s)
killall -o 1h -q -r "claude-agent-acp|acpx" || true
# Alternatively, since killall with regex can be tricky, just kill them if they exist at midnight.
pkill -f "claude-agent-acp" || true

echo "==> Running internal OpenClaw session cleanup..."
find ~/.openclaw/agents/*/sessions/sessions.json -exec openclaw sessions cleanup --store {} --fix-missing --enforce \;

echo "==> Preventing dynamic subagents from accumulating 'done' sessions..."
for agent in claude codex gemini; do
  f=~/.openclaw/agents/$agent/sessions/sessions.json
  if [ -f "$f" ]; then
    jq 'with_entries(select(.value.status != "done"))' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

echo "==> Stripping completed/failed/killed subagents from main store..."
for f in ~/.openclaw/agents/*/sessions/sessions.json; do
  if [ -f "$f" ]; then
    jq 'with_entries(select( (.key | test("subagent|acp")) and (.value.status == "done" or .value.status == "error" or .value.status == "failed" or .value.status == "killed" or .value.status == "aborted") | not ))' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

echo "==> Cleaning up workspace trash..."
rm -f ~/.openclaw/workspace/.deleted.* ~/.openclaw/workspace/.reset.*

echo "==> Stale session cleanup complete!"