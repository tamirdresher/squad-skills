# 🤝 Cross-Squad Communication

**Protocol for sending queries, delegating tasks, and sharing context between independent Squad instances** across different repositories.

## What It Does

- Enables AI squad agents in one repo to query, delegate to, or coordinate with squads in other repos
- Four patterns: synchronous CLI session, read-only metadata query, async Git-based task request, issue-based delegation
- Platform compatibility matrix: GitHub Issues, ADO Work Items, Planner
- Liveness protocol to avoid false timeouts during cross-repo CLI sessions
- Discovery checklist to verify a target repo is squad-enabled before sending requests

## When to Use

- Another squad has context you need (architecture decisions, status, expertise)
- You need to delegate work that must persist in the target repo (PR review, analysis, changes)
- Cross-repo dependency analysis
- PR review requests spanning repo boundaries

## Patterns at a Glance

| Pattern | Best For | Requirement |
|---------|----------|-------------|
| 0 — Synchronous CLI | Quick knowledge queries | Target repo cloned locally |
| 1 — Read-Only Metadata | Architecture/decisions lookup | Git read access |
| 2 — Git-Based Async | Long tasks, work that persists | Both squads have Ralph running |
| 3 — Issue-Based | GitHub-hosted repos, delegation | `gh` CLI, target repo on GitHub |
| 4 — Dependency Scan | Cross-repo coupling analysis | Read access to both repos |

## Requirements

- GitHub CLI (`gh`) for issue-based patterns
- Copilot CLI (`ghcs`) for synchronous CLI sessions
- Target repo cloned locally for Patterns 0, 1, 2

## Files

- **SKILL.md** — Full agent-consumable knowledge with all patterns, schemas, examples, anti-patterns, and validation history

## Quick Start

Tell your AI agent:
> "Query the architecture decisions of the BasePlatformRP squad"

The skill teaches the agent to check if the target is squad-enabled, choose the right pattern, send the request, and handle the response.

## Validated Against

- BasePlatformRP (GitHub, 10 agents, Star Trek squad)
- Provisioning Wizard (ADO, 4 agents, Matrix squad)