---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Agent Default Instructions

Agents must prioritize correctness, validation, and maintainability over speed. A task is not considered finished simply because there are no visible errors. A task is finished only when the feature, fix, or change is verified, tested, reviewed, and confirmed to work as intended.

## Core Principle

Quality comes before speed.

Do not assume.
Do not hallucinate.
Do not skip verification.
Do not ignore warnings, errors, failed checks, suspicious behavior, inconsistent outputs, or incomplete results.

A "working feature" means the feature has been fully validated in the actual expected workflow, not merely that the code compiles or no error appears.

---

## Before Starting Any Task

Before making changes, the agent must:

1. Understand the actual requirement.
2. Inspect the relevant files, structure, dependencies, and existing patterns.
3. Search for existing skills, reusable patterns, documentation, and prior implementations.
4. Identify the simplest correct path.
5. Confirm the expected behavior and success criteria.
6. Check for related risks, including:
   - race conditions
   - async leaks
   - state mismatch
   - contract/API mismatch
   - authentication or authorization boundary issues
   - configuration drift
   - stale, duplicate, orphaned, or dead files
   - fragile assumptions
   - incomplete test coverage

---

## During Execution

Agents must make changes carefully and account for every modified file.

Every implementation must:

- follow existing architecture and code conventions
- avoid unnecessary abstractions
- avoid temporary hacks unless explicitly documented and removed before completion
- avoid bloating the codebase
- remove unused files, dead code, unused imports, abandoned helpers, temporary scripts, and irrelevant artifacts
- preserve workspace boundaries
- keep changes scoped to the task
- handle errors clearly and safely
- prevent silent failures
- avoid hiding failures behind fallback behavior unless the fallback is intentional, documented, and tested

Warnings, failed commands, failed tests, broken assumptions, strange logs, or unexpected outputs must never be ignored. They must be investigated before the task is marked complete.

---

## Verification Before Commit

Before committing, the agent must verify:

1. The intended feature or fix works through the real user/application flow.
2. All modified files are intentional and necessary.
3. No temporary, orphaned, duplicate, irrelevant, or dead files remain.
4. No dead code, unused imports, debug logs, console dumps, temporary comments, or placeholder logic remain.
5. Relevant tests pass.
6. Relevant build, lint, type-check, and formatting checks pass where available.
7. API contracts, request/response shapes, state transitions, and error handling are correct.
8. Edge cases are handled.
9. Failures are surfaced clearly, not silently ignored.
10. The implementation does not introduce security, state integrity, race condition, or configuration risks.

No error output does not mean the feature works.

A feature works only when it has been validated, verified, confirmed, reviewed, and tested against the expected behavior.

---

## Definition of Done

A task is complete only when:

- the requested behavior works as intended
- the implementation is clean and maintainable
- the workflow has been manually or automatically validated
- all known risks have been checked
- all warnings or suspicious signals have been addressed
- tests and relevant checks pass
- unnecessary files and code have been removed
- the codebase remains lean, organized, and production-ready
- the final result can be trusted without relying on assumptions

---

## Failure Signals That Must Stop Completion

The agent must not mark a task as done if any of the following are present:

- failed tests
- failed builds
- unresolved lint/type errors
- unexplained warnings
- inconsistent runtime behavior
- unverified assumptions
- skipped validation
- partial implementation
- mock success without real workflow testing
- temporary files left behind
- duplicate or dead code
- unclear error handling
- silent failure paths
- unexplained logs or strange outputs
- feature only tested at code level but not in actual flow

Any such signal must be treated as a blocker until investigated and resolved.

---

## Codebase Hygiene

Agents must actively prevent codebase bloat.

After completing the task, clean up:

- temporary files
- unused components
- abandoned scripts
- old experiments
- dead branches of logic
- duplicate helpers
- obsolete comments
- unused assets
- irrelevant documentation fragments
- debug output
- placeholder code

The repository must contain only necessary files that serve the current system.

---

## Token and Process Discipline

Agents must conserve token usage by:

- reading only relevant files first
- summarizing findings clearly
- avoiding repetitive analysis
- avoiding unnecessary rewrites
- using existing patterns before inventing new ones
- making focused changes
- documenting only what matters

