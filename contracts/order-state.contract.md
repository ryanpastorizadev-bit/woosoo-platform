---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Contract: Order State (woosoo-nexus)

**Authoritative order lifecycle. Implementation must be verified against actual code in
`woosoo-nexus/` — this document records the contract, not a guess.**

## State machine

```txt
confirmed → completed
confirmed → voided
confirmed → cancelled
```

- `confirmed` — order accepted and dispatched to kitchen/print.
- `completed` — order fulfilled (terminal).
- `voided` — order voided after confirmation (terminal).
- `cancelled` — order cancelled (terminal).

This matches the canonical machine in `AGENTS.md`, `docs/AI_CONTEXT.md`, and `CLAUDE.md`:

> Order state machine: `confirmed → completed | voided | cancelled`.

## Rules
- **Do not invent backend states.** There is no `PENDING`, `READY`, `IN_PROGRESS`, or any other
  state beyond the four above. If a future state is genuinely required it is a contract change
  that must be documented here and in the relevant audit doc **before** any code change.
- Frontend/tablet display states may exist only if each maps to one of the four backend truth
  states. The tablet never owns or sends state.
- State transitions must be authorized server-side. Terminal states do not transition further.
- A failed local transaction must not leave a partial order state; POS rows remain authoritative.
