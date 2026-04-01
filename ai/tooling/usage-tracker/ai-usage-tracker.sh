#!/bin/bash
# ai-usage-tracker.sh
# A shell script equivalent of CodexBar for tracking Claude Code and OpenAI Codex usage.
# - Fetches the 5-hour and 7-day windows directly from Anthropic's OAuth API.
# - Safely refreshes Claude's OAuth token by invoking the CLI directly.
# - Parses ~/.codex/auth.json for OpenAI.
#
# Requires: curl, jq, date

set -e

CACHE_TTL=300 # 5 minutes

# Make common user-level CLI locations available even in non-login shells.
export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"

FRESH=0
ONLY_CLAUDE=0
ONLY_CODEX=0
IS_REAL_RUN=0

for arg in "$@"; do
    case $arg in
        --fresh) FRESH=1 ;;
        --claude) ONLY_CLAUDE=1 ;;
        --codex) ONLY_CODEX=1 ;;
        --real-run) IS_REAL_RUN=1 ;;
    esac
done

if [ "$ONLY_CLAUDE" = "0" ] && [ "$ONLY_CODEX" = "0" ]; then
    ONLY_CLAUDE=1
    ONLY_CODEX=1
fi

CACHE_PREFIX="ai-usage-tracker"
if [ "$ONLY_CLAUDE" = "1" ] && [ "$ONLY_CODEX" = "0" ]; then CACHE_PREFIX="ai-usage-tracker-claude"; fi
if [ "$ONLY_CODEX" = "1" ] && [ "$ONLY_CLAUDE" = "0" ]; then CACHE_PREFIX="ai-usage-tracker-codex"; fi
CACHE_FILE="/tmp/${CACHE_PREFIX}-cache.txt"

if [ "$IS_REAL_RUN" = "0" ]; then
    if [ "$FRESH" = "1" ]; then
        rm -f "$CACHE_FILE"
    elif [ -f "$CACHE_FILE" ]; then
        NOW=$(date +%s)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            CACHE_MOD=$(stat -f "%m" "$CACHE_FILE" 2>/dev/null || echo 0)
        else
            CACHE_MOD=$(stat -c "%Y" "$CACHE_FILE" 2>/dev/null || echo 0)
        fi
        AGE=$((NOW - CACHE_MOD))
        if [ "$AGE" -ge 0 ] && [ "$AGE" -lt "$CACHE_TTL" ]; then
            cat "$CACHE_FILE"
            echo ""
            echo "💡 (Cached ${AGE}s ago. Run with --fresh to bypass)"
            exit 0
        fi
    fi

    "$0" "$@" --real-run | tee "$CACHE_FILE"
    exit ${PIPESTATUS[0]}
fi

