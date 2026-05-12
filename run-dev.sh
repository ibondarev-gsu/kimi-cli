#!/usr/bin/env bash
# Run Kimi CLI from local source (dev mode)
# Usage: ./run-dev.sh [args...]
# Example: ./run-dev.sh login
# Example: ./run-dev.sh --print
# Example: ./run-dev.sh (no args = interactive shell)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
ORIGINAL_PWD="$PWD"

# Check uv is installed
if ! command -v uv &> /dev/null; then
    echo "ERROR: uv not found. Install it from https://docs.astral.sh/uv/" >&2
    exit 1
fi

# Verify project structure
if [ ! -f "$PROJECT_ROOT/pyproject.toml" ]; then
    echo "ERROR: pyproject.toml not found in $PROJECT_ROOT" >&2
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/src/kimi_cli" ]; then
    echo "ERROR: src/kimi_cli not found in $PROJECT_ROOT" >&2
    exit 1
fi

cd "$PROJECT_ROOT"

export PYTHONPATH="${PROJECT_ROOT}/patches:${PROJECT_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"

# Proxy setup — only if corporate proxy is reachable
if python3 -c "import socket; s=socket.create_connection(('localhost',8888), timeout=1); s.close()" 2>/dev/null; then
    export HTTP_PROXY="${HTTP_PROXY:-http://localhost:8888}"
    export HTTPS_PROXY="${HTTPS_PROXY:-http://localhost:8888}"
    export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1},api.z.ai,*.tcsbank.ru,tcsbank.ru,*.tinkoff.ru,tinkoff.ru"
    echo "==> Corporate proxy detected at localhost:8888"
else
    echo "==> No corporate proxy detected, using direct connection"
fi

# Auto-build web static if missing
if [ ! -d "src/kimi_cli/web/static" ]; then
    if command -v npm >/dev/null 2>&1; then
        echo "==> Web static not found, building..."
        uv run scripts/build_web.py
    else
        echo "Warning: src/kimi_cli/web/static is missing and npm is not available. Install Node.js to build the web UI." >&2
    fi
fi

# Detect if user already passed --work-dir or -w
has_work_dir=0
for arg in "$@"; do
    if [[ "$arg" == "-w" || "$arg" == "--work-dir" ]]; then
        has_work_dir=1
        break
    fi
done

if [[ "$has_work_dir" -eq 0 ]]; then
    exec uv run python "${PROJECT_ROOT}/patches/kimi" -w "$ORIGINAL_PWD" "$@"
else
    exec uv run python "${PROJECT_ROOT}/patches/kimi" "$@"
fi
