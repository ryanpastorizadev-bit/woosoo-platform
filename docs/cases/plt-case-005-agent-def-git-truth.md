---
status: under-review
last_reviewed: 2026-05-17
scope: woosoo-platform
---

# CASE: PLT-CASE-005 — Agent-Definition Git-Repo Wording Truth Fix

## Run State
- task_slug: plt-case-005-agent-def-git-truth
- tier: 1
- branch: staging/orchestration-hooks
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-17

## Handoff
- Phase in progress: done
- Done so far: Tier 1 chain complete (Contrarian declared Tier 1 → Specialist dazai-docs applied one edit → Verifier scans PASS → Executioner APPROVED). The single stale git-repo assertion in `.claude/agents/ranpo-backend.md:54` was reworded to git-repo-accurate wording matching _TEMPLATE.md / RESUME_PROTOCOL.md.
- Exact next action: Append PLT-CASE-005 to state/DONE.md, update state/QUEUE.md + state/WORK.md, commit the case file + remediation + state deltas, push to origin/staging/orchestration-hooks.
- Working-tree state (list edited files explicitly; cross-check with `git status`):
  - .claude/agents/ranpo-backend.md — line 53-54 reworded (git-repo-accurate; no longer asserts "not a git repo")
  - docs/cases/plt-case-005-agent-def-git-truth.md — new case file (this file)
  - state/DONE.md — PLT-CASE-005 row appended
  - state/QUEUE.md — PLT-CASE-005 recorded in Completed (recent)
  - state/WORK.md — current-task cache refreshed
- Risks / do-not-redo:
  - Do NOT widen scope beyond `.claude/agents/*.md` git-repo wording.
  - Do NOT touch app code or the excluded sibling repos.
  - Do NOT reword `.claude/agents/ranpo-backend.md:47` ("run `git diff --stat` if git is available; otherwise enumerate explicitly") — that is a conditional, not a false assertion, and is out of this case's strict scope.

---

## Tier
1 — Trivial

## Branch
staging/orchestration-hooks
<!-- Platform governance/docs work runs on the active staging/orchestration-hooks branch. App feature work uses agent/<slug> branches. -->

## Problem

`.claude/agents/ranpo-backend.md:54` instructs the Ranpo Backend specialist that the repo
"is not a git repo, so `git status` is not reliable" and to enumerate edited files for that
reason. This is false: the repository exists and is a git repo on branch
`staging/orchestration-hooks`, pushed to `origin`. It is the same documentation-truth defect
class already remediated in `docs/RESUME_PROTOCOL.md` and `docs/cases/_TEMPLATE.md` by
PLT-CASE-004 (commit b85a357), but `.claude/agents/*.md` was outside PLT-CASE-004's enumerated
scope, so PLT-CASE-004's Verifier/Executioner flagged it as a follow-up (PLT-CASE-005).

## Contrarian Review

**Conducted:** 2026-05-17 (Tier 1 — Contrarian declares tier and exits)

1. **Correct platform scope?** Yes — `woosoo-platform` governance only, strictly
   `.claude/agents/*.md` git-repo wording. No app code, no sibling repos.
2. **Already exists / already fixed?** No. The same-class fix landed in _TEMPLATE.md /
   RESUME_PROTOCOL.md under PLT-CASE-004, but the agent-definition occurrence was explicitly
   excluded there and remains uncorrected. This case closes exactly that gap.
3. **Scope exactly as described?** Yes. Grep on 2026-05-17 showed the stale assertion in
   exactly one file/line: `.claude/agents/ranpo-backend.md:54`. No other `.claude/agents/*.md`
   file carries identical phrasing (`verifier.md:34` uses `git status` legitimately as a
   command, not a false assertion).
4. **What breaks if wrong?** A resuming Ranpo Backend runner trusts a false "not a git repo"
   assertion and skips `git status` cross-checks, risking an inaccurate Files-Changed list.
   Blast radius: documentation text only, one line.
5. **Simpler path?** No simpler path; a one-line reword to match the already-canonical
   wording in _TEMPLATE.md / RESUME_PROTOCOL.md is minimal.
6. **Touches a contract, auth, state machine, payment, or print flow?** No. Pure
   documentation truth in an agent instruction file. No code path changes.
7. **Split per app?** No. Single-platform governance case, one file.

**Decision:** Proceed as **Tier 1**. Specialist: dazai-docs. Sequence per user request:
Specialist → Verifier (lightweight scan) → Executioner. Hard constraints: edit only the
git-repo wording in `.claude/agents/*.md`; no app code; no sibling repos; do not touch the
unrelated conditional phrasing on line 47.

## Investigation

- `grep -rn -i "not .*git repo|is not a git|not currently a git" .claude/agents/` →
  single hit: `.claude/agents/ranpo-backend.md:54`
  `is not a git repo, so \`git status\` is not reliable`.
- `grep -rn -i "git status" .claude/agents/` → `ranpo-backend.md:54` (the defect) and
  `verifier.md:34` (`git status` used as a legitimate command — not a false assertion, out of
  scope, left untouched).
- Canonical corrected wording already established by PLT-CASE-004:
  - `docs/cases/_TEMPLATE.md:32` — "list edited files explicitly; cross-check with `git status`".
  - `docs/RESUME_PROTOCOL.md:107-108` — "list them explicitly and cross-check with `git status`
    on the active branch (platform governance work: staging/orchestration-hooks)".
- `ranpo-backend.md:46-47` separately says "run `git diff --stat` if git is available;
  otherwise enumerate explicitly" — this is a conditional that resolves correctly (git IS
  available) and is **not** a false assertion; it is outside this case's strict scope and
  deliberately left unchanged.

## Root Cause

