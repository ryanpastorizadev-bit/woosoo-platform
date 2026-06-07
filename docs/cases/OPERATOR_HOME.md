---
status: canonical
last_reviewed: 2026-06-07
scope: ecosystem
---

# Operator Home

**Pin this note.** One screen for daily Woosoo orchestration in Obsidian. Embeds pull live
content from the same files agents use — no duplicate state.

Setup: [obsidian-setup-guide.md](../obsidian-setup-guide.md) · All cases: [[CASE_INDEX]]

---

## Right now

![[state/WORK#Current Task]]

| Open | Why |
|------|-----|
| [[plt-case-stability-remediation]] | Pi ops runbook (P0–P2) |
| [[kds-implementation-plan]] | Deferred spec + blockers |
| [[nex-case-015-tablet-intent-payload-hardening]] | P2 code — intent payload hardening |
| `state/QUEUE.md` | Bucket B deploy queue (embed below) |

---

## Pi ops — priority table

![[plt-case-stability-remediation#Priority order (recommended)]]

### Next actions

![[plt-case-stability-remediation#Recommended first actions]]

### P0 checklist (NEX-014)

![[plt-case-stability-remediation#P0 — NEX-014 session-419: deploy + verify on Pi (code already merged)]]

---

## Deploy queue (Bucket B)

![[state/QUEUE#Bucket B — Deploy readiness (restaurant rollout prerequisites; NON-gating ops, not code bugs)]]

Full queue: `state/QUEUE.md`

---

## KDS — blocked until stability green

![[kds-implementation-plan#Run State]]

![[kds-implementation-plan#Blockers (resume protocol)]]

---

## Case index (Dataview)

![[CASE_INDEX#Recently reviewed cases]]

---

## Quick actions

| I want to… | Do this |
|------------|---------|
| Start agents | Claude Code: `work` or `execute <slug>` — case file `## Run State` is resume point |
| New intake | Templater → `Templates/CASE_FILE.md` → save as `docs/cases/<slug>.md` → add row in `state/QUEUE.md` |
| Link cases | `[[nex-case-014-session-domain-login-419]]` — backlinks appear automatically |
| Pi verify only | Read stability case P0/P1 sections; log results in case `## Handoff` or operator notes |
| Unblock KDS | Clear all non-COMPLETE rows in KDS § Blockers; set `status: IN_PROGRESS` in KDS Run State |

---

## Obsidian tips

- **Graph** (`Ctrl+G`): filter `stability` or `kds` to see dependency edges
- **Split pane**: this note left, active case right
- **Tags** (optional): `#ops/pi` `#priority/p0` on operator log lines inside case files
- Run state (`IN_PROGRESS`, `next_agent`) lives in each case's `## Run State` body — not in YAML frontmatter
