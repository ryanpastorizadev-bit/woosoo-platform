---
name: agent-sequence
description: The mandatory Woosoo 4-agent sequence, triage tiers, branching rule, and the final Agent Chain output block every task must end with.
---

# Agent Sequence (Lite — 4 agents)

Mandatory order for every non-trivial task:

```txt
1. Contrarian   — challenge the request, classify tier, decide path
2. Specialist   — implement (ranpo-backend | chuya-frontend | relay-ops | dazai-docs | infra)
3. Verifier     — prove it works (tests / build / lint / health)
4. Executioner  — final verdict gate
```

First agent is always Contrarian. Last is always Executioner. A task is complete only when the
Executioner returns `APPROVED`.

## Triage tiers

- **Tier 1 — Trivial:** `Specialist → Executioner`. Contrarian declares Tier 1 and exits. No
  Verifier if no code path changed.
- **Tier 2 — Standard (default):** `Contrarian → Specialist → Verifier → Executioner`.
- **Tier 3 — High-risk:** `Contrarian (deep) → Specialist → Verifier → Executioner`. Written
  risk analysis required; Specialist references `contracts/*.md`; Executioner uses opus.

## Branching

Tier 2 / Tier 3 run on a dedicated branch `agent/<short-task-slug>` (when the repo is a git
repo). Tier 1 may run on the current working branch. Merge only after `APPROVED`. On `REJECTED`,
restore the working tree (`git restore .`) before any fix-forward, and only fix-forward after
the Verifier re-runs clean.

## Resume & checkpointing (mandatory — see `docs/RESUME_PROTOCOL.md`)

The chain must survive an interrupted runner (rate limit, context limit, handoff to Codex or
Copilot). The durable, runner-agnostic state lives in `docs/cases/<task-slug>.md`.

- **Before starting any task:** check `docs/cases/<task-slug>.md`. If `status: IN_PROGRESS` or
  `BLOCKED`, do not restart — read its `## Run State` + `## Handoff`, adopt the `next_agent`
  role, and continue from there with the recorded tier and branch.
- **When you finish your phase:** write your full output **and** a refreshed `## Run State`
  block to the case file *before* handing off. The chain only advances after this checkpoint.
- **If you are being cut off:** write a `## Handoff` note, set `status: BLOCKED`,
  `interrupted: true`, `interrupt_reason: <reason>`.
- Trust the case file over chat memory. A resuming runner needs only the case file.

## Mandatory final output

Every task must end with this block:

```md
## Agent Chain
- Tier: 1 / 2 / 3
- Branch: agent/<slug>
- Contrarian:
- Specialist:
- Verifier:
- Executioner:

## Files Changed
- ...

## Verification
- ...

## Executioner Verdict
APPROVED / REJECTED / SPLIT_REQUIRED
```

This same information must also be checkpointed into `docs/cases/<task-slug>.md` (the `## Run
State` block + matching phase sections) so any runner can resume. On `APPROVED`, set the case
file `status: COMPLETE`.

`No error does not mean working. Working means verified.`
