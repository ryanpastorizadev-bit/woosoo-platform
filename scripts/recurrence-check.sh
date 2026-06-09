#!/usr/bin/env bash
# Woosoo recurrence-check (bash) - mechanical guards against previously-solved failure modes.
#
# Companion to scripts/recurrence-check.ps1 (the authoritative full gate on Windows). This bash
# version runs the cross-clone-portable detectors natively and defers the two PowerShell-only
# detectors to pwsh when present, otherwise prints an explicit SKIP (no silent cap).
# Wired into pre-merge-check.sh after the per-app case block. Exit 0 = pass; non-zero = a guard fired.
#
# Native (portable):  CHK-PS-ASCII, CHK-STATUS-CLASSIFY (grep half), CHK-WIKILINK-RELATIVE,
#                     CHK-CANVAS-TRACKED, CHK-REGISTRY-SUMMARY
# pwsh-only (deferred): CHK-PS-PARSE, CHK-STATUS-CLASSIFY (regression-test half)

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || { echo "ERROR: cannot cd to repo root" >&2; exit 2; }

FAILED=()
pass() { echo "[PASS] $1 - $2"; }
fail() { FAILED+=("$1"); echo "[FAIL] $1"; shift; for l in "$@"; do echo "         $l"; done; }
skip() { echo "[SKIP] $1 - $2"; }

# --- CHK-PS-ASCII ----------------------------------------------------------------------------
ascii_hits="$(grep -rlnP '[^\x00-\x7F]' --include='*.ps1' scripts 2>/dev/null || true)"
if [[ -z "$ascii_hits" ]]; then
  pass "CHK-PS-ASCII" "all scripts/**/*.ps1 ASCII-only"
else
  fail "CHK-PS-ASCII" $ascii_hits
fi

# --- CHK-STATUS-CLASSIFY (grep half) ---------------------------------------------------------
# Registry must not classify status via an unanchored -match against a status word.
classify_hits=""
if [[ -f scripts/obsidian-case-registry.ps1 ]]; then
  classify_hits="$(grep -nE '\-match' scripts/obsidian-case-registry.ps1 \
    | grep -E 'COMPLETE|IN_PROGRESS|BLOCKED' \
    | grep -v '\^' || true)"
else
  classify_hits="obsidian-case-registry.ps1 not found"
fi
if [[ -z "$classify_hits" ]]; then
  pass "CHK-STATUS-CLASSIFY" "registry anchored (grep half; test half via pwsh below)"
else
  fail "CHK-STATUS-CLASSIFY" "$classify_hits"
fi

# --- CHK-WIKILINK-RELATIVE -------------------------------------------------------------------
# Ignore example links inside code (fenced ``` blocks + inline `...` spans): the L-004 ledger
# entry and templates legitimately quote `[[../FOO]]` as the anti-pattern to avoid.
md_files="$(find docs -name '*.md' -type f 2>/dev/null)"
wikilink_hits=""
if [[ -n "$md_files" ]]; then
  wikilink_hits="$(awk '
    FNR==1 { infence=0 }
    /^[[:space:]]*```/ { infence = !infence; next }
    infence { next }
    { line=$0; gsub(/`[^`]*`/, "", line); if (line ~ /\[\[\.\.\//) print FILENAME":"FNR": "$0 }
  ' $md_files)"
fi
if [[ -z "$wikilink_hits" ]]; then
  pass "CHK-WIKILINK-RELATIVE" "0 relative [[../ ]] wikilinks in docs/**/*.md"
else
  fail "CHK-WIKILINK-RELATIVE" "$wikilink_hits"
fi

# --- CHK-CANVAS-TRACKED ----------------------------------------------------------------------
canvas_violations=()
for c in docs/architecture/SYSTEM_MAP.canvas docs/cases/DEPLOY_SEQUENCE.canvas; do
  if [[ ! -f "$c" ]]; then
    canvas_violations+=("$c missing on disk")
    continue
  fi
  if git -C "$ROOT_DIR" check-ignore -q "$c"; then
    canvas_violations+=("$c is git-ignored (restore the !-negation in .gitignore)")
  fi
done
if [[ ${#canvas_violations[@]} -eq 0 ]]; then
  pass "CHK-CANVAS-TRACKED" "hub canvases committable (not ignored)"
else
  fail "CHK-CANVAS-TRACKED" "${canvas_violations[@]}"
fi

# --- CHK-REGISTRY-SUMMARY --------------------------------------------------------------------
summary_hits=""
if [[ -f docs/cases/CASE_REGISTRY.md ]]; then
  summary_hits="$(grep -nE '\|[[:space:]]*(app|run_status|tier|next_agent|branch|interrupted|scope|last_reviewed|tags)[[:space:]]*:[[:space:]]' docs/cases/CASE_REGISTRY.md || true)"
else
  summary_hits="CASE_REGISTRY.md not found"
fi
if [[ -z "$summary_hits" ]]; then
  pass "CHK-REGISTRY-SUMMARY" "no frontmatter key leaked as a case summary"
else
  fail "CHK-REGISTRY-SUMMARY" "$summary_hits"
fi

# --- pwsh-only detectors ---------------------------------------------------------------------
PWSH="$(command -v pwsh || true)"
if [[ -n "$PWSH" ]]; then
  # CHK-PS-PARSE
  parse_out="$("$PWSH" -NoProfile -NonInteractive -Command '
    $bad = 0
    Get-ChildItem -Path scripts -Recurse -File | Where-Object { $_.Extension -eq ".ps1" } | ForEach-Object {
      $t = $null; $e = $null
      [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$t, [ref]$e)
      if ($e -and $e.Count -gt 0) { Write-Output ("{0}: {1} error(s)" -f $_.FullName, $e.Count); $bad++ }
    }
    exit $bad
  ' 2>&1)"
  if [[ $? -eq 0 ]]; then
    pass "CHK-PS-PARSE" "all scripts/**/*.ps1 parse clean (via pwsh)"
  else
    fail "CHK-PS-PARSE" "$parse_out"
  fi
  # CHK-STATUS-CLASSIFY regression test (the test half)
  "$PWSH" -NoProfile -NonInteractive -File scripts/tests/case-status-classify.Tests.ps1 >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    pass "CHK-STATUS-CLASSIFY/test" "case-status-classify.Tests.ps1 PASS (via pwsh)"
  else
    fail "CHK-STATUS-CLASSIFY/test" "case-status-classify.Tests.ps1 regression (via pwsh)"
  fi
else
  skip "CHK-PS-PARSE" "pwsh not found; enforced by recurrence-check.ps1 on Windows"
  skip "CHK-STATUS-CLASSIFY/test" "pwsh not found; enforced by recurrence-check.ps1 on Windows"
fi

# --- Verdict ---------------------------------------------------------------------------------
echo
echo "================================================================"
if [[ ${#FAILED[@]} -eq 0 ]]; then
  echo "  recurrence-check OK (bash)"
  echo "================================================================"
  exit 0
else
  echo "  recurrence-check FAILED (bash) - ${#FAILED[@]} detector(s): ${FAILED[*]}"
  echo "  Do not weaken a detector to pass. Fix the cause (see docs/LESSONS.md)."
  echo "================================================================"
  exit 1
fi
