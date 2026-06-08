# Palisade CLI shim (Windows) — runs the Bash pipeline in WSL.
# Native pld.exe ships in Phase 2; until then use WSL Docker path from USAGE_GUIDE § 6.
# Usage: .\pld.ps1 sync   OR   pld.cmd sync

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Passthrough
)

$ErrorActionPreference = 'Stop'

function Invoke-WslPld {
    param([string]$WslCd, [string[]]$Args)

    $quoted = ($Args | ForEach-Object {
        if ($_ -match '\s') { "'$_'" } else { $_ }
    }) -join ' '

    $bashCmd = "cd $WslCd && ./run $quoted"
    wsl.exe bash -lc "$bashCmd"
}

# Prefer operator canonical WSL clone over /mnt/e bind-mount
$homeClone = '~/projects/woosoo-platform'
$homeCheck = (wsl.exe bash -lc "test -d $homeClone && echo ok" 2>$null)
if ($homeCheck -match 'ok') {
    Invoke-WslPld -WslCd $homeClone -Args $Passthrough
    exit $LASTEXITCODE
}

# Fallback: this repo via wslpath (Windows checkout)
$root = $PSScriptRoot
if (-not (Test-Path (Join-Path $root 'run'))) {
    Write-Error "Platform root not found (missing run). Run from woosoo-platform repo root."
}
$wslPath = (wsl.exe wslpath -a "$root").Trim()
Invoke-WslPld -WslCd $wslPath -Args $Passthrough
exit $LASTEXITCODE
