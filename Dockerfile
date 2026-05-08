# Production Dockerfile for Kimi Code CLI Web UI
# Multi-stage build: web assets + Python runtime

# ─── Stage 1: Build web frontend ─────────────────────────────────────────────
FROM node:20-bookworm AS web-builder

WORKDIR /workspace
COPY web/package*.json web/
RUN cd web && npm ci

COPY web/ web/
RUN cd web && npm run build

# ─── Stage 2: Python runtime ─────────────────────────────────────────────────
FROM ghcr.io/astral-sh/uv:python3.14-bookworm-slim

# Install git (needed for some CLI operations)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy project source
COPY . .

# Copy built web assets from stage 1
COPY --from=web-builder /workspace/web/dist /workspace/src/kimi_cli/web/static

# Install Python dependencies and package
RUN uv sync --all-packages \
    && uv pip install -e .

# Persist kimicli config (models, providers, subagent_models)
VOLUME ["/root/.kimi"]

# Expose web UI port
EXPOSE 5494

# Default: run web UI without auth (for local Docker testing).
# For production, mount a config with auth or pass KIMI_WEB_AUTH_TOKEN.
ENTRYPOINT ["uv", "run", "python", "-m", "kimi_cli"]
CMD ["web", "--host", "0.0.0.0", "--port", "5494", "--no-open", "--network"]
