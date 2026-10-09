# Run Flutter app in debug mode with dart-define env vars loaded from .env.local.
# Usage: .\tool\run_dev.ps1 [-Device <device-id>]
#
# Prerequisites:
#   1. Copy .env.example to .env.local and fill in TEST keys.
#   2. Never commit .env.local.

param(
    [string]$Device = ""
)

$envFile = Join-Path $PSScriptRoot "..\\.env.local"
if (-not (Test-Path $envFile)) {
    Write-Error ".env.local not found. Copy .env.example to .env.local and fill in your values."
    exit 1
}

$defines = @()
Get-Content $envFile | Where-Object { $_ -match "^[A-Z_]+=.+" } | ForEach-Object {
    $parts = $_ -split "=", 2
    $key   = $parts[0].Trim()
    $value = ($parts[1] -split "#")[0].Trim()  # strip inline comments
    if ($value -and $value -notmatch "REPLACE_ME") {
        $defines += "--dart-define=$key=$value"
    }
}

$deviceArg = if ($Device) { @("--device-id", $Device) } else { @() }

Write-Host "Starting Flutter with $($defines.Count) dart-defines..."
& flutter run @deviceArg @defines
