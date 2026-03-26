param(
    [int]$TimeoutSeconds = 120,
    [switch]$OneShot,
    [switch]$CopyToClipboard,
    [int]$PollIntervalMs = 2000,
    [string]$SenderFilter = "",
    [int]$MaxAgeMinutes = 5
)
$ErrorActionPreference = "Stop"

function Find-PhoneLinkDB {
    $base = "$env:LOCALAPPDATA\Packages\Microsoft.YourPhone_8wekyb3d8bbwe\LocalCache\Indexed"
    if (!(Test-Path $base)) { throw "Phone Link data not found. Is it installed and paired?" }
    $dbs = Get-ChildItem $base -Recurse -Filter "*.db" -EA SilentlyContinue
    if (!$dbs) { throw "No SMS database. Enable SMS sync in Phone Link." }
    $pick = $dbs | Where-Object { $_.Name -match "store|message" } | Select-Object -First 1
    if (!$pick) { $pick = $dbs[0] }
    return $pick.FullName
}

function Get-RecentSMS([string]$DbPath) {
    if (!(Get-Command sqlite3 -EA SilentlyContinue)) { throw "sqlite3 not found. Run: winget install SQLite.SQLite" }
    $tmp = "$env:TEMP\phonelink_2fa_$(Get-Random).db"
    Copy-Item $DbPath $tmp -Force
    $queries = @(
        "SELECT body, sender_name, timestamp FROM message ORDER BY timestamp DESC LIMIT 10;",
        "SELECT body, address, date FROM sms ORDER BY date DESC LIMIT 10;",
        "SELECT text_content, sender, created_time FROM messages ORDER BY created_time DESC LIMIT 10;"
    )
    foreach ($q in $queries) {
        $r = sqlite3 -separator "|" $tmp $q 2>$null
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
        '(?:^|\s)(\d{4,8})(?:\s|$|\.)'
    )
    foreach ($p in $patterns) { if ($Text -match $p) { return $Matches[1] } }
    return $null
}

# --- Main ---
$dbPath = Find-PhoneLinkDB
Write-Host ("SMS DB: {0}" -f $dbPath) -ForegroundColor Cyan
$filterLabel = if ($SenderFilter) { $SenderFilter } else { "any" }
Write-Host ("Watching for 2FA (timeout:{0}s filter:{1})..." -f $TimeoutSeconds, $filterLabel) -ForegroundColor Green

$start = Get-Date; $seen = @{}
while (((Get-Date)-$start).TotalSeconds -lt $TimeoutSeconds) {
    try { $msgs = Get-RecentSMS $dbPath } catch { Start-Sleep 3; continue }
    foreach ($m in $msgs) {
        $parts = $m -split '\|'; $body=$parts[0]; $sender=if($parts.Count -gt 1){$parts[1]}else{"?"}
        if ($SenderFilter -and $sender -notmatch $SenderFilter -and $body -notmatch $SenderFilter) { continue }
        $code = Extract-2FACode $body
        if ($code -and !$seen[$code]) {
            $seen[$code]=$true
            Write-Host ("`n2FA CODE: {0}" -f $code) -ForegroundColor Green
            Write-Host ("  From: {0}" -f $sender) -ForegroundColor Gray
            if ($CopyToClipboard) { Set-Clipboard $code; Write-Host "  Copied!" -ForegroundColor Cyan }
            if ($OneShot) { return $code }
        }
    }
    Start-Sleep -Milliseconds $PollIntervalMs
    Write-Host "." -NoNewline -ForegroundColor DarkGray
}
Write-Host "`nTimeout." -ForegroundColor Yellow; return $null
