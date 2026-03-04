# ChatGPT Bridge (almost headless)

Automates ChatGPT web from your local machine using a persistent Chrome profile.

## Setup
```bash
cd ~/dotfiles/ai/tooling/chatgpt-bridge
./setup.sh
```

## First run
```bash
node bridge.mjs send --chat "Some chat title" --message "hello"
```
- A Chrome window opens minimized style (`--start-minimized`).
- If not logged in, log in once, then re-run the command.
- Session persists in `./.profile`.

## Usage
```bash
node bridge.mjs send --chat "Project X" --message "Summarize latest plan"
node bridge.mjs send --chat "Project X" --message "Give raw response" --raw
```

## Windows-native path (recommended when WSL networking blocks CDP)
From WSL:
```bash
# 1) login once (persists in Windows local profile)
./login-win.sh

# 2) send to a specific chat title
./send-win.sh "Receita de Muhammara" "teste"
```

This runs Playwright + browser automation on Windows PowerShell side, avoiding WSL->CDP networking.

## WSL workaround (recommended)
If WSL browser UI is weird, use your normal Windows Chrome and connect via CDP.

1) On Windows, start Chrome with remote debugging:
```powershell
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 https://chatgpt.com
```

2) In `~/dotfiles/ai/tooling/chatgpt-bridge/.env`, set:
```env
CHATGPT_BRIDGE_CDP_URL=http://127.0.0.1:9222
```

3) Run bridge command again from WSL.

## Notes
- This is UI automation; selectors can break when ChatGPT UI changes.
- Keep chat titles distinctive for reliable matching.
- If matching fails, rename the chat to a unique name.
