---
name: phone-link-2fa
description: "Read SMS 2FA codes from Windows Phone Link (notifications.db) and automate 2FA enrollment. Use when a web workflow requires SMS verification, 2FA codes, or phone number enrollment. Triggers on: 2FA code, SMS code, read SMS, phone verification, SMS 2FA, phone link."
domain: "auth"
---

# Phone Link 2FA — SMS Reading & 2FA Automation

Read SMS messages and extract 2FA codes from Windows Phone Link, and automate phone-based 2FA enrollment
on web platforms. This skill has two capabilities:

1. **SMS Reading** — Extract 2FA codes from Phone Link's `notifications.db` (automated, no human needed)
2. **2FA Enrollment** — Browser automation for linking phone numbers to accounts (may need human for CAPTCHA)

## Machine Requirement

> **⚠️ `needs:sms` capability required.** This skill only works on machines with Phone Link installed,
> paired, and syncing notifications from an Android phone. Check `~/.squad/machine-capabilities.json`
> for `"sms"` in the capabilities array. Currently only available on: **CPC-tamir-WCBED**.

## How SMS Reading Works

Phone Link syncs Android notifications (including SMS) into a local SQLite database:

```
%LOCALAPPDATA%\Packages\Microsoft.YourPhone_8wekyb3d8bbwe\LocalCache\Indexed\{GUID}\System\Database\notifications.db
```

SMS messages appear as notifications from these Android packages:
- `com.google.android.apps.messaging` (Google Messages)
- `com.android.mms` (stock Android MMS)
- `com.samsung.android.messaging` (Samsung Messages)

The `Get-2FACode.ps1` script queries this DB, extracts SMS text via `json_extract()`, and pattern-matches
2FA codes (4-8 digit codes with keyword context in EN/HE/AR/ZH/RU).

### Usage

```powershell
# Watch for 2FA code (polls every 2s, 120s timeout)
.\scripts\Get-2FACode.ps1 -OneShot -CopyToClipboard

# Filter by sender
.\scripts\Get-2FACode.ps1 -SenderFilter "Google" -OneShot

# List recent SMS messages
.\scripts\Get-2FACode.ps1 -ListRecent

# Custom timeout
.\scripts\Get-2FACode.ps1 -TimeoutSeconds 300 -PollIntervalMs 5000
```

### Automated 2FA Flow (No Human Needed)

When the squad triggers a login that sends an SMS 2FA code:

1. **Trigger login** via Playwright (enter username/password)
2. **Run Get-2FACode.ps1** with `-OneShot -CopyToClipboard -SenderFilter "{service}"`
3. **Script polls** Phone Link notifications.db for new SMS with a matching code
4. **Code returned** → paste into the 2FA field via Playwright
5. **Login complete** — no human intervention required!

## 2FA Enrollment (Browser Automation)

For enrolling a phone number in a new account's 2FA:

### Step 1: Navigate to Account Security Settings

Use Playwright to open the account security/2FA settings page.

### Step 2: Select Phone/SMS Method & Enter Number

Phone numbers must come from Bitwarden (via secrets-management skill) — never hardcode.

### Step 3: Receive & Enter Code

Use `Get-2FACode.ps1 -OneShot` to capture the verification SMS automatically.
If Phone Link isn't available on the current machine, escalate to Tamir via `status:needs-action`.

### Step 4: Confirm Enrollment

Verify the phone number is listed as enrolled. Take a screenshot as evidence.

## Error Handling

| Error | Action |
|-------|--------|
| Phone Link not installed | Fail with clear message; route to `needs:sms` machine |
| notifications.db not found | Check Phone Link is paired and notifications are syncing |
| No SMS packages in DB | Phone may not be syncing SMS notifications — check Phone Link settings |
| sqlite3 not found | `winget install SQLite.SQLite` |
| CAPTCHA blocks enrollment | Set `status:needs-action`, ask Tamir to complete manually |
| SMS not received within timeout | Increase `-TimeoutSeconds`; check phone has signal |
| Rate limited | Wait 5 min, retry once; escalate on second failure |

## Related Skills

- **secrets-management** — Retrieve phone number and credentials from Bitwarden
- **github-account-switching** — Auth isolation when managing multiple accounts
- **gh-auth-isolation** — Prevent account state conflicts during enrollment
- **error-recovery** — Handle unexpected failures during the workflow

---

**Skill Maintainer**: Worf (Security & Cloud)  
**Created**: Issue #1595 (routing/capabilities audit gap from #1592)  
**Updated**: 2026-03-26 — Rewrote to use notifications.db for SMS reading (no dedicated SMS DB needed)  
**Status**: Working — tested on CPC-tamir-WCBED with Google Messages via Phone Link
