#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$DIR/.env"

TOKEN="${1:-}"
if [ -z "$TOKEN" ]; then
  echo "Usage: ./save-token.sh <refresh_token>"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$DIR/.env.example" "$ENV_FILE"
fi

if grep -q '^SPOTIFY_REFRESH_TOKEN=' "$ENV_FILE"; then
  sed -i "s#^SPOTIFY_REFRESH_TOKEN=.*#SPOTIFY_REFRESH_TOKEN=$TOKEN#" "$ENV_FILE"
else
  printf "\nSPOTIFY_REFRESH_TOKEN=%s\n" "$TOKEN" >> "$ENV_FILE"
fi

echo "OK: SPOTIFY_REFRESH_TOKEN updated in $ENV_FILE"
