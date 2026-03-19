#!/bin/bash
# ai-usage-tracker.sh
# A shell script equivalent of CodexBar for tracking Claude Code and OpenAI Codex usage.
# - Fetches the 5-hour and 7-day windows directly from Anthropic's OAuth API.
# - Safely refreshes Claude's OAuth token by invoking the CLI directly.
# - Parses ~/.codex/auth.json for OpenAI.
#
# Requires: curl, jq, date

set -e

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
echo "=== Claude Code Usage ==="

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

        echo "🦞 Claude Code Usage"
        echo ""
        echo "⏱️  Session (5h): $(status_emoji $FIVE_PCT) $(draw_bar $FIVE_PCT) ${FIVE_PCT}%"
        echo "   Resets in: $FIVE_LEFT"
        echo ""
        echo "📅 Weekly (7d): $(status_emoji $WEEK_PCT) $(draw_bar $WEEK_PCT) ${WEEK_PCT}%"
        echo "   Resets in: $WEEK_LEFT"
    fi
else
    echo "❌ No access token found. Are you using an API Key instead of OAuth?"
    echo "Note: API Keys don't have a 5-hour/7-day window."
fi

echo ""
# ==================== OPENAI CODEX ====================
echo "=== OpenAI Codex Usage ==="
echo "🤖 OpenAI Codex"
echo ""
CODEX_AUTH="$HOME/.codex/auth.json"
if [ ! -f "$CODEX_AUTH" ]; then
    echo "❌ No Codex credentials found at $CODEX_AUTH"
