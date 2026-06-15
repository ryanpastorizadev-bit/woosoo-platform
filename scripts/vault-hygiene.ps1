# vault-hygiene.ps1 -- unified operator-runnable vault hygiene wrapper.
# Tier A (detect-only): lint, governance guards, canonical-age, placeholder dates,
#                       malformed status values.
# Tier B (safe auto-fix): -Refresh flag regenerates case registry + frontmatter.
# No git commits. Exit 0 always (report tool -- use recurrence-check for the hard gate).
# ASCII-only source. PowerShell 5.1 compatible.
#
# Usage:
#   .\scripts\vault-hygiene.ps1                          # Tier A checks only (read-only)
#   .\scripts\vault-hygiene.ps1 -Refresh                 # Tier B: regen registry first
#   .\scripts\vault-hygiene.ps1 -AgeThresholdDays 14     # tighter staleness window
#   .\scripts\vault-hygiene.ps1 -SaveReport              # save snapshot to docs/cases/

param(
    [switch]$Refresh,
    [int]$AgeThresholdDays = 30,
    [switch]$SaveReport
)

$ErrorActionPreference = "Stop"
$VaultPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $VaultPath

# Emoji defined at runtime so source bytes stay ASCII (recurrence-check CHK-PS-ASCII).
$iconOk   = [char]0x2705   # checkmark green
$iconWarn = [char]0x26A0   # warning triangle
$iconBull = [char]0x2022   # bullet

$today     = [datetime]::Today
$cutoff    = $today.AddDays(-$AgeThresholdDays)
$dateStamp = $today.ToString("yyyy-MM-dd")

$reportLines = [System.Collections.Generic.List[string]]::new()

function Out {
    param([string]$msg = "")
    Write-Host $msg
    [void]$reportLines.Add($msg)
}
function OutSection([string]$title) {
    Out ""
    Out ("=" * 64)
    Out "  $title"
    Out ("=" * 64)
}

# --- helper: read YAML frontmatter (between first pair of --- delimiters) ---
function Get-Frontmatter([string]$path) {
    $fm = @{}
    $raw = Get-Content $path -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $raw -or $raw.Count -eq 0 -or $raw[0].Trim() -ne '---') { return $fm }
    $i = 1
    while ($i -lt $raw.Count -and $raw[$i].Trim() -ne '---') {
        if ($raw[$i] -match '^([\w][\w_-]*):\s*(.*)$') {
            $fm[$Matches[1]] = $Matches[2].Trim()
        }
        $i++
    }
    return $fm
}

Out "vault-hygiene.ps1 -- $dateStamp"
Out "VaultPath: $VaultPath"
Out "AgeThresholdDays: $AgeThresholdDays"

# =====================================================================
# STEP 0: Registry refresh (Tier B -- only when -Refresh)
# =====================================================================
OutSection "STEP 0: Case Registry"
$regScript = Join-Path $PSScriptRoot "obsidian-case-registry.ps1"
if ($Refresh) {
    Out "  -Refresh: running obsidian-case-registry.ps1 (frontmatter + registry)..."
    & $regScript *>&1 | ForEach-Object { Out "  $_" }
} else {
    # Read-only: just report freshness of CASE_REGISTRY.md.
    $regFile = Join-Path $VaultPath "docs\cases\CASE_REGISTRY.md"
    if (Test-Path $regFile) {
        $regFm = Get-Frontmatter $regFile
        $regDate = if ($regFm['last_reviewed']) { $regFm['last_reviewed'] } else { "(no date)" }
        Out "  CASE_REGISTRY.md last_reviewed: $regDate"
        Out "  To regenerate registry + frontmatter run with -Refresh."
    } else {
        Out "  $iconWarn CASE_REGISTRY.md not found."
    }
}

# =====================================================================
# STEP 1: Vault lint -- orphans, broken links, missing tags (Tier A)
# =====================================================================
OutSection "STEP 1: Vault Lint (obsidian-lint.ps1)"
$lintScript = Join-Path $PSScriptRoot "obsidian-lint.ps1"
$lintLines  = & $lintScript *>&1 | ForEach-Object { "$_" }
$lintLines | ForEach-Object { Out "  $_" }

$orphanCount      = 0
$brokenCount      = 0
$missingTagsCount = 0
foreach ($l in $lintLines) {
    if ($l -match '=== Orphans: (\d+)')                 { $orphanCount      = [int]$Matches[1] }
    if ($l -match '=== Broken links[^:]*: (\d+)')       { $brokenCount      = [int]$Matches[1] }
    if ($l -match '=== Cases missing required tags: (\d+)') { $missingTagsCount = [int]$Matches[1] }
}
$lintOk = ($brokenCount -eq 0 -and $missingTagsCount -eq 0)
$lintSymbol = if ($lintOk) { $iconOk } else { $iconWarn }
Out ""
Out "  $lintSymbol Lint: orphans=$orphanCount  broken=$brokenCount  missing-tags=$missingTagsCount"

# =====================================================================
# STEP 2: Governance guards (Tier A / hard merge gate)
# =====================================================================
OutSection "STEP 2: Governance Guards (recurrence-check.ps1)"
$recScript = Join-Path $PSScriptRoot "recurrence-check.ps1"
$recLines  = & $recScript *>&1 | ForEach-Object { "$_" }
$recLines | ForEach-Object { Out "  $_" }
$recFailed = @($recLines | Where-Object { $_ -match '^\[FAIL\]' })
$recSymbol = if ($recFailed.Count -eq 0) { $iconOk } else { $iconWarn }
Out ""
Out "  $recSymbol Recurrence-check: $($recFailed.Count) guard(s) failed"

