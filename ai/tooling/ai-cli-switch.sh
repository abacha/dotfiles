#!/usr/bin/env bash
# Unified profile switcher for Claude and Codex CLI tools.
# Usage: ai-cli-switch <claude|codex> <hs|personal> [login|backup] [--push]

set -euo pipefail

# ── Arg parsing ────────────────────────────────────────────────────────────────
TOOL=${1:-}
TARGET=${2:-}
shift 2 2>/dev/null || true

ACTION=""
PUSH=false
for arg in "$@"; do
    case "$arg" in
        --push)         PUSH=true ;;
        login|backup)   ACTION="$arg" ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

if [[ "$TOOL" != "claude" && "$TOOL" != "codex" ]] || \
   [[ "$TARGET" != "hs" && "$TARGET" != "p" ]]; then
    echo "Usage: ai-cli-switch <claude|codex> <hs|p> [login|backup] [--push]"
    exit 1
fi

CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="$HOME/.codex"

# ── Save current state ─────────────────────────────────────────────────────────
save_current() {
    local prof=$1
    [[ "$prof" == "unknown" ]] && return

    if [[ "$TOOL" == "claude" ]]; then
        [ -f "$CLAUDE_DIR/.credentials.json" ] && cp "$CLAUDE_DIR/.credentials.json" "$CLAUDE_DIR/.credentials-${prof}.json"
        [ -f "$HOME/.claude.json" ]            && cp "$HOME/.claude.json" "$HOME/.claude-${prof}.json"
        [ -d "$CLAUDE_DIR/sessions" ]     && rm -rf "$CLAUDE_DIR/sessions-${prof}"     && cp -r "$CLAUDE_DIR/sessions"     "$CLAUDE_DIR/sessions-${prof}"
        [ -d "$CLAUDE_DIR/session-env" ]  && rm -rf "$CLAUDE_DIR/session-env-${prof}"  && cp -r "$CLAUDE_DIR/session-env"  "$CLAUDE_DIR/session-env-${prof}"
        [ -f "$CLAUDE_DIR/history.jsonl" ] && cp "$CLAUDE_DIR/history.jsonl" "$CLAUDE_DIR/history-${prof}.jsonl"
    else
        [ -f "$CODEX_DIR/auth.json" ]      && cp "$CODEX_DIR/auth.json" "$CODEX_DIR/auth-${prof}.json"
        [ -d "$CODEX_DIR/sessions" ]       && rm -rf "$CODEX_DIR/sessions-${prof}" && cp -r "$CODEX_DIR/sessions" "$CODEX_DIR/sessions-${prof}"
        [ -f "$CODEX_DIR/history.jsonl" ]  && cp "$CODEX_DIR/history.jsonl" "$CODEX_DIR/history-${prof}.jsonl"
    fi
}

