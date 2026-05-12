#!/usr/bin/env pwsh
# Run Kimi CLI from local source (dev mode)
# Usage: .\run-dev.ps1 [args...]
# Example: .\run-dev.ps1 login
# Example: .\run-dev.ps1 --print
# Example: .\run-dev.ps1 (no args = interactive shell)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$OriginalPwd = Get-Location

# Check uv is installed
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Error "uv not found. Install it from https://docs.astral.sh/uv/"
    exit 1
}

# Verify project structure
if (-not (Test-Path (Join-Path $ProjectRoot "pyproject.toml"))) {
    Write-Error "pyproject.toml not found in $ProjectRoot"
    exit 1
}

if (-not (Test-Path (Join-Path $ProjectRoot "src\kimi_cli") -PathType Container)) {
    Write-Error "src\kimi_cli not found in $ProjectRoot"
    exit 1
}

Set-Location $ProjectRoot

$env:PYTHONPATH = "$ProjectRoot\patches;$ProjectRoot\src" + $(if ($env:PYTHONPATH) { ";$env:PYTHONPATH" } else { "" })

# Proxy setup — only if corporate proxy is reachable
$proxyReachable = $false
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("localhost", 8888)
    $proxyReachable = $tcp.Connected
    $tcp.Close()
} catch {
    $proxyReachable = $false
}

if ($proxyReachable) {
    $env:HTTP_PROXY = if ($env:HTTP_PROXY) { $env:HTTP_PROXY } else { "http://localhost:8888" }
    $env:HTTPS_PROXY = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { "http://localhost:8888" }
    $env:NO_PROXY = "$env:NO_PROXY,api.z.ai,*.tcsbank.ru,tcsbank.ru,*.tinkoff.ru,tinkoff.ru"
    Write-Host "==> Corporate proxy detected at localhost:8888"
} else {
    Write-Host "==> No corporate proxy detected, using direct connection"
}

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

# Detect if user already passed --work-dir or -w
$hasWorkDir = $false
foreach ($arg in $args) {
    if ($arg -eq "-w" -or $arg -eq "--work-dir") {
        $hasWorkDir = $true
        break
    }
}

if (-not $hasWorkDir) {
    uv run python "$ProjectRoot\patches\kimi" -w $OriginalPwd @args
} else {
    uv run python "$ProjectRoot\patches\kimi" @args
}