# =====================================================================
# STEP 3: Canonical-age, placeholder date, missing date (Tier A -- new)
# =====================================================================
OutSection "STEP 3: Canonical-Age and Date Hygiene (threshold: $AgeThresholdDays days)"

$scanDirs = @('docs', 'contracts') |
    ForEach-Object { Join-Path $VaultPath $_ } |
    Where-Object { Test-Path $_ }
$allMd = @()
foreach ($d in $scanDirs) {
    $allMd += Get-ChildItem $d -Recurse -Filter '*.md' -File
}

$staleCanonical  = [System.Collections.Generic.List[object]]::new()
$placeholderDates = [System.Collections.Generic.List[string]]::new()
$missingDates    = [System.Collections.Generic.List[string]]::new()
$malformedStatus = [System.Collections.Generic.List[string]]::new()

foreach ($f in $allMd) {
    $fm  = Get-Frontmatter $f.FullName
    $rel = $f.FullName.Substring($VaultPath.Length + 1) -replace '\\', '/'

    # --- malformed status: quoted or pipe-separated ---
    $sv = $fm['status']
    if ($sv) {
        if ($sv -match "^[`"']" -or $sv -match "[`"']$" -or $sv -match '\|') {
            [void]$malformedStatus.Add("$rel  (status: $sv)")
        }
    }

    # --- canonical-age checks ---
    if ($sv -ne 'canonical') { continue }

    $lrVal = $fm['last_reviewed']

    if (-not $lrVal -or $lrVal -eq '') {
        [void]$missingDates.Add($rel)
        continue
    }
    if ($lrVal -match '^YYYY-MM-DD') {
        [void]$placeholderDates.Add($rel)
        continue
    }
    $parsed = [datetime]::MinValue
    $ok = [datetime]::TryParseExact(
        $lrVal, 'yyyy-MM-dd', $null,
        [System.Globalization.DateTimeStyles]::None,
        [ref]$parsed
    )
    if ($ok -and $parsed -lt $cutoff) {
        [void]$staleCanonical.Add([PSCustomObject]@{
            Path = $rel
            Date = $parsed
            Age  = ($today - $parsed).Days
        })
    }
}

$staleCanonical = @($staleCanonical | Sort-Object Age -Descending)

Out "  Canonical docs older than $AgeThresholdDays days: $($staleCanonical.Count)"
if ($staleCanonical.Count -gt 0) {
    Out "  (Review or open a scribe case -- NOT auto-fixed by this script)"
    foreach ($s in $staleCanonical) {
        Out ("  {0,4}d  {1}" -f $s.Age, $s.Path)
    }
}
Out ""
Out "  Placeholder last_reviewed (YYYY-MM-DD literal): $($placeholderDates.Count)"
foreach ($p in $placeholderDates) { Out "  $iconBull $p" }
Out ""
Out "  Missing last_reviewed entirely: $($missingDates.Count)"
foreach ($m in $missingDates) { Out "  $iconBull $m" }

# =====================================================================
# STEP 4: Malformed status values (Tier A -- new)
# =====================================================================
OutSection "STEP 4: Malformed Status Values"
Out "  Quoted or pipe-separated status: $($malformedStatus.Count)"
foreach ($ms in $malformedStatus) { Out "  $iconBull $ms" }

# =====================================================================
# SUMMARY
# =====================================================================
OutSection "SUMMARY"
$ageSymbol  = if ($staleCanonical.Count -eq 0) { $iconOk } else { $iconWarn }
$dateSymbol = if ($placeholderDates.Count -eq 0 -and $missingDates.Count -eq 0) { $iconOk } else { $iconWarn }
$msSymbol   = if ($malformedStatus.Count -eq 0) { $iconOk } else { $iconWarn }
Out "  $lintSymbol  Lint:              orphans=$orphanCount  broken=$brokenCount  missing-tags=$missingTagsCount"
Out "  $recSymbol  Governance:        $($recFailed.Count) guard(s) failed"
Out "  $ageSymbol  Canonical age:     $($staleCanonical.Count) doc(s) older than $AgeThresholdDays days"
Out "  $dateSymbol  Date hygiene:      $($placeholderDates.Count) placeholder + $($missingDates.Count) missing last_reviewed"
Out "  $msSymbol  Malformed status:  $($malformedStatus.Count) doc(s)"
Out ""
Out "  Tier C (agent/scribe required): semantic doc-code drift is not detected by this script."
Out "  Known drift: see docs/cases/plt-case-non-complete-audit-2026-06-08.md"
Out ""
Out "  Next steps:"
Out "    -Refresh      regen CASE_REGISTRY.md + frontmatter (Tier B safe fix)"
Out "    -SaveReport   save this report to docs/cases/vault-hygiene-$dateStamp.md"
Out "    Tier C items  open a case + assign scribe agent for semantic drift"

# =====================================================================
# OPTIONAL: save report
# =====================================================================
if ($SaveReport) {
    $reportPath = Join-Path $VaultPath "docs\cases\vault-hygiene-$dateStamp.md"
    $bt = [char]0x60
    $header = @(
        "---",
        "status: under-review",
        "last_reviewed: $dateStamp",
        "scope: ecosystem",
        "---",
        "",
        "# Vault Hygiene Report -- $dateStamp",
        "",
        "Generated by: ${bt}${bt}.\scripts\vault-hygiene.ps1 -SaveReport${bt}${bt}",
        ""
    )
    $body = ($header + @($reportLines)) -join "`n"
    [System.IO.File]::WriteAllText($reportPath, $body, [System.Text.Encoding]::UTF8)
    Out ""
    Out "$iconOk  Report saved: $reportPath"
    Out "  Stage with: git add docs/cases/vault-hygiene-$dateStamp.md"
}

exit 0
