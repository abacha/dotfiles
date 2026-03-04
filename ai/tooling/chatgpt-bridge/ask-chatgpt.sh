#!/bin/bash
~/dotfiles/ai/tooling/chatgpt-bridge/send-win.sh "ChatGPT 5.2" "$1" | sed -n "/--- CHATGPT RESPONSE START ---/,/--- CHATGPT RESPONSE END ---/p" | sed "1d;\$d"

