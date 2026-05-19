# clean-logs.ps1
# Trims Laravel log to the last N days (default: 2).
# Usage:
#   .\scripts\clean-logs.ps1           # keep today + yesterday
#   .\scripts\clean-logs.ps1 -Days 3   # keep last 3 days

param(
    [int]$Days = 2
)

$laravelLog = "$PSScriptRoot\..\woosoo-nexus\storage\logs\laravel.log"
$cutoff = (Get-Date).Date.AddDays(-($Days - 1))  # start of the earliest day to keep

if (-not (Test-Path $laravelLog)) {
    Write-Host "laravel.log not found at: $laravelLog"
    exit 1
}

$lines = Get-Content $laravelLog
$kept  = $lines | Where-Object {
    if ($_ -match '^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
        [datetime]$entryDate = $Matches[1]
        return $entryDate -ge $cutoff
    }
    # Keep continuation lines (stack traces, JSON blobs) — no leading timestamp
    return $true
}

$removed = $lines.Count - $kept.Count
$kept | Set-Content $laravelLog -Encoding UTF8

$sizeMB = [math]::Round((Get-Item $laravelLog).Length / 1MB, 2)
Write-Host "✅ laravel.log trimmed — kept $($kept.Count) lines, removed $removed lines older than $($cutoff.ToString('yyyy-MM-dd')) (${sizeMB} MB remaining)"
