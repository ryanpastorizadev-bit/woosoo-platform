#!/usr/bin/env pwsh
# case-status — print or update the "## Run State" block in docs/cases/<slug>.md
#
# Cross-runner resume helper (Claude Code / Codex / Copilot). Dependency-free.
# Behaviour-identical to scripts/case-status.sh. See docs/RESUME_PROTOCOL.md.
#
# Usage:
#   pwsh scripts/case-status.ps1 get  <slug>
#   pwsh scripts/case-status.ps1 set  <slug> key=value [key=value ...]
#   pwsh scripts/case-status.ps1 init <slug>
#
# Keys: task_slug tier branch status last_completed_agent next_agent
#       active_runner interrupted interrupt_reason updated
# 'updated' is auto-set on 'set' unless passed explicitly. Only keys already
# present in the Run State block are updated (the template ships every key).

[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('get', 'set', 'init')][string]$Command,
  [Parameter(Mandatory)][string]$Slug,
  [Parameter(ValueFromRemainingArguments)][string[]]$Pairs
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$casesDir = Join-Path $root 'docs/cases'
$template = Join-Path $casesDir '_TEMPLATE.md'
$caseFile = Join-Path $casesDir "$Slug.md"
$allowed = @('task_slug', 'tier', 'branch', 'status', 'last_completed_agent',
  'next_agent', 'active_runner', 'interrupted', 'interrupt_reason', 'updated')

function Read-Lines([string]$path) {
  return ([IO.File]::ReadAllText($path) -split "`r?`n")
}
function Write-Lines([string]$path, [string[]]$lines) {
  [IO.File]::WriteAllText($path, ($lines -join "`n"))
}
function Get-RunStateBlock([string[]]$lines) {
  $f = $false
  foreach ($l in $lines) {
    if ($l -match '^## Run State') { $f = $true; $l; continue }
    if ($f -and $l -match '^## ' -and $l -notmatch '^## Run State') { break }
    if ($f) { $l }
  }
}

switch ($Command) {
  'init' {
    if (-not (Test-Path $template)) { throw "case-status: template not found: $template" }
    if (Test-Path $caseFile) { "case-status: $caseFile already exists (not overwritten)"; break }
    $content = ([IO.File]::ReadAllText($template)).Replace('<slug>', $Slug)
    [IO.File]::WriteAllText($caseFile, $content)
    "case-status: created $caseFile"
  }
  'get' {
    if (-not (Test-Path $caseFile)) { throw "case-status: case file not found: $caseFile" }
    Get-RunStateBlock (Read-Lines $caseFile)
  }
  'set' {
    if (-not (Test-Path $caseFile)) { throw "case-status: case file not found: $caseFile" }
    if (-not $Pairs -or $Pairs.Count -lt 1) { throw "case-status: set requires at least one key=value" }
    $lines = Read-Lines $caseFile
    if (-not ($lines -match '^## Run State')) { throw "case-status: no '## Run State' block in $caseFile" }
    $kv = [ordered]@{}
    foreach ($p in $Pairs) {
      $i = $p.IndexOf('=')
      if ($i -lt 1) { throw "case-status: bad arg (need key=value): $p" }
      $k = $p.Substring(0, $i); $v = $p.Substring($i + 1)
      if ($allowed -notcontains $k) { throw "case-status: unknown key: $k (allowed: $($allowed -join ' '))" }
      $kv[$k] = $v
    }
    if (-not $kv.Contains('updated')) { $kv['updated'] = (Get-Date -Format 'yyyy-MM-dd HH:mm') }
    $inblk = $false
    $new = foreach ($l in $lines) {
      if ($l -match '^## Run State') { $inblk = $true; $l; continue }
      if ($inblk -and $l -match '^## ' -and $l -notmatch '^## Run State') { $inblk = $false }
      if ($inblk) {
        $m = [regex]::Match($l, '^- ([a-z_]+):')
        if ($m.Success -and $kv.Contains($m.Groups[1].Value)) {
          $key = $m.Groups[1].Value
          ('- {0}: {1}' -f $key, $kv[$key])
          continue
        }
      }
      $l
    }
    Write-Lines $caseFile $new
    Get-RunStateBlock (Read-Lines $caseFile)
  }
}
