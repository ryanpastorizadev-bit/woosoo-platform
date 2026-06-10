---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# CASE: plt-case-vault-doc-automation

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Runbook: [[obsidian-vault-hygiene]]
- Related: [[obsidian-setup-guide]] · [[plt-case-non-complete-audit-2026-06-08]]

## Run State
- task_slug: plt-case-vault-doc-automation
- tier: 1
- branch: dev
- status: COMPLETE
- last_completed_agent: specialist:scribe
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-10 00:00

## Handoff
- Phase in progress: none
- Done so far: baseline captured, vault-hygiene.ps1 created, runbook doc created
- Exact next action: operator reviews + stages changed files; open plt-case for Tier C drift items
- Working-tree state: scripts/vault-hygiene.ps1 (new), docs/obsidian-vault-hygiene.md (new), docs/cases/plt-case-vault-doc-automation.md (new)
- Risks / do-not-redo: recurrence-check passes 6/6 with new script; do not modify existing scripts

## Tier
1

## Branch
dev

## Problem

Widespread vault doc staleness with no single operator-runnable hygiene entry-point.
Existing automation (obsidian-case-registry, obsidian-lint, recurrence-check) worked in
isolation but had no wrapper, no canonical-age detection, no placeholder-date detection,
and no operator runbook. Operator wanted automation without replacing human/scribe judgment
for semantic content accuracy.

## Success Criterion

Operator can run `.\scripts\vault-hygiene.ps1` from the platform root and get a structured
report covering: lint counts, governance gate result, canonical-age list, placeholder dates,
and malformed status values — without modifying any existing scripts or weakening any guard.

## Investigation

**Existing scripts inventoried (2026-06-10):**

| Script | Trigger | Tier |
|---|---|---|
| obsidian-case-registry.ps1 | Manual | B (safe writes) |
| obsidian-lint.ps1 | Manual | A (detect-only) |
| recurrence-check.ps1 | Manual / pre-merge | A (hard gate) |
| case-status.ps1 | Manual | B |
| obsidian-bootstrap.ps1 | Manual (once) | B |

**Gaps identified:** no unified wrapper, no canonical-age check, no placeholder-date
detector, no malformed-status check, no operator runbook.

## Baseline Findings (2026-06-10)

Captured by running existing scripts before any changes:

```
obsidian-lint.ps1:
  138 docs, 168 indexed notes
  Orphans: 1 (docs/operator/daily/2026-06-10.md — expected daily log)
  Broken links: 0
  Missing tags: 0

recurrence-check.ps1:
  6/6 guards PASS (17 scripts ASCII-only + parse-clean)

obsidian-case-registry.ps1 -SkipFrontmatter:
  101 cases: 79 complete, 20 active/blocked
```

**Additional findings from vault-hygiene.ps1 (after implementation):**

```
Canonical age (>30 days): 0 docs
Placeholder last_reviewed: 0 docs
Missing last_reviewed: 1 (docs/CASE_AUDIT_2026-05-18.md)
Malformed status: 1 (docs/archive/refactor-woosoo-nexus-n1-query-fixes-plan-2026-05-16.md — status: 'Planned')
```

These two items are minor and in non-canonical/archive files. No action required unless
the operator wants to clean them up manually.

**Known Tier C drift (not in scope for this case):**
- `infra-case-002`: DRIFT_MAJOR — see [[plt-case-non-complete-audit-2026-06-08]]

## Files Changed

| Action | Path |
|---|---|
| CREATE | `scripts/vault-hygiene.ps1` |
| CREATE | `docs/obsidian-vault-hygiene.md` |
| CREATE | `docs/cases/plt-case-vault-doc-automation.md` (this file) |

No existing scripts modified. No sibling app repos touched.

## Verification

```powershell
# Governance guards pass with new script included (18 scripts now)
.\scripts\recurrence-check.ps1
# Expected: 6/6 PASS, 18 scripts ASCII-only + parse-clean

# Wrapper runs without errors and reports correct counts
.\scripts\vault-hygiene.ps1
# Expected: lint 0 broken / 0 missing-tags, recurrence 0 failed, age 0 stale

# SaveReport path works
.\scripts\vault-hygiene.ps1 -SaveReport
# Expected: vault-hygiene-YYYY-MM-DD.md written to docs/cases/
```

All three checks passed on 2026-06-10.

## Documentation Sync

- `docs/obsidian-vault-hygiene.md` created (operator runbook with inventory, tiers, commands)
- `docs/cases/plt-case-vault-doc-automation.md` created (this file)
- `scripts/vault-hygiene.ps1` created (new wrapper)
- No existing docs required updates (new functionality; no prior docs described it)

## Executioner Verdict

> [!success] APPROVED
> All deliverables complete: baseline captured, wrapper script passes ASCII+parse guards,
> runbook doc written, case file created. No existing scripts or guards modified.
> Operator can now run `.\scripts\vault-hygiene.ps1` as a single hygiene entry-point.

## Remaining Risks

> [!warning]
> Tier C semantic drift (infra-case-002 DRIFT_MAJOR, plus older canonical docs) is
> NOT resolved by this case. Operator must open a separate plt-case per affected doc
> and assign scribe. See [[obsidian-vault-hygiene]] Tier C escalation section.
