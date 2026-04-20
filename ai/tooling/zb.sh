#!/bin/bash

# Zoxide-style branch jumper (zb)
# Usage: zb <query>

QUERY=$1

# 1. Get all local branches, sorted by most recent commit
# We strip the '*' from current branch and whitespace
BRANCHES=$(git branch --sort=-committerdate | sed 's/^[* ]*//')

if [ -z "$QUERY" ]; then
    # No query: Show interactive fzf selector
    if [ -t 1 ]; then
        # Interactive TTY
        SELECTED=$(echo "$BRANCHES" | fzf --height 40% --reverse --prompt="Jump to branch > ")
        if [ -n "$SELECTED" ]; then
            git checkout "$SELECTED"
        fi
    else
        # Non-interactive: just list branches
        echo "$BRANCHES"
    fi
    exit 0
fi

# 2. Try exact match first
if echo "$BRANCHES" | grep -qx "$QUERY"; then
    git checkout "$QUERY"
    exit 0
fi

# 3. Try fuzzy/substring match
MATCHES=$(echo "$BRANCHES" | grep -i "$QUERY")
MATCH_COUNT=$(echo "$MATCHES" | grep -c .)

if [ "$MATCH_COUNT" -eq 1 ]; then
    # Single match: jump immediately
    git checkout "$MATCHES"
elif [ "$MATCH_COUNT" -gt 1 ]; then
    # Multiple matches: use fzf to disambiguate if interactive, or list them
    if [ -t 1 ]; then
        SELECTED=$(echo "$MATCHES" | fzf --height 40% --reverse --query="$QUERY" --select-1 --prompt="Multiple matches for '$QUERY' > ")
        if [ -n "$SELECTED" ]; then
            git checkout "$SELECTED"
        fi
    else
        echo "Multiple matches found for '$QUERY':"
        echo "$MATCHES"
    fi
else
    echo "No branch matches '$QUERY'."
    exit 1
fi
