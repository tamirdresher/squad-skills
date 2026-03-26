# 📱 Phone Link 2FA

Extract 2FA verification codes from SMS messages synced to Windows via the **Phone Link** app.

## When to Use

When your automation flow hits a 2FA/OTP page and the code is sent via SMS to your phone. Instead of manually reading and typing the code, this plugin reads it directly from the Phone Link SQLite database.

## Prerequisites

| Requirement | How to Get It |
|-------------|---------------|
| Windows 10/11 | — |
| Phone Link app | Pre-installed on Windows 11, or `ms-windows-store://pdp/?productid=9NMPJ99VJBWV` |
| Android phone paired | Phone Link → pair via QR code |
| SMS sync enabled | Phone Link Settings → Features → Messages: ON |
| sqlite3 CLI | `winget install SQLite.SQLite` |

## Quick Start

```powershell
# One-shot: wait for a 2FA code and return it
$code = .\scripts\Get-2FACode.ps1 -OneShot -TimeoutSeconds 60

# Filter by sender
$code = .\scripts\Get-2FACode.ps1 -OneShot -SenderFilter "Google"

# Copy to clipboard
.\scripts\Get-2FACode.ps1 -OneShot -CopyToClipboard
```

## Playwright Integration

```powershell
# 1. Trigger the 2FA flow
playwright-cli click e7           # "Send code" button

# 2. Wait for SMS and extract code
$code = .\scripts\Get-2FACode.ps1 -OneShot -SenderFilter "Microsoft" -TimeoutSeconds 90

# 3. Fill and verify
playwright-cli fill e12 $code
playwright-cli click e15          # "Verify" button
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `TimeoutSeconds` | int | 120 | Max seconds to wait |
| `OneShot` | switch | false | Return first code and exit |
| `CopyToClipboard` | switch | false | Copy code to clipboard |
| `PollIntervalMs` | int | 2000 | Poll frequency |
| `SenderFilter` | string | `""` | Filter by sender name/number |
| `MaxAgeMinutes` | int | 5 | Ignore messages older than this |

## Machine Capability

This plugin requires the `sms` machine capability. Register it in your machine capabilities file:

```json
{
  "capabilities": ["browser", "sms"]
}
```

And add `needs:sms` to any issue that requires 2FA via SMS.

## Supported Code Formats

- Google: `G-123456`
- Microsoft: `Security code: 123456`
- Generic: `Your code is 123456`, `OTP: 1234`
- Hebrew: `קוד: 123456`
- Arabic: `رمز: 123456`
- Chinese: `验证码: 123456`
- Any standalone 4-8 digit code in a verification message

## Security Notes

- **Local only** — reads the Phone Link SQLite DB on disk, no network calls
- **Copy-on-read** — copies the DB before querying to avoid locking Phone Link
- **No logging** — SMS content is never written to disk
- **Time-bounded** — only reads messages from the last N minutes
