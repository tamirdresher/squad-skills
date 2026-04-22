# 🚀 Spawn Squad

**Teach an HQ agent to create, run, and manage child squads for specific missions.**

## What It Does

This skill enables a "fan-out" pattern where a coordinator agent spawns purpose-built child squads for parallel or specialized work. Each child squad gets its own workspace, team configuration, and mission brief — then reports structured results back to the parent.

## Use Cases

| Scenario | Squad Type | Example |
|----------|-----------|---------|
| Legacy migration | Long-lived | One child squad per microservice to modernize |
| Research exploration | Ephemeral | Parallel squads investigating different hypotheses |
| Crisis response | Ephemeral | Dedicated squad spun up per incident |
| Legal / compliance | Long-lived | One squad per case file or audit scope |
| Template validation | Ephemeral | Disposable squads testing prompt changes E2E |

## Requirements

| Tool | Required | Notes |
|------|----------|-------|
| GitHub Copilot CLI (`copilot`) | ✅ | With Squad agent registered |
| Squad CLI (`squad`) | ✅ | For `squad init` |
| Git | ✅ | Workspace isolation |

### Platform Support

| Platform | Status |
|----------|--------|
| Windows (PowerShell) | ✅ Supported |
| macOS / Linux | ✅ Supported |
| GitHub Codespaces | ✅ Supported |
| Containers | ⚠️ Requires CLI installation |

## Quick Start

```bash
# Install the plugin
copilot plugin install tamirdresher/squad-skills:plugins/spawn-squad

# Or copy manually for Squad
cp -r plugins/spawn-squad /path/to/your/repo/.squad/skills/
```

## The Pattern in 30 Seconds

1. **Define** a mission contract with concrete success criteria
2. **Create** an isolated workspace (`mkdir` + `git init` or `git clone`)
3. **Initialize** a squad with `squad init`, customize for the mission
4. **Run** sessions with `copilot --agent squad -p "..."`
5. **Verify** outcomes against success criteria (don't trust — verify)
6. **Report** structured verdict: PASS / PARTIAL / FAIL with evidence
7. **Cleanup** or persist based on squad lifecycle

## Key Principles

- **One workspace per squad** — never share
- **Mission contract first** — no spawning without success criteria
- **Verify independently** — don't trust session output as proof
- **Start small** — one ephemeral squad before parallel fan-out

## Related

- [cross-machine-coordination](../cross-machine-coordination/) — Git-based task queuing across machines
- [github-distributed-coordination](../github-distributed-coordination/) — Work claiming protocol for parallel agents
- [e2e-template-testing (Squad PR #1022)](https://github.com/bradygaster/squad/pull/1022) — The original pattern this skill generalizes

## License

[MIT](../../LICENSE)
