param(
    [switch]$List,
    [string]$Search,
    [string]$SessionId,
    [int]$Top = 20,
    [int]$Days = 7,
    [switch]$Recover
)
$ErrorActionPreference = "Stop"

$dbPaths = @(
    (Join-Path $env:USERPROFILE ".copilot\session-store.db"),
    (Join-Path $env:USERPROFILE ".copilot\session-store\session_store.db"),
    (Join-Path $env:APPDATA "copilot\session-store\session_store.db")
)
$found = $null
foreach ($p in $dbPaths) { if (Test-Path $p) { $found = $p; break } }
if (-not $found) {
    $s = Get-ChildItem (Join-Path $env:USERPROFILE ".copilot") -Recurse -Filter "session*store*.db" -EA SilentlyContinue | Select-Object -First 1
    if ($s) { $found = $s.FullName }
}
if (-not $found) { Write-Error "Session store not found."; exit 1 }

$sq = Get-Command sqlite3 -EA SilentlyContinue
if (-not $sq) { Write-Error "sqlite3 not found. Install: winget install SQLite.SQLite"; exit 1 }

function Invoke-SQL([string]$q) { sqlite3 -separator "|" -header $found $q 2>$null }

function Show-Row($row, [switch]$IsHeader) {
    $parts = $row -split '\|'
    return $parts
}

# --- LIST ---
if ($List -or (-not $Search -and -not $SessionId)) {
    Write-Host ("`nRecent sessions (last {0} days):" -f $Days) -ForegroundColor Cyan
    $q = "SELECT s.id, s.branch, s.summary, s.created_at, (SELECT COUNT(*) FROM turns t WHERE t.session_id = s.id) as turns FROM sessions s WHERE s.created_at >= date('now', '-{0} days') ORDER BY s.created_at DESC LIMIT {1};" -f $Days, $Top
    $rows = Invoke-SQL $q
    $i = 0
    foreach ($row in $rows) {
        if ($i -eq 0) { $i++; continue }
        $p = $row -split '\|'
        $sid = $p[0].Substring(0, [Math]::Min(8, $p[0].Length))
        $summary = if ($p[2] -and $p[2].Length -gt 70) { $p[2].Substring(0,70) + "..." } else { $p[2] }
        Write-Host ("  [{0}] {1} ({2} turns) {3}" -f $sid, $p[3], $p[4], $summary)
        $i++
    }
    Write-Host "`nUse -SessionId <id> for details, -Search <keyword> to find work." -ForegroundColor DarkGray
}

# --- SEARCH ---
if ($Search) {
    Write-Host ("`nSearching: '{0}'" -f $Search) -ForegroundColor Cyan
    $fts = ($Search -split '\s+') -join ' OR '
    $q = "SELECT DISTINCT si.session_id, s.summary, s.created_at, substr(si.content, 1, 80) FROM search_index si JOIN sessions s ON s.id = si.session_id WHERE search_index MATCH '{0}' ORDER BY s.created_at DESC LIMIT {1};" -f $fts, $Top
    $rows = Invoke-SQL $q
    $i = 0
    foreach ($row in $rows) {
        if ($i -eq 0) { $i++; continue }
        $p = $row -split '\|'
        $sid = $p[0].Substring(0, [Math]::Min(8, $p[0].Length))
        Write-Host ("  [{0}] {1} - {2}" -f $sid, $p[2], $p[1]) -ForegroundColor White
        $i++
    }
}

# --- DETAIL ---
if ($SessionId) {
    $q = "SELECT id, cwd, repository, branch, summary, created_at FROM sessions WHERE id LIKE '{0}%' LIMIT 1;" -f $SessionId
    $rows = Invoke-SQL $q
    if ($rows.Count -lt 2) { Write-Error "Not found: $SessionId"; exit 1 }
    $p = ($rows[1]) -split '\|'
    $fullId = $p[0]
    Write-Host ("`nSession: {0}" -f $fullId) -ForegroundColor Cyan
    Write-Host ("  CWD:     {0}" -f $p[1]) -ForegroundColor Gray
    Write-Host ("  Repo:    {0}" -f $p[2]) -ForegroundColor Gray
    Write-Host ("  Branch:  {0}" -f $p[3]) -ForegroundColor Gray
    Write-Host ("  Created: {0}" -f $p[5]) -ForegroundColor Gray
    Write-Host ("  Summary: {0}" -f $p[4]) -ForegroundColor White

    # First messages
    $tq = "SELECT turn_index, substr(user_message, 1, 200) FROM turns WHERE session_id = '{0}' ORDER BY turn_index LIMIT 3;" -f $fullId
    $turns = Invoke-SQL $tq
    Write-Host "`n  First messages:" -ForegroundColor Green
    $i = 0; foreach ($t in $turns) { if ($i -eq 0) { $i++; continue }; $tp = $t -split '\|'; Write-Host ("    Turn {0}: {1}" -f $tp[0], $tp[1]) -ForegroundColor Gray; $i++ }

    # Files
    $fq = "SELECT file_path, tool_name FROM session_files WHERE session_id = '{0}' ORDER BY first_seen_at LIMIT 10;" -f $fullId
    $files = Invoke-SQL $fq
    Write-Host "`n  Files:" -ForegroundColor Green
    $i = 0; foreach ($f in $files) { if ($i -eq 0) { $i++; continue }; $fp = $f -split '\|'; Write-Host ("    {0}: {1}" -f $fp[1], $fp[0]) -ForegroundColor Gray; $i++ }

    # Recovery prompt
    $cq = "SELECT title, substr(next_steps, 1, 300) FROM checkpoints WHERE session_id = '{0}' ORDER BY checkpoint_number DESC LIMIT 1;" -f $fullId
    $cps = Invoke-SQL $cq
    $rp = "Continue work from session {0}. Summary: {1}." -f $fullId, $p[4]
    if ($cps.Count -gt 1) { $cp = ($cps[1]) -split '\|'; $rp += " Last checkpoint: {0}. Next: {1}" -f $cp[0], $cp[1] }

    Write-Host "`n  Recovery prompt:" -ForegroundColor Yellow
    Write-Host "  $rp" -ForegroundColor White
    if ($Recover) { Set-Clipboard $rp; Write-Host "  Copied to clipboard!" -ForegroundColor Green }
    else { Write-Host "  Add -Recover to copy to clipboard." -ForegroundColor DarkGray }
}
