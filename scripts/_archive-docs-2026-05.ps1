# One-shot archive script for the 2026-05-14 documentation audit.
# Moves files into archive directories and prepends archived frontmatter.
# Idempotent: if the source no longer exists, the entry is skipped.

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $PSScriptRoot
$ArchivedOn = "2026-05-14"

# Format: @{ src; dst; reason; superseded_by }
$Manifest = @(
    # ---- woosoo-nexus root ----
    @{ src = "woosoo-nexus/WORKSTREAM_DELEGATION_PROMPT.md";
       dst = "woosoo-nexus/docs/archive/2026-05/WORKSTREAM_DELEGATION_PROMPT.md";
       reason = "One-off AI delegation prompt, superseded by root AGENTS.md and per-app .agents.md.";
       superseded_by = "AGENTS.md" }

    # ---- woosoo-nexus/docs ----
    @{ src = "woosoo-nexus/docs/API_MAP.md";
       dst = "woosoo-nexus/docs/archive/2026-05/API_MAP.md";
       reason = "Ecosystem audit flags this as stale; superseded by API_CONTRACT_SYNC.md and the Nexus audit.";
       superseded_by = "woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md" }
    @{ src = "woosoo-nexus/docs/print-events-contract-plan.md";
       dst = "woosoo-nexus/docs/archive/2026-05/print-events-contract-plan.md";
       reason = "Planning doc superseded by the active print-events-contract.md and the Nexus audit.";
       superseded_by = "woosoo-nexus/docs/print-events-contract.md" }

    # ---- tablet-ordering-pwa root ----
    @{ src = "tablet-ordering-pwa/CASE_FILE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/CASE_FILE.md";
       reason = "Old case file; superseded by the Tablet PWA audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/QUICK_REF_ISSUES.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/QUICK_REF_ISSUES.md";
       reason = "Issues snapshot superseded by the Tablet PWA audit Issues-by-severity section.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/BLOATING_ANALYSIS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/BLOATING_ANALYSIS.md";
       reason = "Superseded by the Tablet PWA audit's cleanup recommendations.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/BLOATING_ANALYSIS_COMPLETE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/BLOATING_ANALYSIS_COMPLETE.md";
       reason = "Superseded by the Tablet PWA audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/COMPREHENSIVE_ISSUE_ANALYSIS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/COMPREHENSIVE_ISSUE_ANALYSIS.md";
       reason = "Superseded by the Tablet PWA audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/DEVELOPMENT_SETUP_DIAGNOSIS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/DEVELOPMENT_SETUP_DIAGNOSIS.md";
       reason = "One-off diagnosis; not maintained.";
       superseded_by = "tablet-ordering-pwa/README.md" }
    @{ src = "tablet-ordering-pwa/DOCUMENTATION_INDEX.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/DOCUMENTATION_INDEX.md";
       reason = "Superseded by the platform docs/README.md index.";
       superseded_by = "docs/README.md" }
    @{ src = "tablet-ordering-pwa/EXECUTIVE_BRIEF.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/EXECUTIVE_BRIEF.md";
       reason = "Point-in-time executive brief; superseded by audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/PRODUCTION_ARCHITECTURE_GUIDE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/PRODUCTION_ARCHITECTURE_GUIDE.md";
       reason = "Superseded by the Tablet PWA audit and the Ecosystem review.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/PRODUCTION_DEPLOYMENT_CHECKLIST.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/PRODUCTION_DEPLOYMENT_CHECKLIST.md";
       reason = "Superseded by tablet-update-contract.md and pre-merge-check.sh.";
       superseded_by = "tablet-ordering-pwa/docs/deployment/tablet-update-contract.md" }
    @{ src = "tablet-ordering-pwa/QUICK_REFERENCE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/QUICK_REFERENCE.md";
       reason = "Snapshot reference; not maintained.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/SETUP_SUMMARY.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/SETUP_SUMMARY.md";
       reason = "One-off setup summary; not maintained.";
       superseded_by = "tablet-ordering-pwa/README.md" }

    # ---- tablet-ordering-pwa/docs ----
    @{ src = "tablet-ordering-pwa/docs/IMPLEMENTATION-SUMMARY.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/IMPLEMENTATION-SUMMARY.md";
       reason = "Completed-work summary; superseded by audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/IMPLEMENTATION_SUMMARY_ORDER_RESTRICTIONS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/IMPLEMENTATION_SUMMARY_ORDER_RESTRICTIONS.md";
       reason = "Completed-work summary; behavior now part of canonical flow.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/MODERN-PACKAGE-SELECTION.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/MODERN-PACKAGE-SELECTION.md";
       reason = "Completed feature spec; ongoing behavior covered by audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/SPLIT-LAYOUT-IMPLEMENTATION.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/SPLIT-LAYOUT-IMPLEMENTATION.md";
       reason = "Completed implementation summary.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/TESTING-PACKAGE-SELECTION.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/TESTING-PACKAGE-SELECTION.md";
       reason = "Completed test plan.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/PHASE3_MANUAL_TESTING.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/PHASE3_MANUAL_TESTING.md";
       reason = "Completed test plan for finished phase.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/PACKAGE_SELECTION_RESPONSIVE_SPEC.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/PACKAGE_SELECTION_RESPONSIVE_SPEC.md";
       reason = "Completed responsive spec.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/REFACTOR_PLAN.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/REFACTOR_PLAN.md";
       reason = "Refactor plan superseded by the audit Action Items section.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/QUICK_REFERENCE_ORDER_RESTRICTIONS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/QUICK_REFERENCE_ORDER_RESTRICTIONS.md";
       reason = "Snapshot reference for completed work.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/CASE_FILE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/CASE_FILE.md";
       reason = "Old technical-review case file superseded by the Tablet PWA audit.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/ARCHITECTURE.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/ARCHITECTURE.md";
       reason = "Pre-audit architecture notes superseded by the Tablet PWA audit Runtime facts section.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/API_AND_EVENT_CONTRACTS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/API_AND_EVENT_CONTRACTS.md";
       reason = "Pre-audit contracts; superseded by audit Contracts section.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/HANDOVER_PROTOCOL.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/HANDOVER_PROTOCOL.md";
       reason = "Pre-audit handover protocol; superseded.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/PWA_OFFLINE_AND_TESTABILITY.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/PWA_OFFLINE_AND_TESTABILITY.md";
       reason = "Pre-audit offline notes; audit covers the offline contradiction.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }
    @{ src = "tablet-ordering-pwa/docs/technical-review/WORKFLOWS.md";
       dst = "tablet-ordering-pwa/docs/archive/2026-05/technical-review/WORKFLOWS.md";
       reason = "Pre-audit workflow notes; superseded.";
       superseded_by = "tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md" }

    # ---- woosoo-print-bridge root ----
    @{ src = "woosoo-print-bridge/README.md";
       dst = "woosoo-print-bridge/docs/archive/2026-05/README.md";
       reason = "Flutter starter boilerplate; not a real readme per audit.";
       superseded_by = "woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md" }
    @{ src = "woosoo-print-bridge/CASE_FILE.md";
       dst = "woosoo-print-bridge/docs/archive/2026-05/CASE_FILE.md";
       reason = "Old case file; superseded by the Print Bridge audit.";
       superseded_by = "woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md" }
)

# Operational runbook moves (NOT archived - kept as canonical operational ref)
$RunbookManifest = @(
    @{ src = "woosoo-print-bridge/PHASE2_PRINTER_SSL_RUNBOOK.md";
       dst = "woosoo-print-bridge/docs/runbooks/PHASE2_PRINTER_SSL_RUNBOOK.md";
       scope = "woosoo-print-bridge" }
)

function Move-Archive($entry) {
    $srcAbs = Join-Path $RootDir $entry.src
    $dstAbs = Join-Path $RootDir $entry.dst
    if (-not (Test-Path $srcAbs)) {
        Write-Host "  skip (missing): $($entry.src)"
        return
    }
    $dstDir = Split-Path -Parent $dstAbs
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }
    $body = Get-Content -Raw -Path $srcAbs
    $front = @"
---
status: archived
archived_reason: $($entry.reason)
superseded_by: $($entry.superseded_by)
archived_on: $ArchivedOn
---

"@
    Set-Content -Path $dstAbs -Value ($front + $body) -NoNewline
    Remove-Item -Force $srcAbs
    Write-Host "  archived: $($entry.src) -> $($entry.dst)"
}

function Move-Runbook($entry) {
    $srcAbs = Join-Path $RootDir $entry.src
    $dstAbs = Join-Path $RootDir $entry.dst
    if (-not (Test-Path $srcAbs)) {
        Write-Host "  skip (missing): $($entry.src)"
        return
    }
    $dstDir = Split-Path -Parent $dstAbs
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
    }
    $body = Get-Content -Raw -Path $srcAbs
    $front = @"
---
status: canonical
last_reviewed: $ArchivedOn
scope: $($entry.scope)
doc_kind: runbook
---

"@
    Set-Content -Path $dstAbs -Value ($front + $body) -NoNewline
    Remove-Item -Force $srcAbs
    Write-Host "  runbook moved: $($entry.src) -> $($entry.dst)"
}

Write-Host "== Archiving stale/superseded docs =="
foreach ($e in $Manifest) { Move-Archive $e }
Write-Host ""
Write-Host "== Moving operational runbooks =="
foreach ($e in $RunbookManifest) { Move-Runbook $e }
Write-Host ""
Write-Host "Done."
