#!/usr/bin/env bash
set -euo pipefail

CHAT="${1:-}"
MSG="${2:-}"

if [ -z "$CHAT" ] || [ -z "$MSG" ]; then
  echo "Usage: ./send-win.sh \"<chat title>\" \"<message>\""
  exit 1
fi

PS1_PATH_W="$(wslpath -w "$(dirname "$0")/win-bridge.ps1")"

"/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" \
  -NoProfile -ExecutionPolicy Bypass \
  -File "$PS1_PATH_W" \
  -Mode send \
  -Chat "$CHAT" \
  -Message "$MSG"
