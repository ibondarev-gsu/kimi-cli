# Dev Setup Guide

This guide is for running Kimi Code CLI from source with custom modifications (e.g., Z.AI provider, reviewer subagent, or any dev changes).

## Prerequisites

- [uv](https://docs.astral.sh/uv/) — Python package manager (should already be installed if you use Kimi)
- Git

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/ibondarev-gsu/kimi-cli.git ~/kimi-cli-dev
cd ~/kimi-cli-dev
```

### 2. Run dev version

We provide helper scripts that set `PYTHONPATH` and run the local code via `uv`:

**macOS / Linux:**
```bash
./run-dev.sh
```

**Windows (PowerShell):**
```powershell
.\run-dev.ps1
```

Both scripts accept the same arguments as the regular `kimi` command:

```bash
# Interactive shell
./run-dev.sh

# Login to a provider (e.g., Z.AI)
./run-dev.sh login

# Non-interactive mode
./run-dev.sh --print

# ACP server mode
./run-dev.sh acp
```

### 3. Optional: Create an alias

**macOS / Linux (add to `~/.zshrc` or `~/.bash_profile`):**
```bash
alias kimi-dev='~/kimi-cli-dev/run-dev.sh'
```

**Windows (add to PowerShell profile):**
```powershell
function kimi-dev { & "~/kimi-cli-dev/run-dev.ps1" @args }
```

## Important Notes

### Shared config directory

The dev version uses the **same** `~/.kimi` directory as the official release:

| What | Location | Shared? |
|------|----------|---------|
| API keys, config | `~/.kimi/config.toml` | ✅ Yes |
| Chat sessions | `~/.kimi/sessions/` | ✅ Yes |
| User skills | `~/.kimi/skills/` | ✅ Yes |
| MCP configs | `~/.kimi/mcp/` | ✅ Yes |
| Plans | `~/.kimi/plans/` | ✅ Yes |

You can safely switch between `kimi` (official) and `kimi-dev` (source) — they see the same settings.

### Updating dev version

```bash
cd ~/kimi-cli-dev
git pull
# No reinstall needed — run-dev.sh always uses current source
```

### Docker (optional)

If you use the web UI via Docker:

```bash
cd ~/kimi-cli-dev
docker build -t kimi-cli:latest .
docker run -d --name kimi-cli-web -p 8080:8080 \
  -v ~/.kimi:/root/.kimi \
  kimi-cli:latest
```

The `~/.kimi` volume mount ensures your config survives container rebuilds.

## Building a binary (advanced)

If you want to replace the system `kimi` binary:

```bash
cd ~/kimi-cli-dev
make build-bin
# Binary will be in dist/
# Replace at your own risk — `kimi update` may overwrite it later
```
