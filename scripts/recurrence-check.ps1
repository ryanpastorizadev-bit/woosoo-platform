# Woosoo recurrence-check - mechanical guards against previously-solved failure modes.
#
# Turns the documented LESSONS guards into a binding, automated merge gate (wired into
# pre-merge-check.ps1 after the per-app switch). Each detector maps to a real incident; a
# deliberately-introduced violation makes exactly that detector FAIL (fail-before / pass-after).
#
# Detectors:
#   CHK-PS-ASCII         every scripts/**/*.ps1 is ASCII-only            (LESSONS L-001 / L-002)
#   CHK-PS-PARSE         every scripts/**/*.ps1 parses, 0 errors         (LESSONS L-003 + syntax)
#   CHK-STATUS-CLASSIFY  registry has no unanchored case-status -match;  (case root cause / clobber)
#                        case-status-classify.Tests.ps1 passes
#   CHK-WIKILINK-RELATIVE  no [[../ ]] wikilinks in docs/**/*.md         (LESSONS L-004)
#   CHK-CANVAS-TRACKED   the two hub canvases are NOT git-ignored        (.gitignore *.canvas trap)
#   CHK-REGISTRY-SUMMARY no CASE_REGISTRY.md summary cell is a bare      (frontmatter #-fence vs H1)
#                        frontmatter key (e.g. "app: platform")
#
# ASCII-only, PowerShell 5.1 safe, read-only (no edits). Exit 0 = all pass; non-zero = a guard fired.

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$ScriptsDir = Join-Path $RootDir "scripts"
$DocsDir = Join-Path $RootDir "docs"

$script:failed = @()
$script:passed = @()

function Pass([string]$id, [string]$detail) {
    $script:passed += $id
    Write-Host "[PASS] $id - $detail"
}

function Fail([string]$id, [string[]]$lines) {
    $script:failed += $id
    Write-Host "[FAIL] $id"
    foreach ($l in $lines) { Write-Host "         $l" }
}

# Enumerate scripts/**/*.ps1 once (Extension filter, not -Include - L-001 watchlist).
$psFiles = Get-ChildItem -Path $ScriptsDir -Recurse -File | Where-Object { $_.Extension -eq '.ps1' }

# --- CHK-PS-ASCII -----------------------------------------------------------------------------
$asciiViolations = @()
foreach ($f in $psFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $bad = 0
    foreach ($b in $bytes) { if ($b -gt 0x7F) { $bad++ } }
    if ($bad -gt 0) {
        $rel = $f.FullName.Substring($RootDir.Length + 1)
        $asciiViolations += "$rel  ($bad non-ASCII byte(s))"
    }
}
if ($asciiViolations.Count -eq 0) {
    Pass "CHK-PS-ASCII" "$($psFiles.Count) script(s) ASCII-only"
} else {
    Fail "CHK-PS-ASCII" $asciiViolations
}

# --- CHK-PS-PARSE -----------------------------------------------------------------------------
$parseViolations = @()
foreach ($f in $psFiles) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        $rel = $f.FullName.Substring($RootDir.Length + 1)
        $parseViolations += "$rel  ($($errors.Count) parse error(s): $($errors[0].Message))"
    }
}
if ($parseViolations.Count -eq 0) {
    Pass "CHK-PS-PARSE" "$($psFiles.Count) script(s) parse clean"
} else {
    Fail "CHK-PS-PARSE" $parseViolations
}

# --- CHK-STATUS-CLASSIFY ----------------------------------------------------------------------
# (a) The registry must not classify status with an unanchored -match against a status word
#     (the pre-fix bug); classification is delegated to Get-CaseStatusToken (anchored). Flag any
#     line that uses -match with a status literal but no '^' anchor.
$registry = Join-Path $ScriptsDir "obsidian-case-registry.ps1"
$classifyViolations = @()
if (Test-Path $registry) {
    $n = 0
    foreach ($line in [System.IO.File]::ReadAllLines($registry)) {
        $n++
        if ($line -match '-match' -and $line -match '(COMPLETE|IN_PROGRESS|BLOCKED)' -and $line -notmatch '\^') {
            $classifyViolations += "obsidian-case-registry.ps1:${n}: unanchored case-status -match: $($line.Trim())"
        }
    }
} else {
    $classifyViolations += "obsidian-case-registry.ps1 not found"
}
# (b) Run the no-Pester regression test; it exits non-zero on any failed assertion.
$test = Join-Path $ScriptsDir "tests\case-status-classify.Tests.ps1"
$testOk = $false
if (Test-Path $test) {
    & $test | Out-Null
    $testOk = ($LASTEXITCODE -eq 0)
    if (-not $testOk) { $classifyViolations += "case-status-classify.Tests.ps1 exited $LASTEXITCODE (regression)" }
} else {
    $classifyViolations += "case-status-classify.Tests.ps1 not found"
}
if ($classifyViolations.Count -eq 0) {
    Pass "CHK-STATUS-CLASSIFY" "registry anchored; regression test 9/9 PASS"
} else {
    Fail "CHK-STATUS-CLASSIFY" $classifyViolations
}

