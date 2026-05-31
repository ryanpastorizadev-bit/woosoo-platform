---
name: documentation-truth-audit
description: Ensure docs match real code — commands exist, features exist, states are correct, outdated docs are consolidated or deprecated, no conflicting duplicates, no invented completion claims.
---

# Documentation Truth Audit

## Checklist
- Every command shown in docs actually exists and runs.
- Every feature/endpoint/state described actually exists in code. Verify before writing.
- Order state machine matches the `OrderStatus` enum / `contracts/order-state.contract.md`
  everywhere — no doc invents states or contradicts the enum.
- Outdated docs are consolidated or marked `status: archived` — never left as conflicting
  duplicates of canonical content.
- No "implemented / done / complete" claim without verifiable proof.
- `docs/README.md` index stays in sync with canonical docs added or retired.
- Frontmatter present and correct: `status`, `last_reviewed`, `scope`.
