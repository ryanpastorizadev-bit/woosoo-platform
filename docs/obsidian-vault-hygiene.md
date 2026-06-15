---
status: canonical
last_reviewed: 2026-06-10
scope: ecosystem
---

# Vault Doc Hygiene — Operator Runbook

Companion to [[obsidian-setup-guide]]. Covers the automation layer for keeping docs
structurally consistent over time. Content accuracy (prose matching current code) is
Tier C — it requires human or scribe-agent judgment and is not automated here.

---

## Automation Inventory

| Script | Path | Trigger | Tier | Writes |
|---|---|---|---|---|
| `obsidian-bootstrap.ps1` | `scripts/` | Manual (once per machine) | B | `.obsidian/` plugins |
| `obsidian-case-registry.ps1` | `scripts/` | Manual / `-Refresh` flag | B | case frontmatter, `CASE_REGISTRY.md` |
| `obsidian-lint.ps1` | `scripts/` | Manual / via wrapper | A | nothing (report only) |
| `recurrence-check.ps1` | `scripts/` | Manual / pre-merge gate | A | nothing (exit code) |
| **`vault-hygiene.ps1`** | `scripts/` | **Manual / scheduled** | **A+B** | **nothing by default; snapshot with `-SaveReport`** |
| `case-status.ps1` | `scripts/` | Manual (resume protocol) | B | case Run State block |
| Scribe agent phase | agent workflow | Per-case, after code specialist | C | affected docs |

---

## Automation Tiers

### Tier A — Detect Only

Safe to run at any time. Reports problems; changes nothing.

| Check | What it flags | Script |
|---|---|---|
| Orphaned docs | Files with zero inbound wikilinks | `obsidian-lint.ps1` |
| Broken wikilinks | `[[target]]` with no matching file or heading | `obsidian-lint.ps1` |
| Missing tags | Case files with run-state frontmatter lacking `app/` or `status/` tags | `obsidian-lint.ps1` |
| Governance guards | Six mechanical recurrence guards (ASCII, parse, classifier, wikilinks, canvas, registry) | `recurrence-check.ps1` |
| Canonical age | `status: canonical` docs with `last_reviewed` older than N days | `vault-hygiene.ps1` |
| Placeholder dates | `last_reviewed: YYYY-MM-DD` literal (not backfilled) | `vault-hygiene.ps1` |
| Malformed status | Quoted (`'Planned'`) or pipe-separated (`canonical \| archived`) status values | `vault-hygiene.ps1` |

### Tier B — Safe Auto-Fix

Mechanical writes. Safe because output is derived from source-of-truth body text;
re-running produces no diff if the body hasn't changed.

| Action | Command | What it changes |
|---|---|---|
| Regen case frontmatter | `.\scripts\obsidian-case-registry.ps1` | YAML frontmatter derived from `## Run State` |
| Regen CASE_REGISTRY.md | `.\scripts\obsidian-case-registry.ps1` | `docs/cases/CASE_REGISTRY.md` table |
| Regen registry only | `.\scripts\obsidian-case-registry.ps1 -SkipFrontmatter` | `CASE_REGISTRY.md` only |
| Wrapper refresh | `.\scripts\vault-hygiene.ps1 -Refresh` | Runs full registry regen then all Tier A checks |

**Rule:** `## Run State` body is always the source of truth. Never hand-edit the generated
frontmatter fence — re-run the registry script instead.

### Tier C — Agent / Scribe Required

Cannot be automated. Requires reading code to verify claims.

| Situation | Who handles it |
|---|---|
| Doc prose contradicts current implementation | Scribe agent (post code-specialist) |
| Architecture doc references removed component | Open plt-case + assign scribe |
| Contract out of sync with actual API | Open case; contrarian triage first |
| DRIFT_MAJOR flagged in audit | Open plt-case referencing the audit; scribe rewrites affected doc |

**Note on case audits:** `CASE_DASHBOARD.md` is the live view (auto-updates via Dataview after each registry run). Full case audits (code correctness verification, risk narrative) are point-in-time Tier C documents — create a dated `docs/CASE_AUDIT_YYYY-MM-DD.md` when a comprehensive audit is needed, don't attempt to maintain one as a living document.

---

## Commands — Copy Paste

### Default hygiene check (read-only, Tier A)

```powershell
.\scripts\vault-hygiene.ps1
```