However, token efficiency must never be used as an excuse to skip validation, ignore warnings, or deliver incomplete work.

---

## Final Reporting Requirement

At the end of every task, the agent must report:

1. What was changed.
2. Why it was changed.
3. What files were modified.
4. What was verified.
5. What tests/checks were run.
6. Any remaining risks or follow-up items.
7. Confirmation that cleanup was performed.

If something was not tested or verified, the agent must say so clearly. Never claim completion beyond what was actually confirmed.

---

## Prime Directive

A finished task must be a working, tested, validated, and clean implementation.

No hallucinations.
No assumptions.
No skipped checks.
No ignored warnings.
No silent failures.
No dead files.
No codebase bloat.
No fake completion.

Done means working.

---

# Extended Rules (Evidence-Derived from Production Failures)

The following rules were added after repeated agent failures caused by specific anti-patterns. Each rule names the failure pattern it prevents.

---

## Test Measurement Integrity

**Rule:** Every test count claim must quote the raw output line verbatim (e.g. `Tests: 33 failed, 372 passed`). Summary narratives without raw output are unverified and must not be accepted as evidence.

**Forbidden:**
- Arithmetic approximations: `127 − 5 + 9 = 131 ≈ 122` is not a valid proof.
- Inconsistent counts within the same report (e.g. reporting 295 passed in one section and 256 passed in another for the same run). A self-contradicting report is an unreliable report.
- Claiming a count without pasting the `Tests:` line from actual output.

**Required:**
- Before and after counts from the same configuration baseline.
- If the baseline changed between measurements (e.g. phpunit.xml edited, env variable added/removed), all prior deltas are confounded and void. State this explicitly.

---

## Full-Suite Requirement — No Filter Slices as Gates

**Rule:** A `--filter`, `--test`, `--group`, or equivalent partial run is never acceptable as the merge gate or as proof of suite health. Only the real, unfiltered full suite result counts.

**Forbidden:**
- `php artisan test --filter=SomeTest` reported as "tests pass."
- `flutter test test/specific_file_test.dart` reported as "suite green."
- Any slice result used to unblock a branch, close a task, or claim a red suite is now fixed.

**Required:**
- Full `composer test`, `npm run test`, or `flutter test` with the raw `Tests:` output line quoted.
- If a full run cannot be executed, say so explicitly and do not claim the suite is healthy.

---

## Baseline Pinning Before Measurement

**Rule:** Before measuring the effect of any fix, capture the exact working-tree state that produced the baseline count. A measurement is only valid if it was taken under the same configuration as the baseline.

**Required before each measurement:**
- `git status --porcelain` — confirms no unintended dirty files.
- Content of any configuration file that affects the run (e.g. `phpunit.xml`, `.env.testing`).

**If the config changed between runs, the comparison is void.** Do not subtract the counts. Reset to a known baseline and re-measure.

---

## Root Cause Proof Standard

**Rule:** A hypothesis is not a root cause. A root cause requires an isolation experiment with a predicted outcome.

**Proof requirements:**
1. State the precise prediction: "Fixing X will reduce Y from N to M."
2. Apply the fix in isolation (no other changes).
3. Run the full suite.
4. Compare the actual result to the prediction.
5. A fix that produces less than ~50% of the expected improvement is not the dominant cause. Reopen the hypothesis.

**Forbidden:**
- Declaring a cause "proven" based on a plausible mechanism alone.
- Accepting a narrative diagnosis without isolation evidence.
- Treating a −8 or −9 improvement as a "cascade collapse" when 90 failures were predicted to clear.
- Carrying forward a disproven diagnosis into the next fix attempt.

**Failure pattern this prevents:** Four separate root causes were each declared "definitive" and then disproven by underwhelming deltas (−5, −8, −9). Each false diagnosis consumed a full investigation cycle and introduced confounding changes.

---

## Regression Lock — A Fix Stays Fixed

**Rule:** A fix is not complete until a test makes the defect unable to return silently. The same
bug must never recur unnoticed.

**Required for every code fix:**
- Add or update a test that **fails on the pre-fix code and passes on the post-fix code** —
  capture both results (fail-before, pass-after) as evidence in the case file.
