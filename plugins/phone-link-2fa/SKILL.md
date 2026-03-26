---
name: phone-link-2fa
description: "Extract 2FA verification codes from SMS via Windows Phone Link. Use when browser automation hits a 2FA page that sends codes via SMS."
domain: "authentication"
confidence: "high"
source: "manual"
triggers:
  - "2fa"
  - "sms"
  - "verification code"
  - "otp"
  - "phone link"
requires:
  os: windows
  capabilities:
    - sms
tools:
  - name: "powershell"
    description: "Run Get-2FACode.ps1 to poll Phone Link SMS database"
    when: "When a 2FA code needs to be extracted from an incoming SMS"
---

## Context

When automating web logins (Google, Microsoft, GitHub, etc.), many sites send a 2FA verification code via SMS. This skill extracts that code automatically from the Windows Phone Link app's local SQLite database.

**Only works on machines with:**
- Windows Phone Link paired to an Android phone
- SMS sync enabled
- `sms` capability registered in machine-capabilities.json

## Recipes

### Recipe 1: One-shot 2FA extraction

```powershell
# Trigger the 2FA flow first (e.g., click "Send code" in browser)
# Then wait for the SMS and extract the code:
$code = .\Get-2FACode.ps1 -OneShot -TimeoutSeconds 90
```

### Recipe 2: Filtered extraction

```powershell
# Only look for codes from a specific sender:
$code = .\Get-2FACode.ps1 -OneShot -SenderFilter "Google" -TimeoutSeconds 60
```

### Recipe 3: Playwright pipeline

```powershell
# Full 2FA automation flow:
playwright-cli click e7           # click "Send verification code"
$code = .\Get-2FACode.ps1 -OneShot -SenderFilter "Microsoft" -TimeoutSeconds 90
playwright-cli fill e12 $code     # fill the code field
playwright-cli click e15          # click "Verify"
```

### Recipe 4: Clipboard mode (manual paste)

```powershell
.\Get-2FACode.ps1 -OneShot -CopyToClipboard -TimeoutSeconds 120
# Code is now on clipboard — Ctrl+V to paste anywhere
```

## Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| "Phone Link data not found" | Phone Link not installed or never paired | Install Phone Link, pair phone |
| "No SMS database" | SMS sync not enabled | Phone Link Settings → Features → Messages: ON |
| "sqlite3 not found" | sqlite3 CLI missing | `winget install SQLite.SQLite` |
| Timeout with no code | SMS didn't arrive, or sender filter too strict | Relax SenderFilter, increase timeout |
| Wrong code extracted | Multiple recent SMS with codes | Use SenderFilter to narrow |

## Anti-Patterns

- **Don't run without a timeout.** Always set `-TimeoutSeconds` to avoid hanging forever.
- **Don't skip SenderFilter in noisy environments.** If the phone gets many SMS, filter by sender.
- **Don't use on shared machines.** The Phone Link DB contains all SMS — treat as sensitive.
- **Don't rely on this for iPhone.** Phone Link iPhone support has limited SMS sync.

## Routing Registration

```
| phone-link-2fa | 2FA code extraction from SMS | Infrastructure | Get-2FACode.ps1 | needs:sms |
```
