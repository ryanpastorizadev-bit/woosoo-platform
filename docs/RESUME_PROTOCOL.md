---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Resume & Handoff Protocol

The per-task case file `docs/cases/<task-slug>.md` is the single durable source of truth. Every agent phase checkpoints to it. This protocol is **mandatory** — always resume from the case file, never restart from zero.

**Obsidian vault:** same files on disk. Use `docs/VAULT_INDEX.md` and `docs/cases/CASE_REGISTRY.md`
to find related cases; add `[[wikilinks]]` when cross-referencing. Graph navigation does not
replace `## Run State` in the case file.

---

## 1. Task slug (the resume key)

Every task has a stable slug derived from the request (kebab-case, e.g.
`fix-tablet-package-loading`). The case file is always `docs/cases/<task-slug>.md`. The slug is
the join key across runners — it must be identical no matter who is working.

If the user does not give one, derive it deterministically from the request title and state it
explicitly in the first response so the next runner derives the same slug.

## 2. Run State block (machine-readable, top of the case file)

Every case file begins (after frontmatter) with a `## Run State` block. It is the resume
header. Agents **rewrite it in full** when they finish their phase:

```md
## Run State
- task_slug: <slug>
- tier: 1 | 2 | 3
- branch: agent/<slug>            # platform governance work uses staging/orchestration-hooks
- status: IN_PROGRESS | BLOCKED | COMPLETE
- last_completed_agent: none | contrarian | specialist:<name> | verifier | executioner
- next_agent: contrarian | specialist:<name> | verifier | executioner | done
- active_runner: <runner>   # claude-code | codex | copilot | cascade | cursor
- interrupted: false | true
- interrupt_reason: none | rate-limit | context-limit | error | manual-handoff
- updated: <YYYY-MM-DD HH:MM, or date if time unknown>
```

`status: BLOCKED` means a phase started but could not finish (e.g. interrupted). `next_agent`
always points at the phase that must run next.

## 3. Mandatory pre-task check (every task)

Before doing **anything** else on any task:

1. Determine the task slug. Look for `docs/cases/<task-slug>.md`.
2. **If it exists with `status: IN_PROGRESS` or `BLOCKED`:**
   - Do **not** restart. Do **not** re-run already-completed agents. Do **not** re-triage the
     tier or change the branch unless the Contrarian phase itself is incomplete.
   - Read the Run State, every completed phase section, and the `## Handoff` note.
   - Adopt the role named in `next_agent` (see role mapping below) and continue the chain from
     exactly that point, honoring the recorded tier and branch.
   - Set `active_runner` to yourself and `interrupted: false` once you resume.
3. **If it exists with `status: COMPLETE`:** the task is done. Do not reopen unless the user
   explicitly asks for new work (which is a new slug / new case file).
4. **If it does not exist:** start fresh as the Contrarian (per the tier rules in `AGENTS.md`)
   and create the case file from `docs/cases/_TEMPLATE.md` before handing past triage.

## 4. Checkpoint discipline (what makes handoff safe)

Each agent, the moment it finishes its phase and **before** control passes to the next agent,
must write to the case file:

- its full output into the matching section (Contrarian Review / Investigation + Files Changed /
  Verification / Executioner Verdict),
- an updated `## Run State` block (`last_completed_agent`, `next_agent`, `updated`).

The chain advances only after the checkpoint is written. If a runner dies between phases, the
last checkpoint is durable and the next runner resumes cleanly. No checkpoint = the phase did
not happen.

**Helper (optional):** `bash scripts/case-status.sh <init|get|set> <slug> [key=value ...]` — PowerShell: `pwsh scripts/case-status.ps1`. Editing the case file directly is equally valid; the file is authoritative.

## 5. Interruption / rate-limit handling

If a runner detects it is being cut off (rate limit, context limit, forced stop), it must, if
it can produce any further output, write a `## Handoff` note to the case file and set
`status: BLOCKED`, `interrupted: true`, `interrupt_reason: <reason>`:

```md
## Handoff
- Phase in progress: <agent/role>
- Done so far: <concrete list>
- Exact next action: <the single next step the resuming runner should take>
- Working-tree state: <files edited but unverified; list them explicitly and cross-check with
  `git status` on the active branch (platform governance work: staging/orchestration-hooks)>
- Risks / do-not-redo: <anything the next runner must not repeat, e.g. an already-applied edit>
```

If the runner cannot emit anything (hard cutoff), the previous checkpoint + `next_agent` is the
recovery point. This is why checkpointing per phase — not just at the end — is mandatory.

## 6. Role mapping

The agent **definitions** live only in `.claude/agents/*.md`. A single Claude Code session adopts
each role in turn by invoking the matching subagent in `.claude/agents/<role>.md`.

Role names used in `next_agent`: `contrarian`, `specialist:ranpo-backend`,
`specialist:chuya-frontend`, `specialist:relay-ops`, `specialist:scribe`,
`specialist:infra`, `verifier`, `executioner`.

A resuming session does not need the original session's chat history — the case file is
sufficient and authoritative. Trust the case file over memory.

## 7. Hard rules carried across the handoff

The tier, branch, one-app-per-task scope, and contract obligations recorded at triage are
binding on every subsequent runner. A resuming runner must not silently widen scope, change the
tier, or skip a gate to "catch up". If the recorded plan is wrong, the correct action is to
re-enter the Contrarian phase explicitly and record why — not to improvise.

A task is still complete only when the Executioner records `APPROVED` in the case file and
`status: COMPLETE`.