- If the defect is a contract/state invariant, add a **contract-lock test** asserting the
  invariant (e.g. "`SessionReset` is not dispatched per-order"; "the order status enum exposes no
  state outside `OrderStatus`").
- If it genuinely cannot be automated, state why and record the exact manual reproduction plus
  post-fix proof.

**Forbidden:**
- Closing a fix as "verified manually" when an automated guard was feasible.
- Re-fixing a previously "fixed" defect without first adding the regression test that should have
  caught it — **the missing test is itself the defect**.
- Drive-by edits to unrelated behaviour while fixing; they are the usual source of new issues.

---

## Destructive Git Operations Are Absolutely Forbidden

**Rule:** The following git commands must never be run on tracked files without explicit written user approval in the same conversation turn:

```
git checkout -- <file>
git restore <file>
git reset --hard
git stash (drop|pop|clear)
git clean -f
```

**Why:** Silent reverts of working changes have caused cascading loss of progress. Multiple sessions lost verified fixes (B1, B2) when an agent reverted them while claiming it had not touched those files.

**When a fix fails:**
- Revert ONLY the specific file that contains the bad fix.
- Verify the revert scope: `git diff --stat` before and after.
- Preserve all other changes.

**Never:** revert everything to HEAD as a shortcut when a single fix doesn't work.

---

## Self-Report Accuracy — Own Every File You Touch

**Rule:** Every file modified by an agent during a task must appear in that agent's final report. "I only changed file X" is a verifiable claim. If git diff shows other files changed, the report is false.

**Required at end of every task:**
- Run `git diff --stat` and include the output or a summary of it.
- If the diff shows files not mentioned in the task, explain them or revert them.

**Forbidden:**
- Claiming "no test files were modified" without checking `git diff`.
- Omitting files from the changed-files list.
- Reporting a clean working tree without running `git status`.

**Failure pattern this prevents:** An agent reverted B1 + B2 + Fix A while reporting it had "reverted only Fix A and touched no test files." The misreport invalidated all count comparisons for the remainder of the session.

---

## Constraint Absoluteness

**Rule:** When a task specifies a constraint ("read-only," "no git commands," "test files only," "no app code"), that constraint is a hard boundary. Violating it is not a judgment call.

**If a constraint makes the task impossible:** Stop and report the conflict. Do not work around it silently.

**Examples of hard constraints:**
- "Read-only diagnostic" → no file writes, no git operations.
- "Test files only" → no changes to `app/`, `config/`, `routes/`, `database/`.
- "No git commands" → no `git status`, `git add`, `git commit`, or any variant.

**Forbidden:** Applying an out-of-scope change and then mentioning it in the final report as a footnote. Scope violations must be flagged before the action, not disclosed after.

---

## Cascade vs. Per-Test Failure Classification

**Rule:** A test that passes in isolation but fails in a full suite run is **cascade-affected**, not TEST-WRONG. Do not rewrite it. Fix the upstream poisoner.

**Proof of cascade-affected status:** Run the test class alone (`--filter=ClassName`) and confirm it passes. Then run the suspected poisoner + this class together. If the class now fails, the poisoner is confirmed.

**Forbidden:**
- Rewriting a test that passes alone because it fails in the full suite.
- Classifying cascade victims as "pre-existing defects unmasked."
- Skipping isolation experiments when classifying failures.

**Failure pattern this prevents:** Tests like `Settings\ProfileUpdateTest` (passes alone, fails in full suite) were nearly rewritten. The real fix was the upstream tearDown ordering bug in `TransactionRollbackTest`.

---

## No "Pre-existing" Hand-Waves

**Rule:** "Pre-existing," "unrelated," or "minor" is not an acceptable failure classification without isolation evidence. Every failure in the target population requires a named concrete cause:

- Exact test class and method
- Exact exception class and message
- Exact file and line of the originating defect
- Proof that it is independent (isolated run result)

**Forbidden:**
- "These 26 failures are likely pre-existing and unrelated to our changes."
- "The remaining failures are a separate concern from a prior session."
- Any dismissal of a failure cluster without per-item triage.

---

## No Unverified Claim Reuse

**Rule:** If a report's claim cannot be independently verified from raw output, do not build on it in the next step. An unverified claim that contradicts verified evidence must be explicitly rejected and removed from the working model.

**Required when a report is suspicious:**
- List specific contradictions found (e.g. self-inconsistent counts, unverified file states).
- Reject the report's conclusions.
- Revert to the last verified ground truth before proceeding.

**Failure pattern this prevents:** T1 attempt #1 was rejected. T1 attempt #2 was built on a false premise from that rejected report ("RefreshDatabase doesn't run migrations" — demonstrably false from `TestCase.php:28/54`). The false premise propagated into two further failed fix attempts.

---

## Working Tree Preservation

**Rule:** The uncommitted working tree is the only copy of in-progress work until it is committed. Treat it as irreplaceable.

**Before any risky operation:**
- `git stash` (only if the stash will be explicitly restored) or `git diff > /tmp/work.patch` as a safety copy.
- Never run a destructive git operation on the assumption that "the changes are easy to redo."

**Required when an agent receives a working tree with uncommitted changes:**
- Classify each dirty file before touching anything.
- Never discard unclassified changes.

**Uncommitted-changes decision tree (run `git status` first — always):**
1. **Belongs to the active case** → keep it; it is checkpointed to the case file. Continue.
2. **Pre-existing and unrelated** to this task → do NOT bundle it. Stage only your own files by
   explicit path (`git add <path> …`). Never `git add .` / `git add -A`. List the untouched
   files in your report.
3. **An artifact you created this task and no longer need** → remove it (`dead-code-cleanup`)
   before the Verifier runs — but only files you created this task.
4. **Stray and unsafe to keep but possibly needed** → `git stash push -m "<why>" -- <paths>`
   (recoverable). Never `git stash drop|clear`, `git reset --hard`, or `git clean -fd`.
5. **At every gate handoff** → commit and push the case file (checkpoint discipline) so a
   machine switch loses at most one gate.

**End-of-task gate:** `git diff --stat` must show only declared-scope files. Any dirty file
outside the declared scope is an automatic Executioner rejection.

---

## Scope Discipline — One Variable Per Run

**Rule:** Change one thing between consecutive test runs. If two changes are applied simultaneously and the count moves unexpectedly, the cause is ambiguous.

**Required:**
- Apply Fix A alone, run the full suite, record the count.
- Apply Fix B alone on a clean baseline, run the full suite, record the count.
- Only combine fixes after each is independently validated.

**Forbidden:**
- Applying Fix A + Fix B + a config change in a single commit and then trying to diagnose why counts moved unexpectedly.

---

## Report Rejection Protocol

When an agent report contains any of the following, it must be explicitly rejected before acting on it:

| Signal | Action |
|---|---|
| Self-contradicting counts (e.g. 295 vs 256 passed in same run) | Reject; do not average or accept |
| Quoted `Tests:` line missing | Treat as unverified; request raw output |
| "pre-existing" with no isolation proof | Reject classification |
| Count improvement < expected (< 50% of predicted) | Reopen root cause |
| Claimed scope ("only touched X") inconsistent with `git diff` | Flag as misreport |
| Narrative description of a test run without raw output | Not a valid gate |
| Internal contradiction between sections | Reject entire report |

A rejected report's conclusions must not be incorporated into the working model.

---

## Woosoo-Specific Hard Rules

These rules apply in addition to all of the above, and are enforced by `AGENTS.md`.

- **POS-first:** Never add compensating POS deletes. If a local transaction fails, POS rows are authoritative. Reconcile out-of-band, never inline. (Critical Issue A)
- **Tablet sends intent only.** No pricing, tax, modifiers, totals, or POS mapping from the tablet.
- **One app per task.** Do not modify `woosoo-nexus/` and `tablet-ordering-pwa/` in the same commit.
- **Contract changes require docs first.** Any change to an API surface must be documented in the relevant audit doc before the code change is committed.
- **`feature/nexus-broadcast-integrity` must never be deleted.** It is the only copy of the `/api/health` broadcasting-integrity change, pending contract review.
- **`staging` is the real-env test target.** Never merge a red suite to staging. Never force-push staging.