# helper: draw a 10-char progress bar
draw_bar() {
    local pct=${1:-0}
    local filled=$((pct / 10))
    local empty=$((10 - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

# helper: emoji per percentage
status_emoji() {
    local pct=${1:-0}
    if [ "$pct" -gt 80 ]; then
        echo "🔴"
    elif [ "$pct" -gt 50 ]; then
        echo "🟡"
    else
        echo "🟢"
    fi
}

# helper: human-friendly remaining time (expects ISO timestamp with timezone)
format_date_and_time() {
    local dt="$1"
    if [ -z "$dt" ] || [ "$dt" = "null" ] || [ "$dt" = "N/A" ]; then
        echo "unknown"
        return
    fi
    if ! command -v date >/dev/null 2>&1; then
        echo "unknown"
        return
    fi

    local ts=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local clean_dt="${dt%Z}"
        ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean_dt" +%s 2>/dev/null || echo 0)
    else
        ts=$(date -d "$dt" +%s 2>/dev/null || echo 0)
    fi

    if [ "$ts" -le 0 ]; then
        echo "unknown"
        return
    fi

    local now=$(date +%s)
    local diff=$((ts - now))
    if [ "$diff" -lt 0 ]; then
        diff=0
    fi

    local days=$((diff / 86400))
    local hours=$(((diff % 86400) / 3600))
    local mins=$(((diff % 3600) / 60))

    if [ "$days" -gt 0 ]; then
        echo "${days}d ${hours}h"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}h ${mins}m"
    else
        echo "${mins}m"
    fi
}

# helper: format ISO timestamps for display
format_iso_timestamp_local() {
    local ts="$1"
    if [ -z "$ts" ] || [ "$ts" = "null" ]; then
        echo "unknown"
        return
    fi
    if ! command -v date >/dev/null 2>&1; then
        echo "$ts"
        return
    fi

    local sanitized="$ts"
    if [[ "$sanitized" == *.*Z ]]; then
        sanitized="${sanitized%%.*}Z"
    fi

    local formatted
    if [[ "$OSTYPE" == "darwin"* ]]; then
        formatted=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$sanitized" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null ||                    date -j -f "%Y-%m-%dT%H:%M:%S%z" "$sanitized" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "$ts")
    else
        formatted=$(date -d "$ts" "+%Y-%m-%d %H:%M:%S %Z" 2>/dev/null || echo "$ts")
    fi

    echo "$formatted"
}

# helper: shorten large token counts
format_tokens_short() {
    local value="$1"
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "0"
        return
    fi
    awk -v val="$value" 'BEGIN {
        if (val >= 1e9) { printf "%.1fB", val / 1e9 }
        else if (val >= 1e6) { printf "%.1fM", val / 1e6 }
        else if (val >= 1e3) { printf "%.1fk", val / 1e3 }
        else { printf "%.0f", val }
    }'
}

# helper: format costs with two decimals
format_cost_value() {
    local value="$1"
    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo ""
        return
    fi
    printf "%.2f" "$value"
}

# ==================== CLAUDE CODE ====================
if [ "$ONLY_CLAUDE" = "1" ]; then
# Check environment variable first
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    ACCESS_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
else
    CREDS_FILE="$HOME/.claude/.credentials.json"
    if [ ! -f "$CREDS_FILE" ]; then
        echo "❌ No credentials found. Are you logged in to Claude CLI?"
    else
        # Read the access token and expiration time
        ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE")
        EXPIRES_AT=$(jq -r '.claudeAiOauth.expiresAt // empty' "$CREDS_FILE")

        if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
            NOW_MS=$(($(date +%s) * 1000))

            # Check if expired (or expiring in next 60s)
            if [ -n "$EXPIRES_AT" ] && [ "$NOW_MS" -gt "$((EXPIRES_AT - 60000))" ]; then
                # Trigger official CLI to handle the refresh safely (requires node 22+)
                export PATH=/home/abacha/.asdf/installs/nodejs/25.7.0/bin:$PATH
                if command -v claude >/dev/null 2>&1; then
                    echo "2+2" | claude >/dev/null 2>&1 || true
                    # Re-read token
                    ACCESS_TOKEN=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS_FILE")
                else
                    echo "❌ OAuth token expired and 'claude' CLI not found. Cannot auto-refresh."
                    exit 1
                fi
            fi
        fi
    fi
fi

if [ -n "$ACCESS_TOKEN" ] && [ "$ACCESS_TOKEN" != "null" ]; then
    # Call the hidden OAuth Usage API
    USAGE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "anthropic-beta: oauth-2025-04-20" \
        https://api.anthropic.com/api/oauth/usage)

    ERROR_MSG=$(echo "$USAGE" | jq -r '.error.message // empty')
    if [ -n "$ERROR_MSG" ]; then
        echo "❌ API Error: $ERROR_MSG"
        if echo "$ERROR_MSG" | grep -q "user:profile"; then
            echo "💡 Tip: Your token in CLAUDE_CODE_OAUTH_TOKEN lacks the 'user:profile' scope."
            echo "   You can either generate a new token with this scope, or run 'claude login'."
        elif echo "$ERROR_MSG" | grep -q "expired"; then
            echo "💡 Tip: Your OAuth token has expired. Run 'claude login' to get a fresh token."
        fi
    else
        FIVE_PCT=$(echo "$USAGE" | jq -r '.five_hour.utilization // 0' | cut -d. -f1)
        FIVE_RESET=$(echo "$USAGE" | jq -r '.five_hour.resets_at // "N/A"')
        WEEK_PCT=$(echo "$USAGE" | jq -r '.seven_day.utilization // 0' | cut -d. -f1)
        WEEK_RESET=$(echo "$USAGE" | jq -r '.seven_day.resets_at // "N/A"')

        # Handle null values
        [ "$FIVE_PCT" = "null" ] && FIVE_PCT=0
        [ "$WEEK_PCT" = "null" ] && WEEK_PCT=0

        # If weekly is maxed out, session is effectively maxed out too
        if [ "$WEEK_PCT" -ge 100 ]; then
            FIVE_PCT=100
            FIVE_RESET="$WEEK_RESET"
        fi

        FIVE_LEFT=$(format_date_and_time "$FIVE_RESET")
        WEEK_LEFT=$(format_date_and_time "$WEEK_RESET")

        echo "=== 🦞 Claude Code ==="
        printf "⏱️  %-15s %s %s %3d%%  (Resets in: %s)\n" "Session (5h):" "$(status_emoji $FIVE_PCT)" "$(draw_bar $FIVE_PCT)" "$FIVE_PCT" "$FIVE_LEFT"
        printf "📅  %-15s %s %s %3d%%  (Resets in: %s)\n" "Weekly (7d):" "$(status_emoji $WEEK_PCT)" "$(draw_bar $WEEK_PCT)" "$WEEK_PCT" "$WEEK_LEFT"
        echo ""
    fi
else
    echo "❌ No access token found. Are you using an API Key instead of OAuth?"
    echo "Note: API Keys don't have a 5-hour/7-day window."
fi
fi

# helper: check codex auth usage
check_codex_auth() {
    local auth_file="$1"
    local label="$2"
    
    if [ ! -f "$auth_file" ]; then return; fi
    
    local auth_mode
    auth_mode=$(jq -r '.auth_mode // empty' "$auth_file")
    
    local email=""
    local id_token
    id_token=$(jq -r '.tokens.id_token // empty' "$auth_file")
    if [ -n "$id_token" ] && [ "$id_token" != "null" ]; then
        # very dirty JWT decode of the payload (middle segment)
        local payload
        payload=$(echo "$id_token" | cut -d. -f2 | tr '_-' '/+')
        # add padding if needed
        local padding=$((${#payload} % 4))
        if [ $padding -eq 2 ]; then payload="${payload}=="; elif [ $padding -eq 3 ]; then payload="${payload}="; fi
        email=$(echo "$payload" | base64 -d 2>/dev/null | jq -r '.email // empty' 2>/dev/null || true)
    fi

    if [ -n "$label" ]; then
        if [ -n "$email" ]; then
            echo "   [$label] ($email)"
        else
            echo "   [$label]"
        fi
    else
        if [ -n "$email" ]; then
            echo "   ($email)"
        fi
    fi

    if [ "$auth_mode" = "apikey" ]; then
        echo "   💳 Account: Pay-as-you-go (API Key)"
        return
    fi

    local codexbar_bin
    codexbar_bin=$(command -v codexbar || true)
    if [ -z "$codexbar_bin" ]; then
        echo "   Info   : Install CodexBar CLI (https://github.com/steipete/codexbar) to surface locally tracked usage metrics."
        return
    fi

    # temporarily link auth.json to the target file so codexbar reads it
    local temp_swap=0
    if [ "$auth_file" != "$HOME/.codex/auth.json" ]; then
        cp "$auth_file" "$HOME/.codex/auth.json.tmp_tracker" 2>/dev/null || true
        cp "$HOME/.codex/auth.json" "$HOME/.codex/auth.json.backup_tracker" 2>/dev/null || true
        cp "$auth_file" "$HOME/.codex/auth.json" 2>/dev/null || true
        temp_swap=1
    fi

    local usage_output
    usage_output=$("$codexbar_bin" usage --provider codex --format json 2>&1 || true)
    
    if [ "$temp_swap" -eq 1 ]; then
        mv "$HOME/.codex/auth.json.backup_tracker" "$HOME/.codex/auth.json" 2>/dev/null || true
        rm -f "$HOME/.codex/auth.json.tmp_tracker" 2>/dev/null || true
    fi

    if [ -n "$usage_output" ] && echo "$usage_output" | jq -e '.[0].usage' >/dev/null 2>&1; then
        local primary_pct
        primary_pct=$(echo "$usage_output" | jq -r '.[0].usage.primary.usedPercent // empty')
        local primary_resets
        primary_resets=$(echo "$usage_output" | jq -r '.[0].usage.primary.resetsAt // empty')

        local secondary_pct
        secondary_pct=$(echo "$usage_output" | jq -r '.[0].usage.secondary.usedPercent // empty')
        local secondary_resets
        secondary_resets=$(echo "$usage_output" | jq -r '.[0].usage.secondary.resetsAt // empty')

        if [ -n "$primary_pct" ] && [ "$primary_pct" != "null" ]; then
            printf "   ⏱️  %-15s %s %s %3d%%  (Resets in: %s)\n" "Session (5h):" "$(status_emoji "$primary_pct")" "$(draw_bar "$primary_pct")" "$primary_pct" "$(format_date_and_time "$primary_resets")"
        fi
        if [ -n "$secondary_pct" ] && [ "$secondary_pct" != "null" ]; then
            printf "   📅  %-15s %s %s %3d%%  (Resets in: %s)\n" "Weekly (7d):" "$(status_emoji "$secondary_pct")" "$(draw_bar "$secondary_pct")" "$secondary_pct" "$(format_date_and_time "$secondary_resets")"
        fi
    else
        echo "   Info   : Could not fetch usage limits."
    fi
}

# ==================== OPENAI CODEX ====================
if [ "$ONLY_CODEX" = "1" ]; then
if [ "$ONLY_CLAUDE" = "1" ]; then echo ""; fi
echo "=== 🤖 OpenAI Codex ==="

if [ -f "$HOME/.codex/auth-hs.json" ] || [ -f "$HOME/.codex/auth-personal.json" ]; then
    if [ -f "$HOME/.codex/auth-hs.json" ]; then
        check_codex_auth "$HOME/.codex/auth-hs.json" "Hubstaff"
        echo ""
    fi
    if [ -f "$HOME/.codex/auth-personal.json" ]; then
        check_codex_auth "$HOME/.codex/auth-personal.json" "Personal"
    fi
else
    # Fallback to default if no specific files exist
    if [ ! -f "$HOME/.codex/auth.json" ]; then
        echo "❌ No Codex credentials found at $HOME/.codex/auth.json"
    else
        check_codex_auth "$HOME/.codex/auth.json" "Active"
    fi
fi

fi
