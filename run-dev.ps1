#!/usr/bin/env pwsh
# Run Kimi CLI from local source (dev mode)
# Usage: .\run-dev.ps1 [args...]
# Example: .\run-dev.ps1 login
# Example: .\run-dev.ps1 --print
# Example: .\run-dev.ps1 (no args = interactive shell)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ProjectRoot

$env:PYTHONPATH = "$ProjectRoot\patches;$ProjectRoot\src"

# api.z.ai must bypass the proxy (direct connection via Tinkoff NGFW).
$env:NO_PROXY = "$env:NO_PROXY,api.z.ai"

# Auto-build web static if missing
$staticDir = Join-Path $ProjectRoot "src\kimi_cli\web\static"
if (-not (Test-Path $staticDir)) {
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if ($npm) {
        Write-Host "==> Web static not found, building..."
        uv run scripts/build_web.py
    } else {
        Write-Warning "src/kimi_cli/web/static is missing and npm is not available. Install Node.js to build the web UI."
    }
}

# Run via uv with proxy patch pre-loaded
uv run python "$ProjectRoot\patches\kimi" @args