Same as PLT-CASE-004: the orchestration repo was bootstrapped with template/instruction text
written under the assumption it was not a git repo. The repo later became a git repo on
`staging/orchestration-hooks`. PLT-CASE-004 reconciled the protocol and case template but its
enumerated scope did not include `.claude/agents/*.md`, leaving the Ranpo Backend agent
definition with the stale assertion.

## Proposed Fix

Reword `.claude/agents/ranpo-backend.md` lines 53-54 from
"enumerate every edited file — this is not a git repo, so `git status` is not reliable"
to git-repo-accurate wording instructing explicit enumeration **and** a `git status`
cross-check, matching the corrected canonical phrasing in `_TEMPLATE.md` /
`RESUME_PROTOCOL.md`. No other file changed.

## Files Changed

- `.claude/agents/ranpo-backend.md` — lines 53-54 reworded:
  was "(enumerate every edited file — this is not a git repo, so `git status` is not
  reliable)"; now "(enumerate every edited file explicitly and cross-check with `git status`
  — this is a git repo, branch `staging/orchestration-hooks`)".

## Verification

**Conducted:** 2026-05-17 by verifier (claude-code)

### Commands Run
- `grep -rn -i "not .*git repo|is not a git|not currently a git|git status. is not reliable" .claude/agents/`
- `grep -n "this is a git repo, branch" .claude/agents/ranpo-backend.md`
- `git status --porcelain`
- `git diff --name-only | grep -E "woosoo-nexus/|tablet-ordering-pwa/|woosoo-print-bridge/"`

### Results
- Stale-phrasing scan over `.claude/agents/`: **no matches** (grep exit 1). No
  "not a git repo / `git status` is not reliable" assertion remains in any agent definition.
- Corrected wording present: `.claude/agents/ranpo-backend.md:54` →
  "explicitly and cross-check with `git status` — this is a git repo, branch".
- `git status --porcelain`: only ` M .claude/agents/ranpo-backend.md` modified (case file +
  state deltas added subsequently as part of the documented Required Next Action).
- App-code grep over changed paths: `NO app code in working tree changes`.
- Note: `git` emitted a `LF will be replaced by CRLF` advisory for the edited file — Windows
  line-ending normalization, informational only, not a content defect (same class of advisory
  recorded in PLT-CASE-004).

### Functional Proof
The Ranpo Backend agent definition no longer asserts a falsehood about the repository's git
status; it now instructs explicit enumeration plus a `git status` cross-check on
`staging/orchestration-hooks`, matching the already-canonical wording in _TEMPLATE.md /
RESUME_PROTOCOL.md. Scope confined to one agent-definition file; zero app code; sibling repos
untouched.

### Verdict
PASS

## Verifier Handoff

Task: PLT-CASE-005
App: woosoo-platform
Tier: 1
Files read: `.claude/agents/ranpo-backend.md` (+ git scan output)
Finding: The single in-scope stale git-repo assertion is corrected; no other `.claude/agents/*.md`
file carried identical phrasing; no app code touched; sibling repos untouched.
Decision: Advance to Executioner.
Risks: None to runtime — one line of agent-instruction text.
Deps: none
Next action: Executioner reviews chain + scope adherence and issues verdict, then state ledger
updates + commit + push.
Validation: Stale-phrasing grep (no matches), corrected-wording grep (present), git working-tree
scope + app-code grep.

## Specialist Handoff

Task: PLT-CASE-005
App: woosoo-platform
Tier: 1
Files read: `.claude/agents/ranpo-backend.md`, `docs/cases/_TEMPLATE.md`,
`docs/RESUME_PROTOCOL.md`, `docs/cases/plt-case-004-review-remediation.md`
Finding: Exactly one false git-repo assertion in `.claude/agents/ranpo-backend.md:54`;
canonical corrected wording already exists in _TEMPLATE.md / RESUME_PROTOCOL.md to mirror.
Decision: Applied the minimal one-line reword only; left the line-47 conditional and
`verifier.md` legitimate `git status` usage untouched; no app code; no sibling repos.
Risks: None to runtime — agent-instruction text only.
Deps: none
Next action: Verifier reruns the stale-phrasing scan and confirms no app code touched.
Validation: Stale-phrasing grep over `.claude/agents/`, corrected-wording grep, git diff scope.

## Executioner Verdict

Verdict: APPROVED

### Reason
Tier 1 chain complete and checkpointed: Contrarian declared Tier 1 with a 7-point challenge and
bounded scope, Specialist (dazai-docs) applied exactly one minimal documentation-truth edit to
`.claude/agents/ranpo-backend.md`, Verifier reran the stale-phrasing scan (no matches) and
confirmed the corrected wording is present with zero app code touched, Executioner judging now.
The fix matches the already-canonical wording PLT-CASE-004 established in _TEMPLATE.md /
RESUME_PROTOCOL.md, closing the exact follow-up PLT-CASE-004's Executioner filed. Scope was
honored strictly: only the false assertion was reworded; the out-of-scope line-47 conditional
and `verifier.md` legitimate `git status` command were correctly left untouched
(Constraint Absoluteness). No app code, no sibling repos. No REJECTED trigger present.

### Required Next Action
Append PLT-CASE-005 to state/DONE.md, record it in state/QUEUE.md Completed (recent), refresh
state/WORK.md, then commit the case file + remediation + state deltas and push to
origin/staging/orchestration-hooks as the explicit final step of this APPROVED case.

## Remaining Risks

- `.claude/agents/ranpo-backend.md:47` retains "run `git diff --stat` if git is available;
  otherwise enumerate explicitly". This is a conditional that resolves correctly (git is
  available) and is **not** a false assertion, so it was intentionally out of scope. If the
  governance team wants agent definitions to drop conditional git-availability hedging
  entirely, that is a separate, optional documentation-style cleanup — not a truth defect.
