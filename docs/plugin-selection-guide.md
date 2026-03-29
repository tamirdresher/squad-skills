# 🧩 Plugin Selection Guide

Not sure which plugin you need? This guide organizes all plugins by category with complexity ratings and platform requirements to help you pick the right one.

> **Legend:**
> 🟢 Easy — Minimal setup, no special dependencies
> 🟡 Medium — Some configuration or platform-specific tools needed
> 🔴 Advanced — Multiple dependencies, complex setup, or deep integration required

---

## 🤖 Automation

Plugins that drive UI or application automation beyond standard APIs.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [teams-ui-automation](../plugins/teams-ui-automation/) | Hybrid Teams automation — Playwright + keyboard shortcuts + UIA for operations not in Graph API | 🔴 Advanced | Windows | Playwright MCP, Teams Desktop |
| [outlook-automation](../plugins/outlook-automation/) | Control Outlook via COM — send emails, create meetings, search inbox, manage calendar | 🟡 Medium | Windows | Outlook Desktop (COM) |
| [phone-link-2fa](../plugins/phone-link-2fa/) | Extract 2FA/OTP codes from SMS via Windows Phone Link | 🟡 Medium | Windows | Phone Link app, paired device |

---

## 📡 Communication & Monitoring

Plugins for messaging, email, news delivery, and channel monitoring.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [teams-monitor](../plugins/teams-monitor/) | Monitor Teams channels via WorkIQ and bridge messages to GitHub issues | 🟡 Medium | Any | WorkIQ MCP, GitHub CLI |
| [news-broadcasting](../plugins/news-broadcasting/) | Scan tech news, compile reports, and deliver to team channels | 🟡 Medium | Any | Web access, Teams/email |
| [squad-email-headless](../plugins/squad-email-headless/) | Send emails headlessly via Microsoft Graph API from a shared mailbox | 🟡 Medium | Any | Microsoft Graph API, OAuth token |
| [mail-mcp](../plugins/mail-mcp/) | Enhanced email capabilities via Mail MCP server integration | 🟢 Easy | Any | Mail MCP server |

---

## 🔄 Coordination & Recovery

Plugins for multi-machine work distribution, session recovery, and agent self-improvement.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [cross-machine-coordination](../plugins/cross-machine-coordination/) | Git-based task queuing for multi-machine agent coordination | 🔴 Advanced | Any | Git, multiple machines |
| [github-distributed-coordination](../plugins/github-distributed-coordination/) | Distributed work claiming protocol using GitHub-native features | 🔴 Advanced | Any | GitHub CLI |
| [session-recovery](../plugins/session-recovery/) | Find and resume past Copilot CLI sessions from session_store | 🟢 Easy | Any | Copilot CLI session_store |
| [restart-recovery](../plugins/restart-recovery/) | Snapshot and restore full dev environment after machine restart | 🟡 Medium | Windows | Copilot CLI, running services |
| [reflect](../plugins/reflect/) | Agent self-reflection — capture lessons learned to prevent repeating mistakes | 🟢 Easy | Any | None |

---

## 🔐 Security & Credentials

Plugins for secrets, credential management, and GitHub account isolation.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [bitwarden-credential-management](../plugins/bitwarden-credential-management/) | Secure credential management via Bitwarden MCP + CLI | 🟡 Medium | Any | Bitwarden CLI, Bitwarden MCP |
| [secrets-management](../plugins/secrets-management/) | Centralized secrets management — secrets never in git, always at runtime | 🟡 Medium | Any | Credential store |
| [gh-auth-isolation](../plugins/gh-auth-isolation/) | Prevent auth conflicts when multiple agent instances use different GitHub accounts | 🟡 Medium | Any | GitHub CLI |
| [github-multi-account](../plugins/github-multi-account/) | Auto-routing gh proxy for personal vs EMU/enterprise accounts | 🟡 Medium | Any | GitHub CLI, multiple accounts |

---

## 📋 Project Management

Plugins for issue tracking, project boards, and incident response.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [github-project-board](../plugins/github-project-board/) | GitHub Projects V2 board sync with issue lifecycle management | 🟡 Medium | Any | GitHub CLI, Projects V2 |
| [incident-response](../plugins/incident-response/) | On-call incident triage — Azure Status checks, correlation, and response procedures | 🟡 Medium | Any | Azure subscription (optional) |

