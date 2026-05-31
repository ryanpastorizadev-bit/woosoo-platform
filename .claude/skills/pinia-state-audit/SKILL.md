---
name: pinia-state-audit
description: Audit Pinia stores in tablet-ordering-pwa for stale state, session/table/device leakage, package bypass, cart validation, quantity limits, and backend-state divergence.
---

# Pinia State Audit (tablet-ordering-pwa)

## Checklist
- **Stale state:** stores fully reset on session end / new session start.
- **Leakage:** no table, device, or guest data carried across sessions.
- **Package bypass:** order cannot proceed without a selected package.
- **Cart validation:** guest-count limits, meat/side quantity limits enforced client-side as UX
  guardrails (backend remains the source of truth).
- **Backend divergence:** local cart/session state never contradicts backend truth state
  (the `OrderStatus` enum — see `contracts/order-state.contract.md`).
- Getters/actions are the single mutation path; no ad-hoc state writes from components.
