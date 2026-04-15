#!/bin/bash
# Safely switch between Claude accounts without losing OAuth refresh tokens or mixing sessions.

TARGET=$1
ACTION=$2
CLAUDE_DIR="$HOME/.claude"

if [ "$TARGET" != "hs" ] && [ "$TARGET" != "personal" ]; then
    echo "Usage: claude-switch <hs|personal> [login|backup]"
    exit 1
fi

# Get current active profile
CURRENT="unknown"
if [ -f "$CLAUDE_DIR/.active-profile" ]; then
    CURRENT=$(cat "$CLAUDE_DIR/.active-profile")
fi

# Function to save current state
save_current() {
    local prof=$1
    if [ "$prof" != "unknown" ]; then
        [ -f "$CLAUDE_DIR/.credentials.json" ] && cp "$CLAUDE_DIR/.credentials.json" "$CLAUDE_DIR/.credentials-${prof}.json"
        [ -f "$HOME/.claude.json" ] && cp "$HOME/.claude.json" "$HOME/.claude-${prof}.json"
        [ -d "$CLAUDE_DIR/sessions" ] && rm -rf "$CLAUDE_DIR/sessions-${prof}" && cp -r "$CLAUDE_DIR/sessions" "$CLAUDE_DIR/sessions-${prof}"
        [ -d "$CLAUDE_DIR/session-env" ] && rm -rf "$CLAUDE_DIR/session-env-${prof}" && cp -r "$CLAUDE_DIR/session-env" "$CLAUDE_DIR/session-env-${prof}"
        [ -f "$CLAUDE_DIR/history.jsonl" ] && cp "$CLAUDE_DIR/history.jsonl" "$CLAUDE_DIR/history-${prof}.jsonl"
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
    if [ "$ACTION" != "login" ] && [ ! -f "$CLAUDE_DIR/.credentials-${TARGET}.json" ]; then
        echo "Error: $CLAUDE_DIR/.credentials-${TARGET}.json does not exist."
        echo "If this is a new account or you need to re-auth, run: claude-switch $TARGET login"
        exit 1
    fi

    # Load the target state
    [ -f "$CLAUDE_DIR/.credentials-${TARGET}.json" ] && cp "$CLAUDE_DIR/.credentials-${TARGET}.json" "$CLAUDE_DIR/.credentials.json" || rm -f "$CLAUDE_DIR/.credentials.json"
    [ -f "$HOME/.claude-${TARGET}.json" ] && cp "$HOME/.claude-${TARGET}.json" "$HOME/.claude.json" || rm -f "$HOME/.claude.json"

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
fi

if [ "$ACTION" = "login" ]; then
    echo "🔑 Running claude auth login for $TARGET..."

    # We use 'script' to allocate a pseudo-terminal (PTY) so the CLI doesn't hang or hide input prompts
    # while we simultaneously capture the URL to copy it to the clipboard.
    script -q -e -c "claude auth login" /dev/null | tee >(
        grep -m 1 -oE 'https://claude\.com[a-zA-Z0-9./?=&_+-]+' | while read -r url; do
            # Use OSC 52
            printf "\033]52;c;%s\007" "$(printf "%s" "$url" | base64 | tr -d '\n')"
            # Fallback for WSL
            if [ -x "/mnt/c/Windows/System32/clip.exe" ]; then
                printf "%s" "$url" | /mnt/c/Windows/System32/clip.exe
            fi
            echo -e "\n📋 [Auto-copied URL to your clipboard!]" > /dev/tty
        done
    )

    save_current "$TARGET"
    echo "✅ Login complete and credentials safely backed up for $TARGET."
fi
