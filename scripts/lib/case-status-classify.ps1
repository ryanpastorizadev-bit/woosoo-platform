# Anchored leading-token classifier for case Run State "status:" values.
#
# The body "## Run State" status string is the source of truth and may carry
# parenthetical detail, e.g. "IN_PROGRESS (Stage A complete; Stage B pending)".
# Classify by the LEADING token only, so an embedded word like "complete" inside
# an IN_PROGRESS status never mis-classifies as COMPLETE (the pre-fix bug that
# made infra-case-002 render COMPLETE in CASE_REGISTRY.md).
#
# Returns one of: IN_PROGRESS | BLOCKED | COMPLETE, or $null when the leading
# token is none of these (e.g. an unfilled placeholder or a non-enum word).
#
# ASCII-only, PowerShell 5.1 safe, dependency-free, dot-sourceable.

function Get-CaseStatusToken {
    param([string]$Status)
    if (-not $Status) { return $null }
    $s = $Status.TrimStart()
    if ($s -match '^IN_PROGRESS\b') { return 'IN_PROGRESS' }
    if ($s -match '^BLOCKED\b')     { return 'BLOCKED' }
    if ($s -match '^COMPLETE\b')    { return 'COMPLETE' }
    return $null
}
