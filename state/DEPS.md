---
status: canonical
scope: ecosystem
---

# Dependency Ledger

<!-- Tracks cross-app dependencies that must be confirmed before dependent tasks begin.        -->
<!-- A task may only proceed when its blocking dep is marked `confirmed` with evidence.        -->
<!-- Updated during dependency review and verified handoff.                                   -->
<!-- Last updated: 2026-05-17                                                                  -->

---

## Status Values

| Status | Meaning |
|---|---|
| `pending` | Dependency is known but provider has not started |
| `in_progress` | Provider is working on it |
| `blocked` | Provider cannot complete yet — see Notes |
| `confirmed` | Provider output is implemented, tested, and documented |
| `rejected` | Provider output failed validation — must be redone |
| `changed` | Previously confirmed dep changed — consumers need reverification |

**Never use:** almost done · probably done · ready-ish · working locally · should be fine

---

## Dependency Records

| Dep ID | Provider App | Consumer App | Required Contract / Output | Status | Verification Evidence | Unlocks Case | Date Confirmed | Notes |
|---|---|---|---|---|---|---|---|---|
| — | — | — | No dependencies recorded yet | — | — | — | — | — |

---

## Changed Dependency Protocol

If a `confirmed` dependency changes:
1. Set its status → `changed`
2. Mark all consumer cases in `state/QUEUE.md` → `blocked`
3. Add a note: `Dep DEP-NNN changed — reverification required`
4. Update `contracts/<relevant>.contract.md`
5. Re-run provider verification
6. Re-run consumer integration check
7. Only then: set status back to `confirmed` with new evidence

---
<!--
DEP ID FORMAT: DEP-NNN (sequential, never reuse)

PROVIDER APPS:  woosoo-nexus | tablet-ordering-pwa | woosoo-print-bridge | woosoo-platform
CONSUMER APPS:  same

VERIFICATION EVIDENCE should reference:
- The specific test or build output that confirmed it
- The contract file it corresponds to (contracts/*.contract.md)
- The date and agent/runner that confirmed it
-->
