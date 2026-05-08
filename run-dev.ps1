#!/usr/bin/env pwsh
# Run Kimi CLI from local source (dev mode)
# Usage: .\run-dev.ps1 [args...]
# Example: .\run-dev.ps1 login
# Example: .\run-dev.ps1 --print
# Example: .\run-dev.ps1 (no args = interactive shell)

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ProjectRoot

$env:PYTHONPATH = "$ProjectRoot\src"

# Run via uv
uv run python -m kimi_cli @args
