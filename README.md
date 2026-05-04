# 🧩 Squad Skills — AI Plugin Marketplace

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Plugins](https://img.shields.io/badge/Plugins-24-green.svg)](#-available-plugins)
[![Platform](https://img.shields.io/badge/Works%20With-Any%20AI%20Agent-purple.svg)](#-installation)

**Reusable knowledge plugins for AI agents.** Think of it as *npm for AI agent skills* — structured knowledge modules that any AI system can consume to learn new capabilities.

> 🎯 **Not locked to any framework.** These plugins work with GitHub Copilot, Claude, ChatGPT, Squad, or any LLM-based agent. A plugin is just a well-structured markdown file that teaches an AI agent how to do something.

---

## 💡 What Is This?

AI agents are powerful, but they don't know everything out of the box. This marketplace provides **drop-in knowledge plugins** — each one teaches your AI agent a specific skill:

- 🖥️ **Automate Microsoft Teams** UI when the Graph API isn't enough
- 📡 **Bridge Teams messages** into GitHub issues automatically
- 🔄 **Coordinate work** across machines using Git as a task queue
- 📋 **Manage project boards** with proper lifecycle transitions
- 🤝 **Distribute tasks** across agents without conflicts

Each plugin is a self-contained `SKILL.md` — structured markdown that any AI agent can read and act on. No SDKs, no dependencies, no lock-in.

---

## 📦 Available Plugins

| Plugin | Description | Triggers |
|--------|-------------|----------|
| [🖥️ teams-ui-automation](plugins/teams-ui-automation/) | Hybrid Teams automation — Playwright + keyboard shortcuts + UIA | `teams ui`, `install teams app`, `teams automation` |
| [🔐 bitwarden-credential-management](plugins/bitwarden-credential-management/) | Bitwarden MCP + CLI integration for secure AI agent credential management | `bitwarden`, `vault`, `credential`, `password manager` |
| [📡 teams-monitor](plugins/teams-monitor/) | Monitor Teams channels via WorkIQ and bridge messages to GitHub issues | `check teams`, `teams monitor` |
| [🔄 cross-machine-coordination](plugins/cross-machine-coordination/) | Git-based task queuing for multi-machine agent coordination | `cross machine`, `remote task`, `distribute work` |
| [📋 github-project-board](plugins/github-project-board/) | GitHub Projects V2 board sync with issue lifecycle | `project board`, `move issue`, `board status` |
| [🤝 github-distributed-coordination](plugins/github-distributed-coordination/) | Distributed work claiming protocol using GitHub-native features | `distributed coordination`, `work claiming` |
| [📧 outlook-automation](plugins/outlook-automation/) | Control Outlook on Windows — send emails, create meetings, search inbox, manage tasks | `create meeting`, `send email`, `search emails`, `outlook` |
| [📰 news-broadcasting](plugins/news-broadcasting/) | Tech news scanning, compilation, and delivery to team channels | `news`, `tech news`, `daily briefing`, `news report`, `scan news` |
| [✅ fact-checking](plugins/fact-checking/) | Agent fact-verification patterns for ensuring accuracy before publishing | `fact check`, `verify`, `validate claims`, `source check` |
| [🔄 session-recovery](plugins/session-recovery/) | Find and resume individual past Copilot CLI sessions from session_store | `session recovery`, `find session`, `resume session` |
| [🔄 restart-recovery](plugins/restart-recovery/) | Snapshot and restore full dev environment (services, sessions, state) after machine restart | `restart recovery`, `recover from restart`, `snapshot before restart` |
| [🔄 reflect](plugins/reflect/) | Agent self-reflection and continuous improvement patterns | `reflect`, `retrospective`, `self-improve`, `lessons learned`, `what went wrong` |
| [🔀 github-multi-account](plugins/github-multi-account/) | Solve multi-account GitHub CLI chaos with account-locked aliases | `gh auth switch`, `wrong account`, `multi account`, `EMU` |
| [📱 phone-link-2fa](plugins/phone-link-2fa/) | Extract 2FA codes from SMS via Windows Phone Link | `2fa`, `sms`, `verification code`, `otp`, `phone link` |
| [📘 conference-book-of-news](plugins/conference-book-of-news/) | Auto-generate Ignite-style "Book of News" PDF from any conference — scrapes videos, captures screenshots, OCR extracts slides, AI summarizes sessions | `conference`, `book of news`, `session recap`, `ignite`, `build`, `summit`, `video screenshots` |
| [🚀 spawn-squad](plugins/spawn-squad/) | Teach an HQ agent to create, run, and manage child squads — fan-out pattern for parallel exploration, legacy migration, and ephemeral missions | `spawn squad`, `create squad`, `fan out`, `child squad`, `new squad`, `delegate squad`, `launch squad`, `spin up squad`, `orchestrate squads` |
| [🤝 cross-squad-communication](plugins/cross-squad-communication/) | Protocol for querying, delegating, and sharing context across independent Squad instances in other repos | `cross squad`, `inter squad`, `squad handoff`, `delegate to squad` |

---

## 🚀 Installation

Every plugin's core is a single file: **`SKILL.md`**. The fastest way to install plugins is with the **Copilot CLI plugin system**.

### GitHub Copilot (CLI & VS Code) — Recommended

```bash
# One-time: register the marketplace
copilot plugin marketplace add tamirdresher/squad-skills

# Install any plugin
copilot plugin install teams-ui-automation@squad-skills

# Or install directly from the repo (no marketplace registration needed)
copilot plugin install tamirdresher/squad-skills:plugins/teams-ui-automation
```

Plugins are installed to `~/.copilot/state/installed-plugins/` and activate automatically. Manage them with:

```bash
copilot plugin list                    # View installed plugins
copilot plugin update PLUGIN-NAME      # Update to latest version
copilot plugin uninstall PLUGIN-NAME   # Remove plugin
```

> 💡 In VS Code Copilot Chat, `/plugin install` works in interactive sessions too.

### Squad (GitHub Copilot Squad)

```bash
# Copy the entire plugin folder — Squad agents auto-discover from .squad/skills/
cp -r plugins/teams-ui-automation /path/to/your/repo/.squad/skills/
```

### Claude Projects

1. Open your Claude Project settings → **Project Knowledge**
2. Paste the contents of `SKILL.md` as a knowledge document

### ChatGPT / Custom GPTs

1. Go to **Configure** → **Knowledge**
2. Upload the `SKILL.md` file

### Any Other Agent

Just read the `SKILL.md` file. That's it. It's structured markdown with:
- **YAML frontmatter** — metadata, triggers, confidence level
- **Recipes** — step-by-step procedures the agent can follow
- **Error recovery** — what to do when things go wrong
- **Anti-patterns** — common mistakes to avoid

```python
# Example: Load a plugin in your custom agent
with open("plugins/teams-ui-automation/SKILL.md") as f:
    skill_knowledge = f.read()

# Add to your agent's system prompt or context
agent.add_context(skill_knowledge)
```

---

## 📖 Documentation

New to Squad Skills? These guides will get you up and running:

- **[Getting Started Guide](docs/getting-started.md)** — New here? Walk through picking, installing, and using your first plugin in under 5 minutes.
- **[Plugin Selection Guide](docs/plugin-selection-guide.md)** — Not sure which plugin you need? Browse the categorized matrix with complexity ratings and platform info.

---

## 📁 Plugin Structure

Each plugin follows a consistent structure:

```
plugins/
  your-plugin/
    manifest.json     # 📋 Machine-readable metadata
    SKILL.md          # 🤖 Agent-consumable knowledge (the core)
    README.md         # 📖 Human-readable documentation
    scripts/          # 🔧 Supporting scripts (optional)
```

### Manifest Format

Every plugin includes a `manifest.json` for tooling and discovery:

```json
{
  "name": "your-plugin-name",
  "version": "1.0.0",
  "description": "What it does in one line",
  "platforms": ["copilot", "claude", "squad", "any"],
  "triggers": ["keyword1", "related phrase"],
  "author": "Your Name",
  "license": "MIT",
  "files": {
    "skill": "SKILL.md",
    "scripts": ["scripts/helper.ps1"]
  }
}
```

---

## 🤝 Contributing

We'd love your plugins! If you've built an automation pattern that works well with AI agents, share it.

**Quick start:**

1. Fork this repo
2. Create `plugins/your-plugin-name/` with `manifest.json`, `SKILL.md`, and `README.md`
3. Open a PR

📖 See the full [Contributing Guide](.github/CONTRIBUTING.md) for templates, best practices, and quality guidelines.

---

## 🧠 Philosophy

- **Knowledge, not code.** Plugins are structured documentation, not libraries. They teach agents *how* to do things, not *what* to execute.
- **Platform-agnostic.** If it can read markdown, it can use these plugins.
- **Self-contained.** Each plugin has everything an agent needs — context, recipes, error recovery, and anti-patterns.
- **Community-driven.** The best automation patterns come from real-world use.

---

## 📄 License

[MIT](LICENSE) — use these plugins however you want.
