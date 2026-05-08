#!/usr/bin/env bash
# Run Kimi CLI from local source (dev mode)
# Usage: ./run-dev.sh [args...]
# Example: ./run-dev.sh login
# Example: ./run-dev.sh --print
# Example: ./run-dev.sh (no args = interactive shell)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

export PYTHONPATH="${PROJECT_ROOT}/src:${PYTHONPATH:-}"

# Run via uv
exec uv run python -m kimi_cli "$@"
