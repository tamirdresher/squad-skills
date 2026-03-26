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

function Find-PhoneLinkDB {
    $base = "$env:LOCALAPPDATA\Packages\Microsoft.YourPhone_8wekyb3d8bbwe\LocalCache\Indexed"
    if (!(Test-Path $base)) { throw "Phone Link not found. Install from Microsoft Store and pair your phone." }
    # Primary: phone.db contains the Messages pane SMS data (requires WAL copy)
    $phoneDb = Get-ChildItem $base -Recurse -Filter "phone.db" -EA SilentlyContinue | Select-Object -First 1
    if ($phoneDb) { return @{ Path = $phoneDb.FullName; Type = "phone" } }
    # Fallback: notifications.db (some SMS may appear as notifications)
    $notifDb = Get-ChildItem $base -Recurse -Filter "notifications.db" -EA SilentlyContinue | Select-Object -First 1
    if ($notifDb) { return @{ Path = $notifDb.FullName; Type = "notifications" } }
    throw "No Phone Link database found. Ensure Phone Link is paired and syncing."
}

function Copy-DBWithWAL([string]$DbPath) {
    # SQLite WAL mode: must copy .db + .db-wal + .db-shm together for consistent reads
    $tmp = "$env:TEMP\phonelink_2fa_$(Get-Random)"
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $dbName = [System.IO.Path]::GetFileName($DbPath)
    $dbDir = [System.IO.Path]::GetDirectoryName($DbPath)
    Copy-Item $DbPath "$tmp\$dbName" -Force
    Copy-Item "$DbPath-wal" "$tmp\$dbName-wal" -Force -EA SilentlyContinue
    Copy-Item "$DbPath-shm" "$tmp\$dbName-shm" -Force -EA SilentlyContinue
    return "$tmp\$dbName"
}

function Get-RecentSMS([hashtable]$DbInfo, [int]$Limit = 20) {
    if (!(Get-Command sqlite3 -EA SilentlyContinue)) { throw "sqlite3 not found. Run: winget install SQLite.SQLite" }
    $tmp = Copy-DBWithWAL $DbInfo.Path
    $results = @()
    try {
        if ($DbInfo.Type -eq "phone") {
            # phone.db: message table with body, from_address, timestamp
            $q = "SELECT body, from_address, timestamp FROM message ORDER BY timestamp DESC LIMIT $Limit;"
            $results = sqlite3 -separator "|" $tmp $q 2>$null
        }
        if (!$results -or $results.Count -eq 0) {
            # notifications.db fallback: SMS via Android messaging app notifications
            $smsPackages = @('com.google.android.apps.messaging','com.android.mms','com.samsung.android.messaging')
            $pkgFilter = ($smsPackages | ForEach-Object { "'$_'" }) -join ','
            $q = "SELECT json_extract(json, '$.text'), json_extract(json, '$.title'), post_time FROM notifications WHERE package_name IN ($pkgFilter) ORDER BY post_time DESC LIMIT $Limit;"
            $results = sqlite3 -separator "|" $tmp $q 2>$null
        }
    } finally {
        $tmpDir = [System.IO.Path]::GetDirectoryName($tmp)
        Remove-Item $tmpDir -Recurse -Force -EA SilentlyContinue
    }
    return $results
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
$dbInfo = Find-PhoneLinkDB
Write-Host ("SMS source: {0} ({1})" -f $dbInfo.Path, $dbInfo.Type) -ForegroundColor Cyan

if ($ListRecent) {
    Write-Host "`nRecent SMS messages:" -ForegroundColor Green
    $msgs = Get-RecentSMS $dbInfo -Limit 10
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
    try { $msgs = Get-RecentSMS $dbInfo } catch { Start-Sleep 3; continue }
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
