---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Contract: POS Database Access (woosoo-nexus)

**POS DB access is high risk. Implementation must be verified against the actual schema and
code — no assumptions.**

## Rules
- **No schema assumptions.** Inspect the actual POS schema before reading or writing. Do not
  guess column/table names.
- **No destructive writes** (deletes, truncations, mass updates) without explicit written
  approval.
- **POS-first authority:** never add compensating POS deletes. If a local transaction fails,
  POS rows are authoritative — reconcile toward POS, do not "undo" POS.
- Writes must be transactional where applicable. A failure must not leave a partial order state
  split between local and POS.
- Production POS uses static IP `192.168.1.32`. Detect environment/IP mismatches; never silently
  rewrite connection config.
- Never expose POS credentials or connection secrets. Never read `.env` for this.