# ── Push to all nodes ──────────────────────────────────────────────────────────
push_all() {
    local nodes=(net-core forge stargate cyber-core)

    local claude_files=(
        "$HOME/.claude/.credentials.json"
        "$HOME/.claude/.credentials-hs.json"
        "$HOME/.claude/.credentials-p.json"
        "$HOME/.claude/.active-profile"
        "$HOME/.claude.json"
        "$HOME/.claude-hs.json"
        "$HOME/.claude-p.json"
    )
    local codex_files=(
        "$HOME/.codex/auth.json"
        "$HOME/.codex/auth-hs.json"
        "$HOME/.codex/auth-p.json"
        "$HOME/.codex/.active-profile"
    )

    echo "Pushing credentials to homelab nodes..."
    local node
    for node in "${nodes[@]}"; do
        echo -n "  $node ... "
        ssh -o ConnectTimeout=5 "$node" "mkdir -p ~/.claude ~/.codex" 2>/dev/null || {
            echo "SKIP (unreachable)"
            continue
        }

        local dir_files=() home_files=() c_files=()
        for f in "${claude_files[@]}"; do
            [ -f "$f" ] || continue
            [[ "$f" == "$HOME/.claude/"* ]] && dir_files+=("$f") || home_files+=("$f")
        done
        for f in "${codex_files[@]}"; do
            [ -f "$f" ] && c_files+=("$f")
        done

        [ ${#dir_files[@]} -gt 0 ]   && rsync -az --no-perms "${dir_files[@]}"   "${node}:~/.claude/"
        [ ${#home_files[@]} -gt 0 ]  && rsync -az --no-perms "${home_files[@]}"  "${node}:~/"
        [ ${#c_files[@]} -gt 0 ]     && rsync -az --no-perms "${c_files[@]}"     "${node}:~/.codex/"
        echo "OK"
    done
    echo "Done."
}

# ── Resolve active profile ─────────────────────────────────────────────────────
ACTIVE_FILE="$([[ "$TOOL" == "claude" ]] && echo "$CLAUDE_DIR/.active-profile" || echo "$CODEX_DIR/.active-profile")"
CURRENT="unknown"
[ -f "$ACTIVE_FILE" ] && CURRENT=$(cat "$ACTIVE_FILE")

# ── Backup action ──────────────────────────────────────────────────────────────
if [[ "$ACTION" == "backup" ]]; then
    if [[ "$CURRENT" != "$TARGET" ]]; then
        echo "Error: you can only backup the active profile ($CURRENT). Switch to $TARGET first."
        exit 1
    fi
    save_current "$CURRENT"
    echo "✅ $TOOL credentials backed up for $CURRENT."
    [[ "$PUSH" == "true" ]] && push_all
    exit 0
fi

# ── Switch profile ─────────────────────────────────────────────────────────────
if [[ "$CURRENT" != "$TARGET" ]]; then
    save_current "$CURRENT"

    if [[ "$ACTION" != "login" ]]; then
        if [[ "$TOOL" == "claude" && ! -f "$CLAUDE_DIR/.credentials-${TARGET}.json" ]]; then
            echo "Error: $CLAUDE_DIR/.credentials-${TARGET}.json not found."
            echo "Run: ai-cli-switch claude $TARGET login"
            exit 1
        fi
        if [[ "$TOOL" == "codex" && ! -f "$CODEX_DIR/auth-${TARGET}.json" ]]; then
            echo "Error: $CODEX_DIR/auth-${TARGET}.json not found."
            echo "Run: ai-cli-switch codex $TARGET login"
            exit 1
        fi
    fi

    if [[ "$TOOL" == "claude" ]]; then
        [ -f "$CLAUDE_DIR/.credentials-${TARGET}.json" ] \
            && cp "$CLAUDE_DIR/.credentials-${TARGET}.json" "$CLAUDE_DIR/.credentials.json" \
            || rm -f "$CLAUDE_DIR/.credentials.json"
        [ -f "$HOME/.claude-${TARGET}.json" ] \
            && cp "$HOME/.claude-${TARGET}.json" "$HOME/.claude.json" \
            || rm -f "$HOME/.claude.json"
        if [ -d "$CLAUDE_DIR/sessions-${TARGET}" ]; then
            rm -rf "$CLAUDE_DIR/sessions" && cp -r "$CLAUDE_DIR/sessions-${TARGET}" "$CLAUDE_DIR/sessions"
        else
            rm -rf "$CLAUDE_DIR/sessions" && mkdir -p "$CLAUDE_DIR/sessions"
        fi
        if [ -d "$CLAUDE_DIR/session-env-${TARGET}" ]; then
            rm -rf "$CLAUDE_DIR/session-env" && cp -r "$CLAUDE_DIR/session-env-${TARGET}" "$CLAUDE_DIR/session-env"
        else
            rm -rf "$CLAUDE_DIR/session-env" && mkdir -p "$CLAUDE_DIR/session-env"
        fi
        if [ -f "$CLAUDE_DIR/history-${TARGET}.jsonl" ]; then
            cp "$CLAUDE_DIR/history-${TARGET}.jsonl" "$CLAUDE_DIR/history.jsonl"
        else
            rm -f "$CLAUDE_DIR/history.jsonl" && touch "$CLAUDE_DIR/history.jsonl"
        fi
    else
        [ -f "$CODEX_DIR/auth-${TARGET}.json" ] \
            && cp "$CODEX_DIR/auth-${TARGET}.json" "$CODEX_DIR/auth.json" \
            || rm -f "$CODEX_DIR/auth.json"
        if [ -d "$CODEX_DIR/sessions-${TARGET}" ]; then
            rm -rf "$CODEX_DIR/sessions" && cp -r "$CODEX_DIR/sessions-${TARGET}" "$CODEX_DIR/sessions"
        else
            rm -rf "$CODEX_DIR/sessions" && mkdir -p "$CODEX_DIR/sessions"
        fi
        if [ -f "$CODEX_DIR/history-${TARGET}.jsonl" ]; then
            cp "$CODEX_DIR/history-${TARGET}.jsonl" "$CODEX_DIR/history.jsonl"
        else
            rm -f "$CODEX_DIR/history.jsonl" && touch "$CODEX_DIR/history.jsonl"
        fi
    fi

    echo "$TARGET" > "$ACTIVE_FILE"
    echo "✅ $TOOL switched to $TARGET."
fi

# ── Login ──────────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "login" ]]; then
    echo "🔑 Logging in $TOOL as $TARGET..."

    if [[ "$TOOL" == "claude" ]]; then
        script -q -e -c "claude setup-token" /dev/null | tee >(
            grep -m 1 -oE 'https://claude\.com[a-zA-Z0-9./?=&_+-]+' | while read -r url; do
                printf "\033]52;c;%s\007" "$(printf "%s" "$url" | base64 | tr -d '\n')"
                [ -x "/mnt/c/Windows/System32/clip.exe" ] && printf "%s" "$url" | /mnt/c/Windows/System32/clip.exe
                echo -e "\n📋 [Auto-copied URL to your clipboard!]" > /dev/tty
            done
        )
    else
        if [[ "$TARGET" == "hs" ]]; then
            codex login
        else
            codex login --device-auth
        fi
    fi

    save_current "$TARGET"
    echo "✅ Login complete. Credentials backed up for $TARGET."
fi

# ── Push (if requested) ────────────────────────────────────────────────────────
[[ "$PUSH" == "true" ]] && push_all
