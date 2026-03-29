# 🚀 Getting Started with Squad Skills

## What is Squad Skills?

**Squad Skills** is an open marketplace of reusable knowledge plugins for AI agents. Think of it as *npm for AI agent skills* — each plugin is a structured markdown file (`SKILL.md`) that teaches any AI agent a new capability, from automating Microsoft Teams to managing GitHub project boards.

The key insight: these aren't code libraries — they're **knowledge modules**. Any AI system that can read markdown can use them. No SDKs, no lock-in. They work with GitHub Copilot (CLI & VS Code), Claude, ChatGPT, Squad, or any LLM-based agent.

---

## ⏱️ Your First 5 Minutes

Let's get a plugin working in under 5 minutes. We'll use **conference-book-of-news** — a showcase plugin that auto-generates conference summary PDFs from session videos.

### Step 1 — Browse the plugins

```bash
# Browse available plugins via the CLI
copilot plugin marketplace add tamirdresher/squad-skills   # one-time setup
copilot plugin marketplace browse squad-skills
```

Or just [browse the plugins on GitHub](https://github.com/tamirdresher/squad-skills/tree/main/plugins).

### Step 2 — Pick a plugin and read its SKILL.md

Every plugin lives in `plugins/<plugin-name>/` and contains:

| File | Purpose |
|------|---------|
| `SKILL.md` | 🤖 The core — agent-consumable knowledge |
| `manifest.json` | 📋 Machine-readable metadata (plugin manifest) |
| `README.md` | 📖 Human-readable documentation |
| `scripts/` | 🔧 Optional supporting scripts |

Open the skill file to understand what it teaches:

```bash
cat plugins/conference-book-of-news/SKILL.md
```

You'll see YAML frontmatter (triggers, confidence, description) followed by structured recipes the agent can follow.

### Step 3 — Install the plugin

The fastest way to install a plugin is with the **Copilot CLI plugin system**:

```bash
# Option A: Install from the registered marketplace
copilot plugin marketplace add tamirdresher/squad-skills   # one-time registration
copilot plugin install conference-book-of-news@squad-skills

# Option B: Install directly from the repo (no marketplace registration needed)
copilot plugin install tamirdresher/squad-skills:plugins/conference-book-of-news
```

That's it. The plugin is now installed to `~/.copilot/state/installed-plugins/` and Copilot CLI will use it automatically when you mention relevant triggers.

**Manage your plugins:**

```bash
copilot plugin list                    # View installed plugins
copilot plugin update conference-book-of-news   # Update to latest version
copilot plugin uninstall conference-book-of-news # Remove plugin
```

> 💡 **VS Code users:** The `/plugin install` command also works inside Copilot Chat interactive sessions.

Using a different platform? See [Platform-Specific Installation](#-other-platforms) below.

---

## 🧪 Step 4 — Use the Plugin

After installing, just interact with your AI agent naturally. Use the **trigger phrases** listed in the plugin's YAML frontmatter. For `conference-book-of-news`, try:

> "Generate a book of news for Microsoft Build 2025"

The agent will follow the recipes defined in `SKILL.md` — scraping sessions, capturing screenshots, extracting slides via OCR, and producing a formatted PDF.

---

## 📦 Other Platforms

The `copilot plugin install` command is the recommended method for GitHub Copilot users. For other platforms, install plugins manually:

### Squad (GitHub Copilot Squad)

Squad agents auto-discover skills from `.squad/skills/`:

```bash
# Copy the entire plugin folder into your Squad repo
cp -r plugins/conference-book-of-news /path/to/your/repo/.squad/skills/
```

That's it — Squad agents will pick up the skill on their next run.

### Claude (Projects)

1. Open your [Claude Project](https://claude.ai) settings
2. Go to **Project Knowledge**
3. Click **Add Content** → paste the contents of `SKILL.md`
4. Claude will reference this knowledge in all conversations within that project

### ChatGPT (Custom GPTs)

1. Go to [ChatGPT](https://chat.openai.com) → **Explore GPTs** → **Create**
2. In **Configure** → **Knowledge**, upload the `SKILL.md` file
3. The GPT will use this knowledge when relevant triggers match

### Manual Copy (any Copilot project)

If you prefer to vendor the skill directly into a repo instead of using the plugin system:

```bash
mkdir -p .copilot/skills/conference-book-of-news
cp plugins/conference-book-of-news/SKILL.md .copilot/skills/conference-book-of-news/SKILL.md
```

Copilot auto-discovers skills from `.copilot/skills/` — but the plugin system is preferred since it handles updates automatically.

### Any Other Agent

Just read the file and add it to your agent's context:

```python
with open("plugins/conference-book-of-news/SKILL.md") as f:
    skill = f.read()

agent.add_context(skill)
```

---

## 🗺️ What's Next?

- **Not sure which plugin to use?** Check the [Plugin Selection Guide](plugin-selection-guide.md) for a categorized matrix with complexity ratings.
- **Want to contribute?** See the [Contributing Guide](../.github/CONTRIBUTING.md) for templates and quality guidelines.
- **Browse all plugins** in the [Available Plugins](../README.md#-available-plugins) table.

---

## 💡 Tips

- **Start simple.** Plugins rated 🟢 Easy in the [selection guide](plugin-selection-guide.md) have minimal dependencies and are great for first-timers.
- **One plugin at a time.** Install and test one skill before adding more — too many instructions can dilute agent focus.
- **Check the README.** Each plugin has a human-readable `README.md` alongside `SKILL.md` with extra context, known limitations, and examples.
- **Triggers matter.** Use the exact trigger phrases from the YAML frontmatter for the most reliable activation.
- **Keep plugins updated.** Run `copilot plugin update PLUGIN-NAME` periodically to pull the latest version from the marketplace.
