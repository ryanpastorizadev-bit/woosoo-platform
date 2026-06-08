# Hook: verify

**Triggers:** "verify" · "check if done" · "did it work"

Verifier proves the work before Executioner can approve it.

---

## Step 1 — Read

1. `docs/cases/<task-slug>.md`
2. `state/WORK.md` as cache
3. The case `## Verification` or validation plan

Related cases/contracts: `docs/cases/CASE_REGISTRY.md`, `docs/cases/CONTRACTS_HUB.md` (Obsidian hubs).

If `state/WORK.md` conflicts with the case file, trust the case file.

---

## Step 2 — Run Validation

Use the validation plan recorded in the case file.

Default app gates:

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa
.\scripts\pre-merge-check.ps1 -App woosoo-print-bridge
```

For `woosoo-platform` docs/orchestration-only work, use:
- stale-phrase scans
- hook existence checks
- chain-order checks
- root and nested app git status scope checks

Do not run app gates for docs-only platform work unless app code changed.

---

## Step 3 — Passing Result

If validation passes:
- append exact command output or a concise raw evidence line to case `## Verification`
- update case Run State:
  - `last_completed_agent: verifier`
  - `next_agent: executioner`
  - `interrupted: false`
  - `updated: YYYY-MM-DD`
- update `state/WORK.md`:
  - `status: verified`
  - `next_action: EXECUTIONER: review evidence and issue verdict`

---

## Step 4 — Failing Result

If validation fails:
- record the exact failing command and output in case `## Verification`
- update case Run State:
  - `status: BLOCKED`
  - `last_completed_agent: verifier`
  - `next_agent: specialist:<name>`
  - `interrupted: false`
  - `interrupt_reason: verification-failed`
- update `state/WORK.md`:
  - `status: blocked`
  - `blocking_dependencies: verification-failed`

Do not mark done. Do not hand off to Executioner.
