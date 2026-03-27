---
name: bitwarden-credential-management
description: Secure credential management for AI agents via official Bitwarden MCP server and bw CLI. Agents can store and retrieve secrets without exposing the entire vault. All access is audited.
triggers: ["bitwarden", "vault", "credential", "password manager", "mcp bitwarden", "bw cli", "agent credentials"]
confidence: high
---

# Bitwarden — AI Agent Credential Management

Provides secure, audited credential management for AI agents. Two access methods: **Bitwarden MCP server** (preferred) and **`bw` CLI** (fallback).

## CRITICAL: Security Rules

1. **NO DELETE** — Agents may NEVER delete vault items. Only the vault owner (human) can delete.
2. **NO EXPORT** — Never export the entire vault or dump all passwords.
3. **NO MASTER PASSWORD** — Never request, store, or log the master password.
4. **AUDIT ALL ACCESS** — Every credential access must be logged.
5. **LEAST PRIVILEGE** — Only retrieve the specific credential needed for the current task.
6. **NO PLAINTEXT LOGGING** — Never log actual password values. Log only item name/ID + action + timestamp.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Agent Process (Copilot CLI, CI runner, etc.)    │
│                                                   │
│  ┌──────────────┐    ┌─────────────────────────┐ │
│  │ MCP tools     │    │ bw CLI (fallback)       │ │
│  │ (preferred)   │    │ inherits BW_SESSION     │ │
│  └──────┬───────┘    └────────────┬────────────┘ │
│         │                         │               │
│  ┌──────▼─────────────────────────▼──────────┐   │
│  │ @bitwarden/mcp-server (stdio)             │   │
│  │ Inherits BW_SESSION from User env var      │   │
│  └──────────────────┬────────────────────────┘   │
│                      │                             │
└──────────────────────┼─────────────────────────────┘
                       │
               ┌───────▼───────┐
               │ Bitwarden     │
               │ Vault (cloud) │
               └───────────────┘
```

## Prerequisites

- **Bitwarden CLI:** `npm install -g @bitwarden/cli`
- **Bitwarden MCP server:** `npm install -g @bitwarden/mcp-server`
- **BW_SESSION:** Set as a persistent environment variable (see below)
- **MCP config:** Entry in your Copilot MCP config for the `"bitwarden"` server

## BW_SESSION — Persistent Session Key

`BW_SESSION` is an **encryption key** derived from the master password. It is NOT a JWT and does NOT expire on its own. This is the key insight that makes persistent agent access work.

**How it's stored:** As a User-level environment variable (Windows) or in shell profile (macOS/Linux). All new processes inherit it automatically — including background agents, watch processes, and new terminal sessions.

**It only breaks if:**
- Master password is changed
- Account is reset
- Explicit `bw lock` or `bw logout` is run

**Setting it (one-time, done by vault owner):**

#### Windows (PowerShell)
```powershell
# Login (first time only)
bw login your-vault-email@example.com

# Unlock and persist as User-level env var
$session = bw unlock --raw
[System.Environment]::SetEnvironmentVariable("BW_SESSION", $session, "User")
$env:BW_SESSION = $session
```

#### macOS / Linux
```bash
# Login (first time only)
bw login your-vault-email@example.com

# Unlock and persist in shell profile
export BW_SESSION=$(bw unlock --raw)
echo "export BW_SESSION=$BW_SESSION" >> ~/.bashrc  # or ~/.zshrc
```

## Agent Auto-Detection Pattern

Before using Bitwarden, every agent MUST run this check:

```
1. Is the Bitwarden MCP server available? (check tool list for bitwarden tools)
   → YES: Use MCP tools (preferred path)
2. Is BW_SESSION set?
   → YES: Use bw CLI as fallback
3. Neither available?
   → Report: "Bitwarden not available — BW_SESSION not set and MCP server not configured."
   → Do NOT fail silently. Do NOT attempt to unlock.
