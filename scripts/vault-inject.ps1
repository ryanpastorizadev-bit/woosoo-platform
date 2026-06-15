#Requires -Version 5.1
<#
.SYNOPSIS
    Injects vault state into a Claude Code session via the UserPromptSubmit hook.
    Outputs a formatted context block to stdout; outputs nothing on any error.
.NOTES
    Wired in .claude/settings.json -> hooks -> UserPromptSubmit.
    Case: plt-case-obsidian-orchestration-wiring
    Section-selective per WORK.md schema contract (sections self-documented in WORK.md).
#>

if ($PSScriptRoot) { $root = Split-Path $PSScriptRoot -Parent } else { $root = (Get-Location).Path }
$workFile = Join-Path $root 'state\WORK.md'
$homeFile = Join-Path $root 'docs\cases\OPERATOR_HOME.md'

if (-not (Test-Path $workFile) -or -not (Test-Path $homeFile)) { exit 0 }

try {
    # --- section-selective WORK.md extraction (whitelist 3 sections) ---
    $workRaw   = Get-Content $workFile -Raw -ErrorAction Stop
    $whitelist = @('Current Task', 'Blocking Dependencies', 'Last Agent')
    $picked    = New-Object System.Collections.Generic.List[string]
    $pattern   = '(?ms)^## (.+?)\r?\n(.+?)(?=\r?\n## |\z)'
    foreach ($m in [regex]::Matches($workRaw, $pattern)) {
        $header = $m.Groups[1].Value.Trim()
        if ($whitelist -contains $header) {
            $body = $m.Groups[2].Value.TrimEnd()
            $picked.Add("## $header`r`n$body")
        }
    }
    $work = ($picked -join "`r`n`r`n").Trim()

    # --- OPERATOR_HOME "Right now" table ---
    $homeContent = Get-Content $homeFile -Raw -ErrorAction Stop
    $rightNow = ''
    if ($homeContent -match '(?s)## Right now\r?\n(.*?)(\r?\n---\r?\n|\z)') {
        $rightNow = $Matches[1].Trim()
    }

    # Resolve ![[state/WORK#Current Task]] embed if present in rightNow
    $rightNow = $rightNow -replace '!\[\[state/WORK#Current Task\]\]', ''

    $out = @"
<vault-state>
<!-- Auto-injected by scripts/vault-inject.ps1 - do not edit this block -->

## Active work (state/WORK.md)

$work

## Operator context (OPERATOR_HOME - Right now)

$rightNow
</vault-state>
"@
    Write-Output $out
} catch {
    exit 0
}