Run this whenever you want a quick structural health report. Nothing is written.

### After code merges — refresh registry (Tier B)

```powershell
.\scripts\vault-hygiene.ps1 -Refresh
```

Regenerates CASE_REGISTRY.md and case frontmatter from Run State bodies, then runs all
Tier A checks. Run after every batch of case file updates.

### Tighter staleness window

```powershell
.\scripts\vault-hygiene.ps1 -AgeThresholdDays 14
```

Flags canonical docs not reviewed in the last 14 days. Use before a release or audit.

### Save a dated snapshot

```powershell
.\scripts\vault-hygiene.ps1 -SaveReport
```

Writes `docs/cases/vault-hygiene-YYYY-MM-DD.md`. Stage and commit manually if you want
to preserve it. Combine with other flags:

```powershell
.\scripts\vault-hygiene.ps1 -Refresh -SaveReport
```

### Pre-merge governance gate (hard)

```powershell
.\scripts\recurrence-check.ps1
```

Exit code 0 = all 6 guards pass. This is the merge gate; `vault-hygiene.ps1` is not.
Do **not** weaken a guard to make it pass — fix the cause (see `docs/LESSONS.md`).

### Lint only

```powershell
.\scripts\obsidian-lint.ps1
```

---

## Recommended Frequency

| Cadence | Command | Why |
|---|---|---|
| After any batch of case edits | `vault-hygiene.ps1 -Refresh` | Keep registry + frontmatter current |
| Weekly or before a release | `vault-hygiene.ps1 -AgeThresholdDays 14 -SaveReport` | Catch staleness early |
| Before every merge to `dev` | `recurrence-check.ps1` | Hard governance gate |
| New machine / after Docker rebuild | `obsidian-bootstrap.ps1` | Repair junctions, reinstall plugins |

---

## Interpreting Findings

### Lint: Orphans

An **orphan** is a doc with zero inbound wikilinks. One daily log file is always expected
(today's `docs/operator/daily/YYYY-MM-DD.md`). Actionable orphans are listed under
"Actionable docs orphans" — add a wikilink from DOCS_HUB or VAULT_INDEX to fix.

Case orphans (under "Case orphans") should appear in CASE_REGISTRY. Run
`obsidian-case-registry.ps1 -SkipFrontmatter` to re-add them.

### Lint: Broken links

Zero should always be the target. A broken link means a file was renamed or deleted without
updating references. Fix by finding the new file name and updating the wikilink.

### Lint: Missing tags

Run `obsidian-case-registry.ps1` (Tier B). Tags are auto-generated from Run State — they
are never hand-edited.

### Governance guards: FAIL

Read the `[FAIL]` line for the guard ID. Each guard maps to a lesson in `docs/LESSONS.md`.
Fix the root cause; do not modify the guard.

### Canonical age

Files older than the threshold need operator review. Ask:
- Is the content still accurate? If yes, update `last_reviewed` to today.
- Has the code changed? If yes, open a plt-case and assign scribe.

Priority: contracts and deployment runbooks first; older architecture docs second.

### Placeholder / missing last_reviewed

Add a real date: `last_reviewed: YYYY-MM-DD`. Use the file's last meaningful edit date
(check `git log -- <path>`).

### Malformed status

Fix the frontmatter manually:
- `'Planned'` → remove quotes: `status: under-review` (or correct value)
- `canonical | archived | under-review` → pick one: `status: canonical`

---

## Tier C Escalation: Opening a Scribe Case

When the hygiene report flags a doc as old and you suspect code drift:

1. Open `docs/cases/plt-case-<slug>.md` from the template (`case-status.ps1 init <slug>`)
2. In `## Problem`, describe which doc is stale and what changed in code
3. Set `tier: 2`, `next_agent: contrarian`
4. Run the agent chain: contrarian → scribe specialist → verifier → executioner
5. Scribe updates the doc, verifier confirms accuracy, executioner approves

Known open drift items: see `docs/cases/plt-case-non-complete-audit-2026-06-08.md`.

---

## What This Runbook Does NOT Cover

- Semantic accuracy of doc prose vs current code (Tier C — see above)
- Obsidian plugin setup → see [[obsidian-setup-guide]]
- Daily case workflow → see [[AGENT_USAGE_GUIDE]] and [[RESUME_PROTOCOL]]
- Contract changes → Tier 3; requires contrarian + scribe + executioner chain
