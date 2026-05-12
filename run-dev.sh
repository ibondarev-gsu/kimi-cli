#!/usr/bin/env bash
# Run Kimi CLI from local source (dev mode)
# Usage: ./run-dev.sh [args...]
# Example: ./run-dev.sh login
# Example: ./run-dev.sh --print
# Example: ./run-dev.sh (no args = interactive shell)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

export PYTHONPATH="${PROJECT_ROOT}/patches:${PROJECT_ROOT}/src:${PYTHONPATH:-}"

# Route all traffic through the corporate dev proxy (localhost:8888 → Tinkoff NGFW).
# api.z.ai and internal tcsbank/tinkoff domains bypass the proxy.
export HTTP_PROXY="${HTTP_PROXY:-http://localhost:8888}"
export HTTPS_PROXY="${HTTPS_PROXY:-http://localhost:8888}"
export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1},api.z.ai,*.tcsbank.ru,tcsbank.ru,*.tinkoff.ru,tinkoff.ru"

# Auto-build web static if missing
if [ ! -d "src/kimi_cli/web/static" ]; then
    if command -v npm >/dev/null 2>&1; then
        echo "==> Web static not found, building..."
        uv run scripts/build_web.py
    else
        echo "Warning: src/kimi_cli/web/static is missing and npm is not available. Install Node.js to build the web UI." >&2
    fi
fi

# Run via uv with proxy patch pre-loaded
exec uv run python "${PROJECT_ROOT}/patches/kimi" "$@"
