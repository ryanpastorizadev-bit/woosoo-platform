# Regenerate docs/cases/CASE_REGISTRY.md from flat case files.
# Converts the orphan case list into a SUMMARIZED, status-annotated index (wikilink graph hub).
# Non-destructive: reads case files, never edits them. Full case files remain the durable audit trail.
# Source is ASCII-only (PowerShell 5.1 safe); emoji are built from codepoints for the output file.
# Usage: .\scripts\obsidian-case-registry.ps1

param(
    [string]$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$casesDir = Join-Path $VaultPath "docs\cases"
$skip = @('CASE_INDEX', 'CONTRACTS_HUB', 'OPERATOR_HOME', 'OPS_KANBAN', 'CASE_REGISTRY', '_TEMPLATE')

# Output glyphs (built from codepoints so the script source stays pure ASCII)
$EmOk    = [char]::ConvertFromUtf32(0x2705)   # check mark
$EmActive= [char]::ConvertFromUtf32(0x1F7E1)  # yellow circle
$EmBlock = [char]::ConvertFromUtf32(0x26D4)   # no entry
$Sep     = [char]::ConvertFromUtf32(0x00B7)   # middle dot
$Ell     = [char]::ConvertFromUtf32(0x2026)   # ellipsis

function Get-CaseSummary {
    param([string]$Path)

    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    if (-not $raw) { return $null }
    $lines = $raw -split "`r?`n"

    $status = '-'
    foreach ($l in $lines) { if ($l -match '^\s*-\s*status:\s*(.+)$') { $status = $Matches[1].Trim(); break } }

    $updated = '-'
    foreach ($l in $lines) { if ($l -match '^\s*-\s*updated:\s*(.+)$') { $updated = ($Matches[1].Trim() -split '\s+')[0]; break } }

    $summary = ''
    $titleIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#\s+') { $titleIdx = $i; break }
    }
    if ($titleIdx -ge 0) {
        $end = [Math]::Min($titleIdx + 6, $lines.Count)
        for ($i = $titleIdx + 1; $i -lt $end; $i++) {
            $t = $lines[$i].Trim()
            if ($t -eq '' -or $t -match '^<!--' -or $t -match '^#' -or $t -match '^-\s') { continue }
            $summary = $t; break
        }
    }
    if (-not $summary) {
        $pIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^##\s+Problem') { $pIdx = $i; break } }
        if ($pIdx -ge 0) {
            $end = [Math]::Min($pIdx + 8, $lines.Count)
            for ($i = $pIdx + 1; $i -lt $end; $i++) {
                $t = $lines[$i].Trim()
                if ($t -eq '' -or $t -match '^<!--') { continue }
                $summary = $t; break
            }
        }
    }
    $summary = $summary -replace '\|', '/' -replace '`', ''
    if ($summary.Length -gt 120) { $summary = $summary.Substring(0, 117).TrimEnd() + $Ell }

    return [pscustomobject]@{ Status = $status; Updated = $updated; Summary = $summary }
}

$groups = [ordered]@{
    'nex-case' = @(); 'tab-case' = @(); 'prn-case' = @()
    'plt-case' = @(); 'infra-case' = @(); 'infra-' = @(); 'other' = @()
}

Get-ChildItem -Path $casesDir -Filter '*.md' | Sort-Object Name | ForEach-Object {
    $b = $_.BaseName
    if ($skip -contains $b) { return }
    if ($b -match '^nex-case-') { $key = 'nex-case' }
    elseif ($b -match '^tab-case-') { $key = 'tab-case' }
    elseif ($b -match '^prn-') { $key = 'prn-case' }
    elseif ($b -match '^plt-case-') { $key = 'plt-case' }
    elseif ($b -match '^infra-case-') { $key = 'infra-case' }
    elseif ($b -match '^infra-') { $key = 'infra-' }
    else { $key = 'other' }
    $s = Get-CaseSummary -Path $_.FullName
    $groups[$key] += [pscustomobject]@{ Slug = $b; Status = $s.Status; Updated = $s.Updated; Summary = $s.Summary }
}

function Format-Status {
    param([string]$s)
    if ($s -match 'COMPLETE') { return "$EmOk COMPLETE" }
    if ($s -match 'IN_PROGRESS') { return "$EmActive IN_PROGRESS" }
    if ($s -match 'BLOCKED') { return "$EmBlock BLOCKED" }
    return $s
}

$titles = @{
    'nex-case' = 'Nexus (`nex-case-*`)'; 'tab-case' = 'Tablet (`tab-case-*`)'
    'prn-case' = 'Print bridge (`prn-*`)'; 'plt-case' = 'Platform (`plt-case-*`)'
    'infra-case' = 'Infra numbered (`infra-case-*`)'; 'infra-' = 'Infra other (`infra-*`)'
    'other' = 'Other / intake / audits'
}

$all = $groups.Values | ForEach-Object { $_ }
$total = ($all | Measure-Object).Count
$complete = ($all | Where-Object { $_.Status -match 'COMPLETE' } | Measure-Object).Count
$active = ($all | Where-Object { $_.Status -match 'IN_PROGRESS|BLOCKED' } | Measure-Object).Count

$intro = "**$total cases** $Sep $complete complete $Sep $active active/blocked. Auto-generated summary of every case file in docs/cases/; full files remain the durable audit trail (see RESUME_PROTOCOL). Regenerate: scripts/obsidian-case-registry.ps1."
$hub = "Hub: [[OPERATOR_HOME]] $Sep Dataview: [[CASE_INDEX]] $Sep Contracts: [[CONTRACTS_HUB]] $Sep Vault: [[VAULT_INDEX]]"

$out = @(
    '---', 'status: canonical', "last_reviewed: $(Get-Date -Format 'yyyy-MM-dd')", 'scope: ecosystem', '---', '',
    '# Case Registry (summarized wikilink index)', '',
    $intro, '', $hub, ''
)

foreach ($key in $groups.Keys) {
    $items = $groups[$key]
    if ($items.Count -eq 0) { continue }
    $out += "## $($titles[$key])"
    $out += ''
    $out += '| Case | Status | Updated | Summary |'
    $out += '|------|--------|---------|---------|'
    foreach ($c in ($items | Sort-Object Slug)) {
        $line = '| [[' + $c.Slug + ']] | ' + (Format-Status $c.Status) + ' | ' + $c.Updated + ' | ' + $c.Summary + ' |'
        $out += $line
    }
    $out += ''
}

$registryPath = Join-Path $casesDir "CASE_REGISTRY.md"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($registryPath, ($out -join "`n") + "`n", $utf8NoBom)
Write-Host "Updated $registryPath ($total cases: $complete complete, $active active/blocked)"
