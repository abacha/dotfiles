#!/usr/bin/env bash
# Sync AI coding-agent sessions to the Nexus Recall node (stargate).
# Must not run on stargate itself to avoid a sync loop.

RECALL_NODE="abacha@192.168.15.201"
RECALL_IP="192.168.15.201"
RSYNC="rsync -a --mkpath -e ssh"

# Bail out if we are already on the recall node.
if hostname -I 2>/dev/null | grep -qw "$RECALL_IP"; then
  exit 0
fi

# Claude Code sessions
if [ -d "$HOME/.claude/sessions" ]; then
  $RSYNC "$HOME/.claude/sessions/" "$RECALL_NODE:~/.claude/sessions/"
fi

# Codex sessions
if [ -d "$HOME/.codex" ]; then
  $RSYNC "$HOME/.codex/" "$RECALL_NODE:~/.codex/"
fi

# Antigravity sessions (always written to ~/.gemini/antigravity-cli regardless of ~/.agy migration)
if [ -d "$HOME/.gemini/antigravity-cli" ]; then
  $RSYNC "$HOME/.gemini/antigravity-cli/" "$RECALL_NODE:~/.gemini/antigravity-cli/"
fi

# OpenClaw agent sessions
for agent_dir in "$HOME"/.openclaw/agents/*/; do
  agent_name=$(basename "$agent_dir")
  src="$agent_dir/sessions/"
  if [ -d "$src" ]; then
    $RSYNC "$src" "$RECALL_NODE:~/.openclaw/session-archive/$agent_name/"
  fi
done

# Trigger ingest after sync (fire-and-forget)
curl -sf --max-time 10 -X POST "http://$RECALL_IP:18080/coding-agents/ingest" > /dev/null 2>&1 || true
