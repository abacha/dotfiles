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

# helper: check claude auth usage
check_claude_auth() {
    local creds_file="$1"
    local label="$2"
    
    if [ ! -f "$creds_file" ]; then return; fi
    
    local access_token
    local expires_at
    local email
    
    access_token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds_file")
    expires_at=$(jq -r '.claudeAiOauth.expiresAt // empty' "$creds_file")
    email=$(jq -r '.claudeAiOauth.email // empty' "$creds_file")
    
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

    if [ -n "$access_token" ] && [ "$access_token" != "null" ]; then
        local now_ms
        now_ms=$(($(date +%s) * 1000))

        # Check if expired (or expiring in next 60s)
        if [ -n "$expires_at" ] && [ "$now_ms" -gt "$((expires_at - 60000))" ]; then
            # Temporarily link to default for cli refresh if needed
            local temp_swap=0
            if [ "$creds_file" != "$HOME/.claude/.credentials.json" ]; then
                cp "$creds_file" "$HOME/.claude/.credentials.json.tmp_tracker" 2>/dev/null || true
                cp "$HOME/.claude/.credentials.json" "$HOME/.claude/.credentials.json.backup_tracker" 2>/dev/null || true
                cp "$creds_file" "$HOME/.claude/.credentials.json" 2>/dev/null || true
                temp_swap=1
            fi

            export PATH=/home/abacha/.asdf/installs/nodejs/25.7.0/bin:$PATH
            if command -v claude >/dev/null 2>&1; then
                echo "2+2" | claude >/dev/null 2>&1 || true
                # Re-read token
                access_token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json")
            else
                echo "   ❌ OAuth token expired and 'claude' CLI not found. Cannot auto-refresh."
            fi

            if [ "$temp_swap" -eq 1 ]; then
                mv "$HOME/.claude/.credentials.json.backup_tracker" "$HOME/.claude/.credentials.json" 2>/dev/null || true
                rm -f "$HOME/.claude/.credentials.json.tmp_tracker" 2>/dev/null || true
                # save refreshed token back to original file if refreshed
                # for now, if it refreshed it updated the default file, we should copy it back
                # actually, this is a bit complex for a read-only script, but we can try to update the token locally.
            fi
        fi
        
        if [ -z "$access_token" ] || [ "$access_token" = "null" ]; then
            echo "   ❌ Failed to get a valid OAuth access token."
            return
        fi

        # Call the hidden OAuth Usage API
        local usage
        usage=$(curl -s -H "Authorization: Bearer $access_token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            https://api.anthropic.com/api/oauth/usage)

        local error_msg
        error_msg=$(echo "$usage" | jq -r '.error.message // empty')
        if [ -n "$error_msg" ]; then
            echo "   ❌ API Error: $error_msg"
            if echo "$error_msg" | grep -q "user:profile"; then
                echo "   💡 Tip: Your token lacks the 'user:profile' scope. Generate a new token or run 'claude login'."
            elif echo "$error_msg" | grep -q "expired"; then
                echo "   💡 Tip: Your OAuth token has expired. Run 'claude login' to get a fresh token."
            fi
        else
            local five_pct
            five_pct=$(echo "$usage" | jq -r '.five_hour.utilization // 0' | cut -d. -f1)
            local five_reset
            five_reset=$(echo "$usage" | jq -r '.five_hour.resets_at // "N/A"')
            local week_pct
            week_pct=$(echo "$usage" | jq -r '.seven_day.utilization // 0' | cut -d. -f1)
            local week_reset
            week_reset=$(echo "$usage" | jq -r '.seven_day.resets_at // "N/A"')

            [ "$five_pct" = "null" ] && five_pct=0
            [ "$week_pct" = "null" ] && week_pct=0

            if [ "$week_pct" -ge 100 ]; then
                five_pct=100
                five_reset="$week_reset"
            fi

            local five_left
            five_left=$(format_date_and_time "$five_reset")
            local week_left
            week_left=$(format_date_and_time "$week_reset")

            printf "   ⏱️  %-15s %s %s %3d%%  (Resets in: %s)\n" "Session (5h):" "$(status_emoji "$five_pct")" "$(draw_bar "$five_pct")" "$five_pct" "$five_left"
            printf "   📅  %-15s %s %s %3d%%  (Resets in: %s)\n" "Weekly (7d):" "$(status_emoji "$week_pct")" "$(draw_bar "$week_pct")" "$week_pct" "$week_left"
        fi
    else
        echo "   ❌ No OAuth access token found."
    fi
}

# ==================== CLAUDE CODE ====================
if [ "$ONLY_CLAUDE" = "1" ]; then
echo "=== 🦞 Claude Code (OAuth) ==="

# If there are specific credentials files (like codex)
if [ -f "$HOME/.claude/.credentials-hs.json" ] || [ -f "$HOME/.claude/.credentials-personal.json" ]; then
    if [ -f "$HOME/.claude/.credentials-hs.json" ]; then
        check_claude_auth "$HOME/.claude/.credentials-hs.json" "Hubstaff"
        echo ""
    fi
    if [ -f "$HOME/.claude/.credentials-personal.json" ]; then
        check_claude_auth "$HOME/.claude/.credentials-personal.json" "Personal"
    fi
else
    # Check environment variable first
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        ACCESS_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN"
        # Manually perform what check_claude_auth does if we are using env var directly
        # For simplicity, we just check the token
        USAGE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "anthropic-beta: oauth-2025-04-20" \
            https://api.anthropic.com/api/oauth/usage)

        ERROR_MSG=$(echo "$USAGE" | jq -r '.error.message // empty')
        if [ -n "$ERROR_MSG" ]; then
            echo "   ❌ API Error: $ERROR_MSG"
        else
            FIVE_PCT=$(echo "$USAGE" | jq -r '.five_hour.utilization // 0' | cut -d. -f1)
            FIVE_RESET=$(echo "$USAGE" | jq -r '.five_hour.resets_at // "N/A"')
            WEEK_PCT=$(echo "$USAGE" | jq -r '.seven_day.utilization // 0' | cut -d. -f1)
            WEEK_RESET=$(echo "$USAGE" | jq -r '.seven_day.resets_at // "N/A"')

            [ "$FIVE_PCT" = "null" ] && FIVE_PCT=0
            [ "$WEEK_PCT" = "null" ] && WEEK_PCT=0

            if [ "$WEEK_PCT" -ge 100 ]; then
                FIVE_PCT=100
                FIVE_RESET="$WEEK_RESET"
            fi

            FIVE_LEFT=$(format_date_and_time "$FIVE_RESET")
            WEEK_LEFT=$(format_date_and_time "$WEEK_RESET")

            printf "   ⏱️  %-15s %s %s %3d%%  (Resets in: %s)\n" "Session (5h):" "$(status_emoji $FIVE_PCT)" "$(draw_bar $FIVE_PCT)" "$FIVE_PCT" "$FIVE_LEFT"
            printf "   📅  %-15s %s %s %3d%%  (Resets in: %s)\n" "Weekly (7d):" "$(status_emoji $WEEK_PCT)" "$(draw_bar $WEEK_PCT)" "$WEEK_PCT" "$WEEK_LEFT"
        fi
    else
        CREDS_FILE="$HOME/.claude/.credentials.json"
        if [ ! -f "$CREDS_FILE" ]; then
            echo "❌ No credentials found at $CREDS_FILE"
        else
            check_claude_auth "$CREDS_FILE" "Active"
        fi
    fi
fi
echo ""
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
