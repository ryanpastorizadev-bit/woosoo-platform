---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Operator Home

**Pin this note.** One screen for daily Woosoo orchestration in Obsidian. Embeds pull live
content from the same files agents use — no duplicate state.

Setup: [obsidian-setup-guide.md](../obsidian-setup-guide.md) · Vault: [[VAULT_INDEX]] · Cases: [[CASE_INDEX]] · All cases: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Pi board: [[OPS_KANBAN]]

---

## Right now

![[state/WORK#Current Task]]

| Open | Why |
|------|-----|
| [[plt-case-stability-remediation]] | Pi ops runbook (P0–P2) — **active orchestration** |
| [[OPS_KANBAN]] | Kanban view for Bucket B drag-track |
| [[CONTRACTS_HUB]] | Cross-app contracts (agent truth) |
| `state/QUEUE.md` | Bucket B deploy queue (embed below) |

---

## Pi ops — priority table

![[plt-case-stability-remediation#Priority order (recommended)]]

### Next actions

![[plt-case-stability-remediation#Recommended first actions]]

### P0 checklist (NEX-014)

![[plt-case-stability-remediation#P0 — NEX-014 session-419: deploy + verify on Pi (code already merged)]]

**Script:** `sudo bash scripts/deployment/pi-stability-verify.sh` (P0/P1 auto-checks on Pi)

---

## Deploy queue (Bucket B)

![[state/QUEUE#Bucket B — Deploy readiness (restaurant rollout prerequisites; NON-gating ops, not code bugs)]]

Full queue: `state/QUEUE.md` · Visual board: [[OPS_KANBAN]]

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
| New intake | Templater → `Templates/CASE_FILE.md` → `docs/cases/<slug>.md` → row in `state/QUEUE.md` |
| Daily Pi log | Calendar → today → `Templates/OPERATOR_LOG.md` → `docs/operator/daily/` |
| Link cases | `[[nex-case-014-session-domain-login-419]]` — backlinks appear automatically |
| Pi verify only | Run `pi-stability-verify.sh`; log in daily note or case `## Handoff` |
| Unblock KDS | Clear KDS § Blockers; set `status: IN_PROGRESS` in KDS Run State |

---

## Obsidian surfaces

| Surface | Use |
|---------|-----|
| **OPERATOR_HOME** (this note) | Daily landing — embeds `state/WORK`, queue, stability |
| **OPS_KANBAN** | Kanban plugin — drag Bucket B cards |
| **CONTRACTS_HUB** | Wiki-links to `contracts/*.md` |
| **CASE_INDEX** | Dataview table of canonical cases |
| **Calendar** | Daily operator logs in `docs/operator/daily/` |
| **Graph** (`Ctrl+G`) | Color groups: cases (blue), contracts (orange), state (green) |

Run state (`IN_PROGRESS`, `next_agent`) lives in each case's `## Run State` body — not YAML frontmatter.
