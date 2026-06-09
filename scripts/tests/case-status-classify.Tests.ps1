# Regression test for Get-CaseStatusToken (anchored case-status classification).
#
# No Pester dependency (none in repo). Plain assertions; exits non-zero on any
# failure so it can gate from recurrence-check.ps1 / pre-merge-check.ps1.
#
# Proves both halves of the fix:
#   fail-before - the pre-fix unanchored, COMPLETE-first logic mis-classified a
#                 verbose IN_PROGRESS status as COMPLETE (the bug);
#   pass-after  - the real anchored classifier returns the correct leading token.

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\lib\case-status-classify.ps1')

$script:failures = 0
function Assert-Eq($expected, $actual, $label) {
    if ($expected -ne $actual) {
        Write-Host "[FAIL] $label : expected '$expected', got '$actual'"
        $script:failures++
    }
    else {
        Write-Host "[PASS] $label"
    }
}

# --- fail-before: inlined copy of the pre-fix unanchored, COMPLETE-first logic ---
# This SHOULD return COMPLETE for a verbose IN_PROGRESS status; that wrong answer
# is exactly the regression the anchored fix removes. Asserting it proves the
# test is capable of catching the bug.
function Get-StatusToken-PreFix([string]$s) {
    if ($s -match 'COMPLETE') { return 'COMPLETE' }
    elseif ($s -match 'IN_PROGRESS') { return 'IN_PROGRESS' }
    elseif ($s -match 'BLOCKED') { return 'BLOCKED' }
    return $null
}

$verbose = 'IN_PROGRESS (Stage A complete; Stage B pending)'
Assert-Eq 'COMPLETE' (Get-StatusToken-PreFix $verbose) 'fail-before: pre-fix logic mis-classifies verbose IN_PROGRESS as COMPLETE'

# --- pass-after: the real anchored classifier ---
Assert-Eq 'IN_PROGRESS' (Get-CaseStatusToken $verbose) 'pass-after: anchored classifier returns IN_PROGRESS for verbose status'
Assert-Eq 'COMPLETE'    (Get-CaseStatusToken 'COMPLETE') 'plain COMPLETE'
Assert-Eq 'IN_PROGRESS' (Get-CaseStatusToken 'IN_PROGRESS') 'plain IN_PROGRESS'
Assert-Eq 'BLOCKED'     (Get-CaseStatusToken 'BLOCKED (waiting on operator approval)') 'verbose BLOCKED'
Assert-Eq 'COMPLETE'    (Get-CaseStatusToken 'COMPLETE (closed 2026-06-08)') 'verbose COMPLETE'
Assert-Eq $null         (Get-CaseStatusToken 'APPROVED') 'non-enum APPROVED -> null'
Assert-Eq $null         (Get-CaseStatusToken '') 'empty -> null'
Assert-Eq $null         (Get-CaseStatusToken $null) 'null -> null'

if ($script:failures -gt 0) {
    Write-Host ""
    Write-Host "FAILED: $($script:failures) assertion(s)"
    exit 1
}
Write-Host ""
Write-Host "OK: all assertions passed"
exit 0
