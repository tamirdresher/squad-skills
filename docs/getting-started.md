# 🚀 Getting Started with Squad Skills

## What is Squad Skills?

**Squad Skills** is an open marketplace of reusable knowledge plugins for AI agents. Think of it as *npm for AI agent skills* — each plugin is a structured markdown file (`SKILL.md`) that teaches any AI agent a new capability, from automating Microsoft Teams to managing GitHub project boards.

The key insight: these aren't code libraries — they're **knowledge modules**. Any AI system that can read markdown can use them. No SDKs, no lock-in. They work with GitHub Copilot (CLI & VS Code), Claude, ChatGPT, Squad, or any LLM-based agent.

---

## ⏱️ Your First 5 Minutes

Let's get a plugin working in under 5 minutes. We'll use **conference-book-of-news** — a showcase plugin that auto-generates conference summary PDFs from session videos.

### Step 1 — Browse the plugins

```bash
# Clone or browse the repo
git clone https://github.com/tamirdresher/squad-skills.git
cd squad-skills

# List all available plugins
ls plugins/
```

Or just [browse the plugins on GitHub](https://github.com/tamirdresher/squad-skills/tree/main/plugins).

### Step 2 — Pick a plugin and read its SKILL.md

Every plugin lives in `plugins/<plugin-name>/` and contains:

| File | Purpose |
|------|---------|
| `SKILL.md` | 🤖 The core — agent-consumable knowledge |
| `manifest.json` | 📋 Machine-readable metadata |
| `README.md` | 📖 Human-readable documentation |
| `scripts/` | 🔧 Optional supporting scripts |

Open the skill file to understand what it teaches:

```bash
cat plugins/conference-book-of-news/SKILL.md
```

You'll see YAML frontmatter (triggers, confidence, description) followed by structured recipes the agent can follow.

### Step 3 — Install the plugin

Installation depends on your AI platform. Pick your platform below:

---

## 📦 Platform Installation Guide

### GitHub Copilot CLI

Copy the `SKILL.md` into your repository's Copilot instructions:

```bash
# Option A: Append to repo-level instructions
mkdir -p .github
cat plugins/conference-book-of-news/SKILL.md >> .github/copilot-instructions.md
```

Or reference it as a custom agent:

```bash
# Option B: Create a dedicated Copilot agent
mkdir -p .github/copilot-agents
cp plugins/conference-book-of-news/SKILL.md .github/copilot-agents/conference-news.md
```

Once added, the Copilot CLI will use the skill automatically when you mention relevant triggers (e.g., `"generate a book of news for Build 2025"`).

### VS Code — GitHub Copilot Chat

1. Copy `SKILL.md` into your workspace under `.github/copilot-instructions.md` (append) or `.github/copilot-agents/<name>.md`
2. Open Copilot Chat in VS Code
3. The skill knowledge is now available — just ask Copilot to perform the task described in the plugin

```bash
# Quick setup from terminal
cp plugins/conference-book-of-news/SKILL.md .github/copilot-agents/conference-news.md
```

### Claude (Projects)

1. Open your [Claude Project](https://claude.ai) settings
2. Go to **Project Knowledge**
3. Click **Add Content** → paste the contents of `SKILL.md`
4. Claude will reference this knowledge in all conversations within that project

### ChatGPT (Custom GPTs)

1. Go to [ChatGPT](https://chat.openai.com) → **Explore GPTs** → **Create**
2. In **Configure** → **Knowledge**, upload the `SKILL.md` file
3. The GPT will use this knowledge when relevant triggers match

### Squad (GitHub Copilot Squad)

Squad agents auto-discover skills from `.squad/skills/`:

```bash
# Copy the entire plugin folder into your Squad repo
cp -r plugins/conference-book-of-news /path/to/your/repo/.squad/skills/
```

That's it — Squad agents will pick up the skill on their next run.

### Any Other Agent

Just read the file and add it to your agent's context:

```python
with open("plugins/conference-book-of-news/SKILL.md") as f:
    skill = f.read()

agent.add_context(skill)
```

---

## 🧪 Step 4 — Use the Plugin

After installing, just interact with your AI agent naturally. Use the **trigger phrases** listed in the plugin's YAML frontmatter. For `conference-book-of-news`, try:

> "Generate a book of news for Microsoft Build 2025"

The agent will follow the recipes defined in `SKILL.md` — scraping sessions, capturing screenshots, extracting slides via OCR, and producing a formatted PDF.

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
