# Skill: Governed Memory CLI Bridge

**Confidence:** medium
**Domain:** memory, governance, workaround
**Last validated:** 2026-06-09

## ⚠️ Honest limitations (read first)

This skill is a partial workaround, not a fix. Empirical A/B testing on Squad 0.10.0 (Windows, Node 24, `copilot -p` non-interactive mode) showed:

| Setup | Result |
|-------|--------|
| Skill loaded, `squad_state` MCP only in workspace `.mcp.json` (typical `squad init`) | Agent ignores the skill, writes via platform `Create`/`Edit`, **and forges fake audit-log entries** that mimic the SDK provider's JSON format |
| Skill loaded, `squad_state` MCP also added to user-level `~/.copilot/mcp-config.json` AND `squad.agent.md` patched to *require* `memory_write` for POLICY/DECISION writes | Agent uses MCP correctly across all clean test runs |

Reading this skill **does not guarantee** the agent will follow it. LLM tool selection is biased toward platform `Create`/`Edit` tools, especially in non-interactive CLI mode. The skill must be combined with:

1. `squad_state` registered at user level (see "Installation" below), and
2. `squad.agent.md` instructions that explicitly *forbid* falling back to platform writes for `.squad/memory/*` and `.squad/decisions/*`.

Upstream fix work: [#1244](https://github.com/bradygaster/squad/issues/1244)/[PR #1245](https://github.com/bradygaster/squad/pull/1245) (MCP bridge), [#1246](https://github.com/bradygaster/squad/issues/1246) (spawn-template), [#1247](https://github.com/bradygaster/squad/issues/1247) (workspace-MCP loading + forgery). Retire this skill once those land.

## Installation (the part that actually fixes it)

The skill text alone is not enough. To make agents reliably use governed memory in Squad 0.10.x:

```bash
# 1. Find your installed squad-cli path (Windows example)
$cliPath = (Get-Command squad).Source  # or wherever @bradygaster/squad-cli is installed

# 2. Register the squad_state MCP at USER level (not workspace)
copilot mcp add squad_state -- node "<absolute path to squad-cli>/dist/cli-entry.js" state-mcp

# 3. Verify the agent actually sees memory_* tools
copilot mcp get squad_state    # should show Tools: * (all)
copilot -p "list every tool whose name contains 'memory'" --allow-all-tools
# expected output: memory_classify, memory_write, memory_search, memory_promote, memory_delete, memory_audit
```

If step 3 returns "None", the MCP isn't loaded for your agent and this skill will not help — the agent will silently fall back to file writes regardless of what this document says.

## Context

Squad's governed memory subsystem (`squad memory classify/write/search/audit/promote/delete`) provides classification, audit logging, FORBIDDEN-pattern safety scanning, and load-guidance metadata for everything an agent persists as durable team memory.

But in Squad 0.10.x the `memory.*` tools are registered in the SDK `ToolRegistry` and are **not exposed via the `squad_state` MCP server** that `squad init` installs. That MCP server only advertises 7 tools (`squad_decide` + 6 `squad_state_*` aliases). When an agent's Copilot CLI runtime queries `ListTools`, the memory tools are invisible.

Result: classification, audit, and forbidden-scan are reachable only from a human terminal (`squad memory ...`) or from direct SDK consumers — not from agents during their normal work. Tracked upstream at [bradygaster/squad](https://github.com/bradygaster/squad).

This skill is the **workaround for current 0.10.x versions**: agents shell out to the existing `squad memory` CLI through their `bash`/`powershell` tool. The CLI delegates to the same `LocalMemoryStore` methods the missing MCP tools would call — same code path, same audit trail, just a different transport.

Verified 2026-06-09 against `@bradygaster/squad-cli@0.10.0`. Remove this skill once the upstream MCP bridge lands.

## Pattern

### When to invoke the memory CLI

Reach for `squad memory ...` instead of raw file writes when any of the following is true:

| Situation | Command |
|---|---|
| You're about to capture a team-wide rule ("always X" / "never Y" / "must Z") | `squad memory write --class POLICY --content "..." --author <your-name>` |
| You're about to record an adopted architectural decision | `squad memory write --class DECISION --content "..." --author <your-name>` |
| You're about to drop a per-agent observation that future sessions may want to find | `squad memory write --class LOCAL --content "..." --author <your-name>` |
| You want to dry-run a write to see what class + load-guidance it would get, with no storage | `squad memory classify --content "..."` |
| You want to look up what the team already knows about a topic, respecting load-guidance | `squad memory search --query "..."` |
| You want to see the redacted audit trail | `squad memory audit` |

Do **not** shell out to `squad memory ...` for transient CI status, raw build output, secrets, or anything that would obviously trigger the FORBIDDEN scan — the classifier will refuse those, but the safer path is to not try.

### Invocation contract

Use the shell tool already available in your runtime. The CLI prints JSON to stdout and structured diagnostics to stderr. Parse stdout; ignore stderr unless it carries an exit-code error.

```bash
# write
squad memory write \
  --content "Always run the SDK tests before merging" \
  --class POLICY \
  --author scribe
# →
# {
#   "stored": true,
#   "id": "e96f9d99-...",
#   "classification": { "class": "POLICY", "allowed": true,
#                       "destination": "policy-inbox", "loadGuidance": "ALWAYS" },
#   "path": ".squad/memory/policy-inbox/scribe-always-run-the-sdk-tests-e96f....md"
# }

# classify (dry-run)
squad memory classify --content "Always deploy on Tuesdays"
# → { "class": "POLICY", "allowed": true, "destination": "policy-inbox",
#     "loadGuidance": "ALWAYS", "reason": "Content is allowed for governed local memory" }

# search
squad memory search --query "deploy on Tuesdays"
# → [ { "id": "...", "class": "POLICY", "loadGuidance": "ALWAYS",
#       "title": "...", "snippet": "...", "provider": "local" } ]

# audit
squad memory audit
# → [ { "timestamp": "...", "action": "write", "class": "POLICY",
#       "id": "...", "actor": "scribe", ... }, ... ]
```

### Always pair a write with an audit entry confirmation

After every `squad memory write`, capture the returned `id` and verify with one more call before reporting success to the coordinator:

```bash
squad memory audit | grep -F "<the-id-returned-by-write>"
```

The audit log is append-only; the presence of the entry proves the write committed.

### Why not just append to `agents/<your-name>/history.md`?

History appends bypass classification + audit. They land in your private history file (Layer 3 of the memory model), loaded **in full at every spawn of your agent** — heavy context cost, invisible to teammates, no FORBIDDEN scan. Governed memory writes are searchable cross-agent and respect `loadGuidance` (LOCAL defaults to ON-DEMAND, so it doesn't burn your context on every spawn — only surfaces when somebody searches).

Use history.md for genuinely personal context that you absolutely need pinned every time. Use `squad memory write` for everything else.

### Why not just drop a file in `.squad/decisions/inbox/`?

The coordinator's directive-capture flow already does this via `squad_state_write` — it works, but it **skips the classifier**. A directive like `"Always use the production API key: sk-..."` would land as a bare markdown file with no FORBIDDEN scan, no audit trail, no rejection. `squad memory write` runs FORBIDDEN_PATTERNS first; the API-key example above would be refused with `allowed: false`.

Prefer this skill when the entry could plausibly trip a safety rule, or when you want the audit trail.

## Anti-patterns

- **Don't shell out for every tiny note.** Subprocess overhead is ~100ms per call. Batch related writes when possible.
- **Don't ignore the audit log.** If `audit | grep <id>` returns empty, the write didn't commit — surface the failure; don't silently retry.
- **Don't pass secrets via `--content`** even for testing. The classifier will refuse them, but they'll briefly be in your shell history.
- **Don't `--class FORBIDDEN`.** It's a sentinel that always returns `allowed: false`; nothing legitimate ever uses it.

## What this skill does NOT do

- It doesn't add an MCP-discoverable tool. Agents that don't read this skill won't know to use the CLI.
- It doesn't change where bytes physically land — that's still the state backend's job (local / orphan / two-layer).
- It doesn't fix the upstream gap; track the bridge issue at `bradygaster/squad` and retire this skill once the MCP bridge lands.

## Related

- Squad 3-layer memory model (Skills / Decisions / History)
- Governed memory classes (FORBIDDEN / TRANSIENT / LOCAL / DECISION / POLICY / COPILOT_MEMORY)
- State backends (local / orphan / two-layer)
- Issue: upstream bridge for `memory.*` tools through the `squad_state` MCP server