```

## Access Method 1: MCP Tools (Preferred)

When the Bitwarden MCP server is configured, agents get native tools for vault operations. No CLI invocation needed.

**MCP config entry** (add to your MCP config file):
```json
{
  "servers": {
    "bitwarden": {
      "type": "stdio",
      "command": "npx",
      "args": ["@bitwarden/mcp-server"]
    }
  }
}
```

The MCP server runs via stdio, inherits env vars (including `BW_SESSION`), and exposes tools directly. Agents don't need to do anything special — the tools appear automatically.

**Key MCP tools available:**
| Tool | Purpose |
|------|---------|
| `list` | List vault items (with search/filter) |
| `get` | Retrieve a specific item by ID or name |
| `create_item` | Create a new vault item |
| `edit_item` | Update an existing item |
| `generate` | Generate secure passwords/passphrases |
| `get_totp` | Get current TOTP code for an item |

## Access Method 2: bw CLI (Fallback)

When MCP is not available, use the standard `bw` CLI. The `BW_SESSION` env var is inherited automatically.

### Store a Credential

```powershell
$item = @{
  type = 1  # Login type
  name = "squad/service-name"
  notes = "Created by [agent-name] for [purpose]"
  login = @{
    username = "the-username"
    password = "the-password"
    uris = @(@{ uri = "https://service-url.com" })
  }
} | ConvertTo-Json -Depth 5

$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($item))
bw create item $encoded --session $env:BW_SESSION
```

**Naming Convention:** Prefix item names with a namespace (e.g., `squad/github-api-key`, `myproject/azure-storage-key`).

### Retrieve a Credential

```powershell
bw get item "squad/service-name" --session $env:BW_SESSION
bw get password "squad/service-name" --session $env:BW_SESSION
```

### List Credentials

```powershell
bw list items --search "squad/" --session $env:BW_SESSION
```

### Update a Credential

```powershell
$item = bw get item "squad/service-name" --session $env:BW_SESSION | ConvertFrom-Json
$item.login.password = "new-password"
$encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($item | ConvertTo-Json -Depth 5)))
bw edit item $item.id $encoded --session $env:BW_SESSION
```

## Audit Logging

Every credential access MUST be logged. Example format:

```
[2026-03-26T18:20:00Z] GET    | agent=AgentName | item=squad/github-token | method=MCP
[2026-03-26T18:21:00Z] STORE  | agent=AgentName | item=squad/azure-key    | method=CLI
[2026-03-26T18:22:00Z] LIST   | agent=AgentName | search=squad/           | method=MCP  | count=5
```

**Format:** `[ISO-timestamp] ACTION | agent=NAME | item=ITEM_NAME | method=MCP|CLI`

## Background Agent Integration

Background watch processes and autonomous agents inherit `BW_SESSION` from the User env var automatically — no special setup needed.

**Startup health check:** Agents SHOULD verify Bitwarden availability at startup:

```powershell
# Check BW health at startup
$bwStatus = bw status --session $env:BW_SESSION 2>&1 | ConvertFrom-Json
if ($bwStatus.status -ne "unlocked") {
    Write-Warning "⚠️ Bitwarden vault is NOT unlocked. Status: $($bwStatus.status)"
    Write-Warning "Credential operations will fail. Notify vault owner."
} else {
    Write-Host "✅ Bitwarden vault unlocked. Last sync: $($bwStatus.lastSync)"
}
```

## Cross-Machine Setup

Each machine needs a one-time setup:

```powershell
# 1. Install tooling
npm install -g @bitwarden/cli
npm install -g @bitwarden/mcp-server

# 2. Login and unlock
bw login your-vault-email@example.com
$session = bw unlock --raw

# 3. Persist BW_SESSION (Windows)
[System.Environment]::SetEnvironmentVariable("BW_SESSION", $session, "User")
$env:BW_SESSION = $session

# 4. Configure MCP server in your Copilot MCP config
# Add the bitwarden server entry to your mcp-config.json

# 5. Verify
bw status --session $env:BW_SESSION
```

## What's Next: Bitwarden Agent Access (aac)

Bitwarden is building an official **Agent Access** tool (`aac`) — an open protocol with E2E encrypted tunnels (Noise protocol) for agent credential access. Key differences from the BW_SESSION approach:

| | BW_SESSION approach | Agent Access (aac) |
|---|---|---|
| Scope | Full vault accessible | Per-domain credential scoping |
| Security | Session key in env var | E2E encrypted tunnel |
| LLM exposure | Creds flow through tools | `aac run` injects via env vars only |
| Status | Production-ready | Early preview |

Watch: [github.com/bitwarden/agent-access](https://github.com/bitwarden/agent-access)

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `You are not logged in` | Never logged in on this machine | `bw login your-email@example.com` |
| `Vault is locked` | BW_SESSION missing or invalid | Vault owner re-unlocks, sets env var |
| `Item not found` | Name mismatch or stale cache | Check namespace prefix; run `bw sync` |
| MCP tools not appearing | MCP server not configured | Add entry to your MCP config |
| MCP tools fail silently | BW_SESSION not inherited | Verify User-level env var is set (not just process-level) |
| `bw status` shows `locked` after reboot | User env var lost or password changed | Re-run unlock + persist steps |
