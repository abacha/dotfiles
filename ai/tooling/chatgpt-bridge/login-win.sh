#!/usr/bin/env bash
set -euo pipefail

PS1_PATH_W="$(wslpath -w "$HOME/dotfiles/ai/tooling/chatgpt-bridge/win-bridge.ps1")"

"/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" \
  -NoProfile -ExecutionPolicy Bypass \
  -File "$PS1_PATH_W" \
  -Mode login
