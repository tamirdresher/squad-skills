param(
    [int]$TimeoutSeconds = 120,
    [switch]$OneShot,
    [switch]$CopyToClipboard,
    [int]$PollIntervalMs = 2000,
    [string]$SenderFilter = "",
    [int]$MaxAgeMinutes = 5,
    [switch]$ListRecent
)
$ErrorActionPreference = "Stop"

# SMS package names used by Android messaging apps
$script:SmsPackages = @(
    'com.google.android.apps.messaging',
    'com.android.mms',
    'com.samsung.android.messaging',
    'com.sec.android.app.smsreceiver'
)

function Find-PhoneLinkNotificationsDB {
    $base = "$env:LOCALAPPDATA\Packages\Microsoft.YourPhone_8wekyb3d8bbwe\LocalCache\Indexed"
    if (!(Test-Path $base)) { throw "Phone Link not found. Install from Microsoft Store and pair your phone." }
    $notifDb = Get-ChildItem $base -Recurse -Filter "notifications.db" -EA SilentlyContinue | Select-Object -First 1
    if ($notifDb) { return $notifDb.FullName }
    # Fallback: try legacy store.db / message.db
    $legacy = Get-ChildItem $base -Recurse -Filter "*.db" -EA SilentlyContinue |
        Where-Object { $_.Name -match "store|message" } | Select-Object -First 1
    if ($legacy) { return $legacy.FullName }
    throw "No Phone Link database found. Ensure Phone Link is paired and notifications are syncing."
}

function Get-RecentSMS([string]$DbPath, [int]$Limit = 20) {
    if (!(Get-Command sqlite3 -EA SilentlyContinue)) { throw "sqlite3 not found. Run: winget install SQLite.SQLite" }
    $tmp = "$env:TEMP\phonelink_2fa_$(Get-Random).db"
    Copy-Item $DbPath $tmp -Force
    $results = @()
    # Primary: notifications.db with JSON extraction
    $pkgFilter = ($script:SmsPackages | ForEach-Object { "'$_'" }) -join ','
    $q = "SELECT json_extract(json, '$.text') as body, json_extract(json, '$.title') as sender, post_time FROM notifications WHERE package_name IN ($pkgFilter) ORDER BY post_time DESC LIMIT $Limit;"
    $r = sqlite3 -separator "|" $tmp $q 2>$null
    if ($r) {
        Remove-Item $tmp -Force -EA SilentlyContinue
        return $r
    }
    # Fallback: legacy table structures
    $legacyQueries = @(
        "SELECT body, sender_name, timestamp FROM message ORDER BY timestamp DESC LIMIT $Limit;",
        "SELECT body, address, date FROM sms ORDER BY date DESC LIMIT $Limit;",
        "SELECT text_content, sender, created_time FROM messages ORDER BY created_time DESC LIMIT $Limit;"
    )
    foreach ($lq in $legacyQueries) {
        $r = sqlite3 -separator "|" $tmp $lq 2>$null
        if ($r) { Remove-Item $tmp -Force -EA SilentlyContinue; return $r }
    }
    Remove-Item $tmp -Force -EA SilentlyContinue
    return @()
}

function Extract-2FACode([string]$Text) {
    $patterns = @(
        '(?i)(?:code|码|קוד|код|رمز)[:\s]*(\d{4,8})',
        '(?i)(?:verification|verify|OTP|PIN|passcode)[:\s]*(\d{4,8})',
        'G-(\d{6})',
        '(\d{6})\s*(?:is your|verification|code)',
        '(?i)(?:use|enter|input)\s+(\d{4,8})',
        '(?:^|\s)(\d{4,8})(?:\s|$|\.)'
    )
    foreach ($p in $patterns) { if ($Text -match $p) { return $Matches[1] } }
    return $null
}

# --- Main ---
$dbPath = Find-PhoneLinkNotificationsDB
Write-Host ("SMS source: {0}" -f $dbPath) -ForegroundColor Cyan

if ($ListRecent) {
    Write-Host "`nRecent SMS messages:" -ForegroundColor Green
    $msgs = Get-RecentSMS $dbPath -Limit 10
    foreach ($m in $msgs) {
        $parts = $m -split '\|', 3
        $body = $parts[0]; $sender = if ($parts.Count -gt 1) { $parts[1] } else { "?" }
        $preview = if ($body.Length -gt 80) { $body.Substring(0,77) + "..." } else { $body }
        Write-Host ("  [{0}] {1}" -f $sender, $preview) -ForegroundColor White
    }
    return
}

$filterLabel = if ($SenderFilter) { $SenderFilter } else { "any" }
Write-Host ("Watching for 2FA (timeout:{0}s filter:{1})..." -f $TimeoutSeconds, $filterLabel) -ForegroundColor Green

$start = Get-Date; $seen = @{}
while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSeconds) {
    try { $msgs = Get-RecentSMS $dbPath } catch { Start-Sleep 3; continue }
    foreach ($m in $msgs) {
        $parts = $m -split '\|', 3
        $body = $parts[0]; $sender = if ($parts.Count -gt 1) { $parts[1] } else { "?" }
        if ($SenderFilter -and $sender -notmatch $SenderFilter -and $body -notmatch $SenderFilter) { continue }
        $code = Extract-2FACode $body
        if ($code -and !$seen[$code]) {
            $seen[$code] = $true
            Write-Host ("`n2FA CODE: {0}" -f $code) -ForegroundColor Green
            Write-Host ("  From: {0}" -f $sender) -ForegroundColor Gray
            Write-Host ("  Message: {0}" -f ($body.Substring(0, [Math]::Min(100, $body.Length)))) -ForegroundColor DarkGray
            if ($CopyToClipboard) { Set-Clipboard $code; Write-Host "  Copied to clipboard!" -ForegroundColor Cyan }
            if ($OneShot) { return $code }
        }
    }
    Start-Sleep -Milliseconds $PollIntervalMs
    Write-Host "." -NoNewline -ForegroundColor DarkGray
}
Write-Host "`nTimeout - no 2FA code found." -ForegroundColor Yellow; return $null
