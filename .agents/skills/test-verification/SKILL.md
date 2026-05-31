---
name: test-verification
description: The evidence standard for proving a change works — raw output only, full-suite proof, exact errors, PASS/FAIL with functional proof.
---

# Test Verification

```txt
No error does not mean working.
Working means verified.
```

## Rules
- Quote raw command output verbatim (e.g. `Tests: 33 failed, 372 passed`). No arithmetic
  approximations, no paraphrasing, no rounding.
- A full unfiltered suite is the only proof of suite health. A filtered/single run proves only
  the targeted case — state that explicitly.
- If a suite has a known-red baseline, state the baseline and whether this change moved it.
- Functional proof = the feature observed working (request/response, UI state, print outcome),
  not merely "no exception".

## Required output
```md
### Commands Run
- ...
### Results
- ... (raw output)
### Warnings / Suspicious Output
- ...
### Functional Proof
- ...
### Verdict
PASS / FAIL
```
If FAIL, name the failing command and the exact error.
