param(
  [ValidateSet('login','send')][string]$Mode = 'send',
  [string]$Chat,
  [string]$Message
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

if (!(Test-Path .env)) {
  Copy-Item .env.example .env
}

if (!(Test-Path node_modules)) {
  npm install | Out-Null
}

$profileRoot = Join-Path $env:LOCALAPPDATA "chatgpt-bridge"
if (!(Test-Path $profileRoot)) {
  New-Item -ItemType Directory -Path $profileRoot | Out-Null
}
$env:CHATGPT_BRIDGE_PROFILE_DIR = (Join-Path $profileRoot "chrome-profile")

$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
  $nodeExe = $nodeCmd.Source
} else {
  $candidates = @(
    "$env:ProgramFiles\nodejs\node.exe",
    "$env:LOCALAPPDATA\Programs\nodejs\node.exe",
    "$env:APPDATA\npm\node.exe"
  )
  $nodeExe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $nodeExe) { throw "Node not found on Windows PATH or common install paths." }

$chromeCandidates = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
)
$chromeExe = $chromeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chromeExe) { throw "Chrome not found in standard install paths." }

$cdpUrl = 'http://127.0.0.1:9222'

function Test-CdpUp {
  try {
    Invoke-WebRequest -UseBasicParsing "$cdpUrl/json/version" -TimeoutSec 2 | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Ensure-DebugChrome {
  if (Test-CdpUp) { return }

  Start-Process -FilePath $chromeExe -ArgumentList @(
    "--user-data-dir=$env:CHATGPT_BRIDGE_PROFILE_DIR",
    "--remote-debugging-port=9222",
    "--remote-debugging-address=127.0.0.1",
    "--new-window",
    "https://chatgpt.com"
  ) | Out-Null

  for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Seconds 1
    if (Test-CdpUp) { return }
  }

  throw "Chrome CDP endpoint did not come up on $cdpUrl. Close Chrome and run login-win.sh again."
}

if ($Mode -eq 'login') {
  Ensure-DebugChrome
  Write-Host "Chrome ready for login with profile: $env:CHATGPT_BRIDGE_PROFILE_DIR"
  Write-Host "CDP endpoint: $cdpUrl"
  Write-Host "Log in once, keep Chrome open, then run send-win.sh."
  exit 0
}

if ([string]::IsNullOrWhiteSpace($Chat) -or [string]::IsNullOrWhiteSpace($Message)) {
  throw "For send mode, provide -Chat and -Message."
}

Ensure-DebugChrome
$env:CHATGPT_BRIDGE_CDP_URL = $cdpUrl
& $nodeExe .\bridge.mjs send --chat "$Chat" --message "$Message"
exit $LASTEXITCODE
