---
status: canonical
scope: ecosystem
---

# Active Work State

<!-- Consult this file only after the docs/cases resume check. -->
<!-- It is a cache; docs/cases/<task-slug>.md is authoritative. -->
<!-- Rewrite the fields below when task state changes.          -->
<!-- Last updated: 2026-06-08 — pi-stability-verify.sh added; Pi Bucket B is the gate. -->
<!-- Bucket A EMPTY; promotion unblocked. Active orchestration = plt-case-stability-remediation. -->
<!-- Obsidian operator UI: pin docs/cases/OPERATOR_HOME.md (embeds this file). See docs/obsidian-setup-guide.md -->

---

## Current Task

```yaml
task_id:      plt-case-stability-remediation
status:       in_progress
tier:         2
app:          ecosystem (orchestration + Pi ops)
specialist:   operator (Pi) | per-case specialists
branch:       n/a (see sibling case branches in state/QUEUE.md)
description:  Stabilize before KDS — Pi verify NEX-014/NEX-011/INFRA-003. NEX-CASE-015 + docs #156
              COMPLETE 2026-06-07. TAB-CASE-011 landed (tablet PR #199). KDS deferred.
case_file:    docs/cases/plt-case-stability-remediation.md
next_action:  Pi: sudo bash scripts/deployment/pi-stability-verify.sh (P0/P1 auto-checks).
              Then manual P1a one-ticket smoke + RELEASE_RUNBOOK Step 5; close #140/#136 if green.
              INFRA-004 PR #45 merged. KDS blocked until Pi gates green.
obsidian:     docs/cases/OPERATOR_HOME.md (dashboard) · OPS_KANBAN.md (Pi board) · Calendar daily log
last_agent:   cursor — 2026-06-08 — pi-stability-verify.sh for P0/P1 Bucket B checks.
```

## Parallel Active — Governance Hardening (fix before KDS / Admin UI)

```yaml
task_id:      plt-case-governance-hardening-2026-06-08
status:       in_progress
tier:         3
active_runner: claude-code
case_file:    docs/cases/plt-case-governance-hardening-2026-06-08.md
done:         (Cursor) classifier regression fix (anchored Get-CaseStatusToken) + registry summary
              fix + obsidian-lint hardening + canvases + hub/callout wiring + whole-file ASCII
              cleanup of all scripts (0 parse errors) + .gitignore un-ignore for the 2 hub-linked
              canvases (were silently *.canvas-ignored). Lint 0/0/0; tests green.
              (Claude Code Tier 3, 2026-06-09) recurrence-check.{ps1,sh} built (6 detectors) + wired
              into pre-merge-check.{ps1,sh}; authority wiring done (AGENTS.md Immutable Rule mirrored
              byte-identically to .cursor/rules; executioner reject clause; AGENT_DEFAULT promoted
              rule; LESSONS Automated: pointers + L-012..L-015). Verifier PASS: 6/6 detectors,
              per-detector fail-before/pass-after proven, parity diff identical.
next_action:  Executioner verdict (final gate) on docs/cases/plt-case-governance-hardening-2026-06-08.md.
              Then Must-Fix items 5 (non-COMPLETE audit closure) + 6 (continual-learning), gated on APPROVED.
gate:         KDS (#137/#143-#148) + Admin UI (nex-case-012) stay deferred until Executioner APPROVED.
```

## Reconciliation Findings (2026-05-30) <!-- historical snapshot — not current state; see state/QUEUE.md -->

```text
DRIFT FOUND between agent-OS tracking and GitHub Issues:
- nex-case-007 (POS outbox/SessionReset) was COMPLETE+APPROVED but absent from QUEUE/DONE → recorded.
  Status: complete-landed on remote dev — still needs `php artisan pos:setup-payment-trigger` deploy.
- GH bug issues #140 (duplicate printing) and #136 (Pi build) had NO case files → registered in queue
  as NEX-CASE-011 and INFRA-CASE-003 (case stub files still to be created from _TEMPLATE).
- KDS epic (#137,#143-#148), telemetry #152, discount-sync #184, print-bridge #30, Pi panel #19
  are FEATURES → Bucket C, explicitly deferred (must NOT gate the dev→staging→main merge).
- DONE.md is under-recorded: NEX-CASE-001/008/009, TAB-CASE-001..004, PRN-CASE-001/002 are APPROVED
  but missing canonical rows → flagged for a verification backfill (not fabricated here).
- Branch divergence: nexus dev +1 / staging +6 (minor); main far behind. Realign before promote.
- Repo orgs: nexus/tablet/print-bridge = tech-artificer; platform = ryanpastorizadev-bit.
```

## Blocking Dependencies

```
none
```

## Last Agent

```
role:         cursor — 2026-06-08 — pi-stability-verify.sh (P0/P1 automated Pi checks)
left_off:     Script ready on platform dev; operator must run on Pi hardware. KDS still blocked.
files_open:   scripts/deployment/pi-stability-verify.sh, docs/cases/plt-case-stability-remediation.md
```

## On Completion of Next Task

```text
GATE MODEL (2026-05-31): nexus dev→staging ALREADY merged (nexus PR #157). Bucket A now gates
staging→main ONLY. See state/QUEUE.md for the authoritative three-bucket backlog.

BUCKET A — Stabilization (gates staging→main):
1. ✅ INFRA-CASE-003 — APPROVED 2026-06-01
2. ✅ TAB-CASE-009 — APPROVED 2026-06-01
3. ✅ NEX-CASE-013 — APPROVED 2026-06-01 (nexus PR #160 merged to dev)
4. ✅ TAB-CASE-010 — APPROVED 2026-06-02 (tablet PR #196 merged to dev)
→ BUCKET A CLEAR — staging→main promotion UNBLOCKED. See state/QUEUE.md.

BUCKET B — Deploy readiness (NON-gating ops; gates the actual Pi rollout):
→ NEX-CASE-011 POS config (disable 3rd-party POS printer on Pi — BT-only; NO Nexus code change),
  NEX-CASE-007 Pi step (`php artisan pos:setup-payment-trigger`; code already on dev+staging),
  INFRA-CASE-002 (Stage-B Pi verify), INFRA-CASE-001 (Pi migration on hardware), PRN-REBUILD-APK

BUCKET C — Deferred features (do NOT gate any promotion):
→ PLT-CASE-003, KDS epic (#137/#143-#148), telemetry #152, #184, #30, #19, NEX-CASE-010,
  NEX-CASE-012 (admin UI), tablet-screen-ui-ux-review
```

---