else
    AUTH_MODE=$(jq -r '.auth_mode // empty' "$CODEX_AUTH")
    if [ "$AUTH_MODE" = "apikey" ]; then
        echo "💳 Account: Pay-as-you-go (API Key)"
        echo "📊 Session: 🟢 ██████████ [Unlimited]"
        echo "📅 Weekly : 🟢 ██████████ [Unlimited]"
        echo "   Info   : API keys are billed per-token without session quotas."
    else
        echo "💳 Account: Web/OAuth Token"
        echo "   Info   : Web token parsing relies on official CodexBar CLI."
    fi

    # Read model from local config if available
    if [ -f "$HOME/.codex/config.toml" ]; then
        CODEX_MODEL=$(grep -E '^model[[:space:]]*=' "$HOME/.codex/config.toml" | head -n1 | cut -d'"' -f2)
        if [ -n "$CODEX_MODEL" ]; then
            echo "🧠 Model  : $CODEX_MODEL"
        fi
    fi

    CODEXBAR_BIN=$(command -v codexbar || true)
    if [ -n "$CODEXBAR_BIN" ]; then
        # Check usage limits if we aren't using an apikey
        if [ "$AUTH_MODE" != "apikey" ]; then
            USAGE_OUTPUT=$("$CODEXBAR_BIN" usage --provider codex --format json 2>/dev/null || true)
            if [ -n "$USAGE_OUTPUT" ] && echo "$USAGE_OUTPUT" | jq -e '.[0].usage' >/dev/null 2>&1; then
                PRIMARY_PCT=$(echo "$USAGE_OUTPUT" | jq -r '.[0].usage.primary.usedPercent // empty')
                PRIMARY_RESETS=$(echo "$USAGE_OUTPUT" | jq -r '.[0].usage.primary.resetsAt // empty')
                
                SECONDARY_PCT=$(echo "$USAGE_OUTPUT" | jq -r '.[0].usage.secondary.usedPercent // empty')
                SECONDARY_RESETS=$(echo "$USAGE_OUTPUT" | jq -r '.[0].usage.secondary.resetsAt // empty')
                
                if [ -n "$PRIMARY_PCT" ] && [ "$PRIMARY_PCT" != "null" ]; then
                    echo "⏱️  Session (5h): $(status_emoji "$PRIMARY_PCT") $(draw_bar "$PRIMARY_PCT") ${PRIMARY_PCT}%"
                    echo "   Resets in: $(format_date_and_time "$PRIMARY_RESETS")"
                fi
                if [ -n "$SECONDARY_PCT" ] && [ "$SECONDARY_PCT" != "null" ]; then
                    echo "📅 Weekly (7d): $(status_emoji "$SECONDARY_PCT") $(draw_bar "$SECONDARY_PCT") ${SECONDARY_PCT}%"
                    echo "   Resets in: $(format_date_and_time "$SECONDARY_RESETS")"
                fi
            else
                echo "   Info   : Could not fetch usage limits from CodexBar."
            fi
        fi

        COST_OUTPUT=$("$CODEXBAR_BIN" cost --format json --provider codex 2>/dev/null || true)
        if [ -n "$COST_OUTPUT" ] && echo "$COST_OUTPUT" | jq -e . >/dev/null 2>&1; then
            TOTAL_COST=$(echo "$COST_OUTPUT" | jq -r '.[0].totals.totalCost // empty')
            TOTAL_TOKENS=$(echo "$COST_OUTPUT" | jq -r '.[0].totals.totalTokens // empty')
            SESSION_TOKENS=$(echo "$COST_OUTPUT" | jq -r '.[0].sessionTokens // empty')
            LAST30_TOKENS=$(echo "$COST_OUTPUT" | jq -r '.[0].last30DaysTokens // empty')
            LAST30_COST=$(echo "$COST_OUTPUT" | jq -r '.[0].last30DaysCostUSD // empty')
            UPDATED_AT=$(echo "$COST_OUTPUT" | jq -r '.[0].updatedAt // empty')
            SOURCE=$(echo "$COST_OUTPUT" | jq -r '.[0].source // empty')
            SOURCE=${SOURCE:-local}
            echo "   ⚙️ CodexBar metrics (source: $SOURCE)"
            LATEST_DAY_JSON=$(echo "$COST_OUTPUT" | jq -c '.[0].daily | (if length > 0 then .[-1] else {} end)')
            LAST_DAY_DATE=$(echo "$LATEST_DAY_JSON" | jq -r '.date // empty')
            LAST_DAY_TOKENS=$(echo "$LATEST_DAY_JSON" | jq -r '(.totalTokens // (.inputTokens + .outputTokens) // empty)')
            LAST_DAY_COST=$(echo "$LATEST_DAY_JSON" | jq -r '.totalCost // empty')
            LAST_DAY_MODELS=$(echo "$LATEST_DAY_JSON" | jq -r '[.modelBreakdowns[]?.modelName] | unique | join(", ") // empty')

            [ -z "$TOTAL_TOKENS" ] && TOTAL_TOKENS="$LAST30_TOKENS"
            [ -z "$TOTAL_COST" ] && TOTAL_COST="$LAST30_COST"

            totals_desc=""
            if [ -n "$TOTAL_TOKENS" ]; then
                totals_desc="$(format_tokens_short "$TOTAL_TOKENS") tokens"
            fi
            if [ -n "$TOTAL_COST" ]; then
                totals_desc="${totals_desc:+$totals_desc }\$$(format_cost_value "$TOTAL_COST")"
            fi
            if [ -n "$totals_desc" ]; then
                echo "   Totals (tracked): $totals_desc"
            fi

            last30_desc=""
            if [ -n "$LAST30_TOKENS" ]; then
                last30_desc="$(format_tokens_short "$LAST30_TOKENS") tokens"
            fi
            if [ -n "$LAST30_COST" ]; then
                last30_desc="${last30_desc:+$last30_desc }\$$(format_cost_value "$LAST30_COST")"
            fi
            if [ -n "$last30_desc" ]; then
                echo "   Last 30d: $last30_desc"
            fi

            if [ -n "$SESSION_TOKENS" ]; then
                echo "   Session tokens: $(format_tokens_short "$SESSION_TOKENS")"
            fi

            if [ -n "$UPDATED_AT" ]; then
                echo "   Updated: $(format_iso_timestamp_local "$UPDATED_AT") (source: $SOURCE)"
            fi

            if [ -n "$LAST_DAY_DATE" ]; then
                day_cost="n/a"
                if [ -n "$LAST_DAY_COST" ]; then
                    day_cost="\$$(format_cost_value "$LAST_DAY_COST")"
                fi
                day_models=""
                if [ -n "$LAST_DAY_MODELS" ]; then
                    day_models=" (models: $LAST_DAY_MODELS)"
                fi
                echo "   Most recent day ($LAST_DAY_DATE): $(format_tokens_short "$LAST_DAY_TOKENS") tokens, cost $day_cost$day_models"
            fi
        else
            echo "   Info   : CodexBar cost output was invalid or empty."
        fi
    else
        echo "   Info   : Install CodexBar CLI (https://github.com/steipete/codexbar) to surface locally tracked usage metrics."
    fi

fi
