#!/bin/bash
# Safely switch between Codex accounts without losing OAuth refresh tokens or mixing sessions.

TARGET=$1
ACTION=$2
CODEX_DIR="$HOME/.codex"

if [ "$TARGET" != "hs" ] && [ "$TARGET" != "personal" ]; then
    echo "Usage: codex-switch <hs|personal> [login|backup]"
    exit 1
fi

# Get current active profile
CURRENT="unknown"
if [ -f "$CODEX_DIR/.active-profile" ]; then
    CURRENT=$(cat "$CODEX_DIR/.active-profile")
fi

# Function to save current state
save_current() {
    local prof=$1
    if [ "$prof" != "unknown" ]; then
        [ -f "$CODEX_DIR/auth.json" ] && cp "$CODEX_DIR/auth.json" "$CODEX_DIR/auth-${prof}.json"
        [ -d "$CODEX_DIR/sessions" ] && rm -rf "$CODEX_DIR/sessions-${prof}" && cp -r "$CODEX_DIR/sessions" "$CODEX_DIR/sessions-${prof}"
        [ -f "$CODEX_DIR/history.jsonl" ] && cp "$CODEX_DIR/history.jsonl" "$CODEX_DIR/history-${prof}.jsonl"
    fi
}

if [ "$ACTION" = "backup" ]; then
    if [ "$CURRENT" != "$TARGET" ]; then
         echo "Error: You can only backup the active profile ($CURRENT). Switch to $TARGET first."
         exit 1
    fi
    save_current "$CURRENT"
    echo "✅ Credentials backed up for $CURRENT."
    exit 0
fi

if [ "$CURRENT" != "$TARGET" ]; then
    # Save current state before switching
    save_current "$CURRENT"

    # If not logging in, ensure backup files exist
    if [ "$ACTION" != "login" ] && [ ! -f "$CODEX_DIR/auth-${TARGET}.json" ]; then
        echo "Error: $CODEX_DIR/auth-${TARGET}.json does not exist."
        echo "If this is a new account or you need to re-auth, run: codex-switch $TARGET login"
        exit 1
    fi

    # Load the target state
    [ -f "$CODEX_DIR/auth-${TARGET}.json" ] && cp "$CODEX_DIR/auth-${TARGET}.json" "$CODEX_DIR/auth.json" || rm -f "$CODEX_DIR/auth.json"

    if [ -d "$CODEX_DIR/sessions-${TARGET}" ]; then
        rm -rf "$CODEX_DIR/sessions"
        cp -r "$CODEX_DIR/sessions-${TARGET}" "$CODEX_DIR/sessions"
    else
        rm -rf "$CODEX_DIR/sessions"
        mkdir -p "$CODEX_DIR/sessions"
    fi

    if [ -f "$CODEX_DIR/history-${TARGET}.jsonl" ]; then
        cp "$CODEX_DIR/history-${TARGET}.jsonl" "$CODEX_DIR/history.jsonl"
    else
        rm -f "$CODEX_DIR/history.jsonl"
        touch "$CODEX_DIR/history.jsonl"
    fi

    echo "$TARGET" > "$CODEX_DIR/.active-profile"
    echo "✅ Codex switched to $TARGET."
fi

if [ "$ACTION" = "login" ]; then
    echo "🔑 Running codex login for $TARGET..."

    if [ "$TARGET" = "hs" ]; then
        # Profile HS uses standard browser login
        echo "Using standard browser OAuth login for $TARGET..."
        script -q -e -c "codex login" /dev/null
    else
        # Profile Personal (or others) uses device-auth
        echo "Using device-auth login for $TARGET..."
        script -q -e -c "codex login --device-auth" /dev/null | tee >(
            grep -m 1 -iE 'https://openai\.com/device' | while read -r url; do
                echo -e "\n📋 [Awaiting device auth! Follow the instructions above]" > /dev/tty
            done
        )
    fi

    save_current "$TARGET"
    echo "✅ Login complete and credentials safely backed up for $TARGET."
fi
