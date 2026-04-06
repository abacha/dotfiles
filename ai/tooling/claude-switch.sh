#!/bin/bash
# Safely switch between Claude accounts without losing OAuth refresh tokens or mixing sessions.

TARGET=$1
CLAUDE_DIR="$HOME/.claude"

if [ "$TARGET" != "hs" ] && [ "$TARGET" != "personal" ]; then
    echo "Usage: claude-switch <hs|personal>"
    exit 1
fi

# Get current active profile
CURRENT="unknown"
if [ -f "$CLAUDE_DIR/.active-profile" ]; then
    CURRENT=$(cat "$CLAUDE_DIR/.active-profile")
fi

if [ "$CURRENT" = "$TARGET" ]; then
    echo "Claude is already set to $TARGET."
    exit 0
fi

# Save current state to preserve refreshed OAuth tokens and active sessions
if [ "$CURRENT" != "unknown" ]; then
    [ -f "$CLAUDE_DIR/.credentials.json" ] && cp "$CLAUDE_DIR/.credentials.json" "$CLAUDE_DIR/.credentials-${CURRENT}.json"
    [ -d "$CLAUDE_DIR/sessions" ] && rm -rf "$CLAUDE_DIR/sessions-${CURRENT}" && cp -r "$CLAUDE_DIR/sessions" "$CLAUDE_DIR/sessions-${CURRENT}"
    [ -d "$CLAUDE_DIR/session-env" ] && rm -rf "$CLAUDE_DIR/session-env-${CURRENT}" && cp -r "$CLAUDE_DIR/session-env" "$CLAUDE_DIR/session-env-${CURRENT}"
    [ -f "$CLAUDE_DIR/history.jsonl" ] && cp "$CLAUDE_DIR/history.jsonl" "$CLAUDE_DIR/history-${CURRENT}.jsonl"
fi

# Load the target state
if [ ! -f "$CLAUDE_DIR/.credentials-${TARGET}.json" ]; then
    echo "Error: $CLAUDE_DIR/.credentials-${TARGET}.json does not exist."
    exit 1
fi

cp "$CLAUDE_DIR/.credentials-${TARGET}.json" "$CLAUDE_DIR/.credentials.json"

if [ -d "$CLAUDE_DIR/sessions-${TARGET}" ]; then
    rm -rf "$CLAUDE_DIR/sessions"
    cp -r "$CLAUDE_DIR/sessions-${TARGET}" "$CLAUDE_DIR/sessions"
else
    rm -rf "$CLAUDE_DIR/sessions"
    mkdir -p "$CLAUDE_DIR/sessions"
fi

if [ -d "$CLAUDE_DIR/session-env-${TARGET}" ]; then
    rm -rf "$CLAUDE_DIR/session-env"
    cp -r "$CLAUDE_DIR/session-env-${TARGET}" "$CLAUDE_DIR/session-env"
else
    rm -rf "$CLAUDE_DIR/session-env"
    mkdir -p "$CLAUDE_DIR/session-env"
fi

if [ -f "$CLAUDE_DIR/history-${TARGET}.jsonl" ]; then
    cp "$CLAUDE_DIR/history-${TARGET}.jsonl" "$CLAUDE_DIR/history.jsonl"
else
    rm -f "$CLAUDE_DIR/history.jsonl"
    touch "$CLAUDE_DIR/history.jsonl"
fi

echo "$TARGET" > "$CLAUDE_DIR/.active-profile"
echo "✅ Claude switched to $TARGET."
echo "OAuth tokens and sessions safely preserved for the previous account."
