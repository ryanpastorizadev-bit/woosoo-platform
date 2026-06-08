---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
---

# Contracts Hub

Cross-app contracts — **canonical truth** for agents. Verify claims against code before relying on prose.

Index: [docs/README.md § Contracts](../README.md#contracts) · Home: [[OPERATOR_HOME]]

| Contract | Scope |
|----------|--------|
| [[contracts/order-state.contract\|order-state]] | `OrderStatus` enum + transitions |
| [[contracts/tablet-api.contract\|tablet-api]] | Intent-only tablet payload + backend strip |
| [[contracts/printer-relay.contract\|printer-relay]] | Heartbeat, print idempotency |
| [[contracts/auth-session.contract\|auth-session]] | Sanctum / device auth boundaries |
| [[contracts/pos-db.contract\|pos-db]] | POS DB access safety |
| [[contracts/websocket-events.contract\|websocket-events]] | Reverb channels + `broadcastAs` map |

## Agent rule

Immutable: tablet sends intent only; backend owns truth. See [AGENTS.md](../../AGENTS.md).
