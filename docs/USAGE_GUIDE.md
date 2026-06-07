---
status: canonical
last_reviewed: 2026-05-31
scope: ecosystem
---

# Usage Guide — Driving the Woosoo 4-Agent System

Operator-facing runbook. This guide **navigates**; the authoritative rules live in the files it
points to (`AGENTS.md`, `docs/AGENT_DEFAULT_INSTRUCTIONS.md`, `docs/RESUME_PROTOCOL.md`,
`PROTOCOL.md`). Where this guide and those files appear to differ, the rule files win.

## 1. How to drive it

You type a short phrase; one chatbox plays all four roles — **Contrarian → Specialist → Verifier
→ Executioner** — and the durable state lives in `docs/cases/<slug>.md`, not the chat. A task is
done only when the **Executioner returns `APPROVED`**.

| You type | What happens |
| -------- | ------------ |
| `intake this: <bug/feature>` | Fresh case — Contrarian challenges, sets tier, picks specialist |
| `work` / `continue` / `next` / `go` | Resume the active/queued task from its last gate |
| `status` | Print in-progress work + last gate |
| `triage` / `make a case` | Convert a raw report into a case file |
| `execute <case>` | Run the implementation chain |
| `verify` / `did it work` | Run the Verifier (tests/build/lint) |
| `review` | Inspect partial/unfinished work |
| `blocked` / `unlock` | Dependency check |
| `handover` / `sync` | Write the post-completion handover |

Full hook map + tiers + routing: `AGENTS.md`. Concise routing reference: `PROTOCOL.md`.

## 2. Continuing from a session summary

A chat summary (or `CLAUDE.local.md`) is **not** durable state — the case file is. To continue
correctly, convert each open item into the case system:

1. Split the summary into individual tasks — **one app each**.
2. `intake this: <one item>` → the Contrarian triages it and creates `docs/cases/<slug>.md`.
3. Backlog with ordering/blockers → rows in `state/QUEUE.md` (+ `state/DEPS.md` for cross-app
   dependencies).
4. `work` / `what's next` resumes from the case files + queue.
5. If the summary is old, the case is created with a **"verify against current code"** note —
   never assume a stale item is still open.

## 3. Common scenarios → where the protocol lives

These are codified and enforced at the gates; this table is the index.

| Scenario | Protocol |
| -------- | -------- |
| **Uncommitted changes** in the working tree | `AGENT_DEFAULT_INSTRUCTIONS.md` → *Working Tree Preservation* (decision tree; stage only your files by path; never `git add .`) |
| **A fix must not recur** | *Regression Lock — A Fix Stays Fixed* (fail-before/pass-after test required) + *Root Cause Proof Standard* |
| **A fix failed / REJECTED** | Revert only the bad file; re-run Verifier clean before fix-forward. Never `git reset --hard` / `git clean -fd` (*Destructive Git Operations Are Absolutely Forbidden*) |
| **Work spans two apps** | Executioner returns `SPLIT_REQUIRED`; split into per-app cases (`AGENTS.md` → Workspace Split Rule) |
| **Interrupted / machine switch** | `git pull && git switch agent/<slug>`, then `resume` — case file's `next_agent` is the resume point (`RESUME_PROTOCOL.md`) |
| **Touching auth/POS/order-state/payment/print/deploy** | Auto-escalates to Tier 3 (deep Contrarian + risk analysis + contract reference) |
| **Test counts look off / "pre-existing" claims** | *Report Rejection Protocol*, *Full-Suite Requirement*, *No "Pre-existing" Hand-Waves* |

## 4. Skills

The Contrarian picks from the **scenario → skill map** in `AGENTS.md` → *Skill Discovery*; the
Specialist loads only those. `agent-sequence` is mandatory every task; `test-verification` and
`dead-code-cleanup` on every code task.

## 5. How docs stay current — and keep improving (anti-degradation loop)

Nothing auto-updates. `hooks/*.md` are markdown playbooks, not executable hooks; README/CHANGELOG
do not self-write. Currency is **gate-enforced**, and the system is designed to ratchet forward,
not rot:

- **Checkpoint discipline** — every agent writes its output + `## Run State` to the case file
  before handing off. No checkpoint = the phase did not happen.
- **Handover + `state/DONE.md`** — completion is recorded; knowledge is captured, not lost.
- **Regression Lock** — a fixed defect gets a test, so it cannot silently return.
- **Documentation-truth gate** — `scribe` + `documentation-truth-audit` + the Executioner
  **reject** a task whose docs claim things the code doesn't do, link to missing files, or leave
  the case file unupdated. (This is what catches stale inventories and dead links.)
- **Evidence-derived rules** — when a new failure mode appears, add a rule to the *Extended Rules
  (Evidence-Derived from Production Failures)* section of `AGENT_DEFAULT_INSTRUCTIONS.md` so it
  cannot recur. The ruleset only grows tighter.
- **Periodic orchestration audit** — re-run the structural checks (agents/skills/hooks resolve,
  no dead links, docs match code) when the system changes; fix drift immediately.

The rule of thumb: **every fix leaves behind a guard** (a test, a rule, or a corrected doc) so the
same problem cannot return — that is what keeps the system improving rather than degrading.
