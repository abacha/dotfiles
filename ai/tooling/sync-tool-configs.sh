#!/usr/bin/env bash
set -euo pipefail
AI_DIR="$HOME/dotfiles/ai"
for d in "$HOME/.codex/agents" "$HOME/.claude/agents" "$HOME/.gemini/agents"; do
  [ -L "$d" ] && rm -f "$d"
  mkdir -p "$d"
  rsync -a --delete "$AI_DIR/projects/" "$d/projects/"
  rsync -a --delete "$AI_DIR/prompt-templates/" "$d/prompt-templates/"
  mkdir -p "$d/conventions" "$d/models" "$d/tooling"
  cp -f "$AI_DIR/routing-policy.md" "$d/routing-policy.md"
  cp -f "$AI_DIR/conventions/global-rules.md" "$d/conventions/global-rules.md"
  cp -f "$AI_DIR/models/defaults.md" "$d/models/defaults.md"
  cp -f "$AI_DIR/tooling/coding-agent.md" "$d/tooling/coding-agent.md"
  cat > "$d/README.md" << 'EOT'
# Local Agent Config Mirror

This folder is a local mirrored copy of `~/dotfiles/ai` for tool compatibility.
Do not edit files here manually.
Source of truth: `~/dotfiles/ai`
EOT
done

if [ -L "$HOME/.claude/CLAUDE.md" ]; then rm -f "$HOME/.claude/CLAUDE.md"; fi
cat > "$HOME/.claude/CLAUDE.md" << 'EOT'
# Claude Local Rules

Primary source of truth is `~/dotfiles/ai`.
This file is local (not symlinked) by design.

## Include
- `~/.claude/agents/conventions/global-rules.md`
- `~/.claude/agents/routing-policy.md`
EOT

echo "Sync complete."
