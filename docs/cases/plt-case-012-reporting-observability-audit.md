---
status: canonical
last_reviewed: 2026-06-13
scope: ecosystem
---

# CASE: plt-case-012-reporting-observability-audit

## Run State
- task_slug: plt-case-012-reporting-observability-audit
- tier: 2
- branch: agent/plt-case-012-reporting-observability-audit
- status: IN_PROGRESS
- last_completed_agent: contrarian
- next_agent: specialist:dazai-docs
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-13

## Handoff
- Phase in progress: none
- Done so far: Contrarian review complete
- Exact next action: Specialist (dazai-docs) to audit pportal analytics, map each KPI to its source of truth, and document the cross-app order trace
- Working-tree state: no files edited yet
- Risks / do-not-redo: This is an audit/documentation task first. Do not wire new endpoints or dashboard features until the audit defines what the source of truth IS.

## Tier
2

## Branch
agent/plt-case-012-reporting-observability-audit

## Problem

The owner portal (`woosoo-pportal`) displays analytics, KPIs, and sales data but:
1. No audit has confirmed which Nexus table or query backs each metric.
2. There is no documented single source of truth for any reported KPI.
3. Observability is fragmented across 4 systems: Pulse (Nexus) + Bridge logs + PWA UX + Nexus
   health endpoint — no cross-app trace of an order from tablet submit → backend confirm →
   print dispatch → print ACK.

Business risk: executive decisions made on incorrect or differently-computed analytics. A "pretty
dashboard with wrong numbers" (per the Prime Directive) is worse than no dashboard.

This is Bucket C (deferred / non-blocking for current deploy), but must be completed before the
system is described as production-ready for multi-branch rollout.

## Contrarian Review

**GOAL CHECK:** Produces accurate business reporting (direct). Operational reliability (knowing
when the system is unhealthy). Small-team maintainability (one source of truth per metric). — PASS.

**Tier 2.** Audit and documentation first. Any code changes that emerge are a follow-up task.

**Risks:**
- `woosoo-pportal` is a separate repo not in scope for this governance repo. The Specialist can
  only audit through available docs; actual pportal code requires a pportal-scoped session.
- Defining "source of truth" may reveal that metrics diverge (e.g. report counts from `device_orders`
  but POS counts from `krypton_woosoo.orders`) — this is the finding we need, not a blocker.

**Success Criterion:** Task is done when `docs/reporting/REPORTING_SOURCES.md` exists, mapping
each pportal KPI to its Nexus query or POS table, with discrepancies flagged, and when
`docs/observability/CROSS_APP_TRACE.md` documents the full order → print → ACK trace with health
check commands at each step.

## Investigation

**What exists:**
- Nexus: Laravel Pulse (`/pulse` admin route), `woosoo:verify-integrity` artisan command,
  custom monitoring UI, device heartbeat storage (`/api/printer/heartbeat`)
- Bridge: posts heartbeat every 30s, local logs, `/orders` screen in operator UI
- PWA: client recovery/update/offline status UX (no backend heartbeat contract)
- Health endpoint: `GET /api/health` (includes Reverb integrity check, added NEX-CASE-006)

**What does NOT exist:**
- Cross-app order trace: tablet submit → Nexus confirm → print event created → Bridge reserved →
  printed → ACKed (no single log or dashboard spans this chain)
- pportal analytics audit: no documentation of which Nexus queries back which KPI
- Single "system healthy" indicator: must consult 4 separate systems

**Known discrepancy risk:**
- `device_orders` (Nexus) vs `krypton_woosoo.orders` (POS) — same order, two ID systems.
  Reporting that joins these incorrectly produces wrong counts.
- Print events: server-side `print_events` table vs Bridge local ACK — two views of "was this
  printed?" that may diverge on failure.

## Root Cause

The system was built incrementally across 3 independent repos. Observability was explicitly called
out as a gap in `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md §2.5` ("no cross-app
trace of an order from tablet → backend → print → ACK") but deferred pending feature stabilization.
That stabilization is now largely complete (NEX-CASE-013, TAB-CASE-010, PRN-CASE-001 all APPROVED),
making this audit appropriate now.

## Proposed Fix

### Phase 1 — Audit (Specialist: dazai-docs)

Create `docs/reporting/REPORTING_SOURCES.md`:
- List every KPI visible in pportal (from available docs / BRD / business context)
- For each: the Nexus model/table/query that backs it, whether it joins POS data, and any
  known discrepancy risk
- Flag any KPI where the computation path is NOT VERIFIED

Create `docs/observability/CROSS_APP_TRACE.md`:
- Document the full happy-path trace: tablet submit → API → Nexus DB → broadcast → print event
  created → Bridge poll → reserve → print → ACK → Nexus status updated
- For each step: the health check command or log line that confirms it succeeded
- Identify the earliest detectable failure point for each failure mode

### Phase 2 — Gap filing (follow-up, not in this case)

Once the audit identifies specific missing health checks or query inaccuracies, file targeted
follow-up cases (e.g. `nex-case-014-reporting-accuracy-fix`). Do not combine audit + fix in
this case.

## Files Changed
<!-- Filled by Specialist -->
- `docs/reporting/REPORTING_SOURCES.md` (new)
- `docs/observability/CROSS_APP_TRACE.md` (new)

## Verification

- Both files marked `status: canonical` with `last_reviewed: <date>`
- Every KPI in REPORTING_SOURCES.md has either a verified source or a NOT VERIFIED flag
- CROSS_APP_TRACE.md covers at least: order submit, confirm, print event creation, Bridge poll,
  reserve, ACK, terminal status broadcast to tablet
- Executioner confirms no KPI claims source of truth without evidence from running code or schema

## Executioner Verdict
<!-- Filled by Executioner -->

## Remaining Risks
- pportal codebase is not in this checkout. The audit may be limited to business context docs
  (BRD, ecosystem review) and Nexus-side schema. Flag any pportal-specific claims as NOT VERIFIED
  until verified against actual pportal code in a dedicated pportal session.
- If audit reveals metrics computed from `device_orders` when they should use POS data, fixing
  them is a Tier 3 change (reporting accuracy = business-critical data correctness).
