#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || cp .env.example .env
npm install
cat << 'EOF'
Setup complete.

Next:
1) Run a first send command (headed chrome opens):
   node bridge.mjs send --chat "<chat title>" --message "hello"
2) Log in to ChatGPT in that window when prompted.
3) Re-run same command; session is persisted in ./.profile
EOF
