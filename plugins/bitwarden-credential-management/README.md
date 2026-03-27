# 🔐 Bitwarden Credential Management

Secure credential management for AI agents using Bitwarden's official MCP server and CLI.

## What It Does

Gives AI agents safe, audited access to credentials stored in a Bitwarden vault — without exposing the master password or the entire vault.

### Two Access Methods

1. **Bitwarden MCP Server** (preferred) — Native tool integration, agents get vault tools automatically
2. **`bw` CLI** (fallback) — Standard CLI access when MCP isn't available

### Key Features

- 🔒 **Security-first:** NO delete, NO export, NO master password access
- 📋 **Audit trail:** Every credential access is logged
- 🔄 **Persistent sessions:** `BW_SESSION` doesn't expire — agents work unattended
- 🖥️ **Cross-machine:** User-level env vars propagate to all processes automatically
- 🤖 **Agent auto-detection:** Agents check MCP → CLI → graceful failure

## Quick Start

```bash
# Install
npm install -g @bitwarden/cli @bitwarden/mcp-server

# Login & persist session
bw login your-email@example.com
export BW_SESSION=$(bw unlock --raw)

# Add MCP server to your config
# See SKILL.md for the full MCP config entry
```

## What's Coming

Bitwarden's official [Agent Access](https://github.com/bitwarden/agent-access) (`aac`) tool adds E2E encrypted tunnels and per-domain credential scoping. See SKILL.md for comparison.

## Platform Support

Works with any AI agent platform that supports MCP or can run shell commands:
- GitHub Copilot (CLI, VS Code, JetBrains)
- Claude (via MCP)
- Squad AI teams
- Custom agents
