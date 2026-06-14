#Requires -Version 5.1
<#
.SYNOPSIS
    Injects vault state into a Claude Code session via the UserPromptSubmit hook.
    Outputs a formatted context block to stdout; outputs nothing on any error.
.NOTES
    Wired in .claude/settings.json -> hooks -> UserPromptSubmit.
    Case: plt-case-obsidian-orchestration-wiring
#>

$root = $PSScriptRoot ? (Split-Path $PSScriptRoot -Parent) : (Get-Location).Path
$workFile   = Join-Path $root 'state\WORK.md'
$homeFile   = Join-Path $root 'docs\cases\OPERATOR_HOME.md'

if (-not (Test-Path $workFile) -or -not (Test-Path $homeFile)) { exit 0 }

try {
    $work = Get-Content $workFile -Raw -ErrorAction Stop

    # Extract the "Right now" section from OPERATOR_HOME (up to next --- divider)
    $home = Get-Content $homeFile -Raw -ErrorAction Stop
    $rightNow = ''
    if ($home -match '(?s)## Right now\r?\n(.*?)(\r?\n---\r?\n|\z)') {
        $rightNow = $Matches[1].Trim()
    }

    # Resolve ![[state/WORK#Current Task]] embed if present in rightNow
    $rightNow = $rightNow -replace '!\[\[state/WORK#Current Task\]\]', ''

    $out = @"
<vault-state>
<!-- Auto-injected by scripts/vault-inject.ps1 — do not edit this block -->

## Active work (state/WORK.md)

$($work.Trim())

## Operator context (OPERATOR_HOME — Right now)

$rightNow
</vault-state>
"@
    Write-Output $out
} catch {
    exit 0
}
