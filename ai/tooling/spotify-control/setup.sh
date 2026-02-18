#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js not found in PATH"
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

npm install

echo
cat << 'EOF'
Setup complete.

Next steps:
1) Edit .env with:
   - SPOTIFY_CLIENT_ID
   - SPOTIFY_CLIENT_SECRET
   - (optional) SPOTIFY_REDIRECT_URI

2) Run auth flow (auto-opens browser, auto-saves token):
   npm run auth

3) Optional manual token update fallback:
   ./save-token.sh "<refresh_token>"

4) Test control:
   npm run control -- devices
   npm run control -- status
   npm run control -- current-volume
   npm run control -- play
EOF