---

## 📝 Content Creation

Plugins for writing, summarization, and content generation.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [blog-writing](../plugins/blog-writing/) | Technical blog writing patterns — storytelling structure, code blocks, and checklists | 🟢 Easy | Any | None |
| [conference-book-of-news](../plugins/conference-book-of-news/) | Auto-generate Ignite-style "Book of News" PDF from any conference with video screenshots and AI summaries | 🔴 Advanced | Any | yt-dlp, Tesseract OCR, ffmpeg |
| [fact-checking](../plugins/fact-checking/) | Agent fact-verification patterns for ensuring accuracy before publishing | 🟢 Easy | Any | None |

---

## ⚙️ Agent Configuration

Plugins for tuning agent behavior and integrating developer tools.

| Plugin | Description | Complexity | Platform | Key Dependencies |
|--------|-------------|:----------:|----------|-----------------|
| [chrome-devtools-mcp](../plugins/chrome-devtools-mcp/) | Chrome DevTools MCP server for remote debugging and browser inspection | 🟡 Medium | Any | Chrome, DevTools MCP server |

---

## 🔍 Quick Reference — All Plugins at a Glance

| Plugin | Category | Complexity | Platform |
|--------|----------|:----------:|----------|
| [bitwarden-credential-management](../plugins/bitwarden-credential-management/) | 🔐 Security | 🟡 Medium | Any |
| [blog-writing](../plugins/blog-writing/) | 📝 Content | 🟢 Easy | Any |
| [chrome-devtools-mcp](../plugins/chrome-devtools-mcp/) | ⚙️ Agent Config | 🟡 Medium | Any |
| [conference-book-of-news](../plugins/conference-book-of-news/) | 📝 Content | 🔴 Advanced | Any |
| [cross-machine-coordination](../plugins/cross-machine-coordination/) | 🔄 Coordination | 🔴 Advanced | Any |
| [fact-checking](../plugins/fact-checking/) | 📝 Content | 🟢 Easy | Any |
| [gh-auth-isolation](../plugins/gh-auth-isolation/) | 🔐 Security | 🟡 Medium | Any |
| [github-distributed-coordination](../plugins/github-distributed-coordination/) | 🔄 Coordination | 🔴 Advanced | Any |
| [github-multi-account](../plugins/github-multi-account/) | 🔐 Security | 🟡 Medium | Any |
| [github-project-board](../plugins/github-project-board/) | 📋 Project Mgmt | 🟡 Medium | Any |
| [incident-response](../plugins/incident-response/) | 📋 Project Mgmt | 🟡 Medium | Any |
| [mail-mcp](../plugins/mail-mcp/) | 📡 Communication | 🟢 Easy | Any |
| [news-broadcasting](../plugins/news-broadcasting/) | 📡 Communication | 🟡 Medium | Any |
| [outlook-automation](../plugins/outlook-automation/) | 🤖 Automation | 🟡 Medium | Windows |
| [phone-link-2fa](../plugins/phone-link-2fa/) | 🤖 Automation | 🟡 Medium | Windows |
| [reflect](../plugins/reflect/) | 🔄 Coordination | 🟢 Easy | Any |
| [restart-recovery](../plugins/restart-recovery/) | 🔄 Coordination | 🟡 Medium | Windows |
| [secrets-management](../plugins/secrets-management/) | 🔐 Security | 🟡 Medium | Any |
| [session-recovery](../plugins/session-recovery/) | 🔄 Coordination | 🟢 Easy | Any |
| [squad-email-headless](../plugins/squad-email-headless/) | 📡 Communication | 🟡 Medium | Any |
| [teams-monitor](../plugins/teams-monitor/) | 📡 Communication | 🟡 Medium | Any |
| [teams-ui-automation](../plugins/teams-ui-automation/) | 🤖 Automation | 🔴 Advanced | Windows |

---

## 📖 Further Reading

- [Getting Started Guide](getting-started.md) — Step-by-step tutorial for new users
- [Contributing Guide](../.github/CONTRIBUTING.md) — How to create and submit your own plugin
- [Main README](../README.md) — Project overview and philosophy