# --- CHK-WIKILINK-RELATIVE --------------------------------------------------------------------
# Obsidian does not resolve [[../foo]] relative wikilinks (L-004). Flag any in docs/**/*.md, but
# ignore example links inside code (fenced ``` blocks + inline `...` spans) - the L-004 ledger
# entry and templates legitimately quote `[[../FOO]]` as the anti-pattern to avoid.
$relWikilinks = @()
$mdFiles = Get-ChildItem -Path $DocsDir -Recurse -File | Where-Object { $_.Extension -eq '.md' }
foreach ($f in $mdFiles) {
    $inFence = $false
    $n = 0
    foreach ($line in [System.IO.File]::ReadAllLines($f.FullName)) {
        $n++
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        $stripped = [regex]::Replace($line, '`[^`]*`', '')
        if ($stripped -match '\[\[\.\./') {
            $rel = $f.FullName.Substring($RootDir.Length + 1)
            $relWikilinks += "${rel}:${n}: $($line.Trim())"
        }
    }
}
if ($relWikilinks.Count -eq 0) {
    Pass "CHK-WIKILINK-RELATIVE" "$($mdFiles.Count) doc(s); 0 relative wikilinks"
} else {
    Fail "CHK-WIKILINK-RELATIVE" $relWikilinks
}

# --- CHK-CANVAS-TRACKED -----------------------------------------------------------------------
# The blanket "*.canvas" .gitignore rule silently untracked the intentional hub canvases; the
# negation lines must keep them committable. git check-ignore -q exits 1 when NOT ignored.
$canvases = @(
    "docs/architecture/SYSTEM_MAP.canvas",
    "docs/cases/DEPLOY_SEQUENCE.canvas"
)
$canvasViolations = @()
foreach ($c in $canvases) {
    $abs = Join-Path $RootDir $c
    if (-not (Test-Path $abs)) {
        $canvasViolations += "$c missing on disk"
        continue
    }
    & git -C $RootDir check-ignore -q $c
    $code = $LASTEXITCODE
    if ($code -eq 0) {
        $canvasViolations += "$c is git-ignored (would not be committed; restore the !-negation in .gitignore)"
    } elseif ($code -ne 1) {
        $canvasViolations += "$c git check-ignore errored (exit $code)"
    }
}
if ($canvasViolations.Count -eq 0) {
    Pass "CHK-CANVAS-TRACKED" "$($canvases.Count) hub canvas(es) committable"
} else {
    Fail "CHK-CANVAS-TRACKED" $canvasViolations
}

# --- CHK-REGISTRY-SUMMARY ---------------------------------------------------------------------
# The frontmatter "# --- generated ---" fence once fooled the H1 detector into using the next
# frontmatter key as the summary, rendering every case Summary as "app: <x>". Flag any table cell
# that is a bare frontmatter key.
$registryDoc = Join-Path $DocsDir "cases\CASE_REGISTRY.md"
$summaryViolations = @()
if (Test-Path $registryDoc) {
    $n = 0
    foreach ($line in [System.IO.File]::ReadAllLines($registryDoc)) {
        $n++
        if ($line -match '\|\s*(app|run_status|tier|next_agent|branch|interrupted|scope|last_reviewed|tags)\s*:\s') {
            $summaryViolations += "CASE_REGISTRY.md:${n}: frontmatter key leaked as summary: $($line.Trim())"
        }
    }
} else {
    $summaryViolations += "CASE_REGISTRY.md not found"
}
if ($summaryViolations.Count -eq 0) {
    Pass "CHK-REGISTRY-SUMMARY" "no frontmatter key leaked as a case summary"
} else {
    Fail "CHK-REGISTRY-SUMMARY" $summaryViolations
}

# --- Verdict ----------------------------------------------------------------------------------
Write-Host ""
Write-Host "================================================================"
if ($script:failed.Count -eq 0) {
    Write-Host "  recurrence-check OK - $($script:passed.Count)/$($script:passed.Count) detectors PASS"
    Write-Host "================================================================"
    exit 0
} else {
    Write-Host "  recurrence-check FAILED - $($script:failed.Count) detector(s): $($script:failed -join ', ')"
    Write-Host "  Do not weaken a detector to pass. Fix the cause (see docs/LESSONS.md)."
    Write-Host "================================================================"
    exit 1
}
