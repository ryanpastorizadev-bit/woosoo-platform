---
status: canonical
last_reviewed: 2026-06-15
scope: ecosystem
---

# Contract: Auth & Session (Sanctum / device auth)

**Implementation must be verified against actual code. This document records the contract.**

## Print Bridge WebSocket authentication

The Print Bridge does not participate in the standard `/broadcasting/auth` HTTP flow. Instead:
- It authenticates to the HTTP API level using a Bearer token (device auth token).
- It derives the WebSocket connection URI from the API base URL and Reverb app key.
- It subscribes to `admin.orders` as a **public channel** (no `private-` prefix).

**Important:** `admin.orders` is a public broadcast channel in the implementation. While
`routes/channels.php` defines an `is_admin` auth callback for it, this callback is only
invoked for private-channel subscriptions (those with a `private-` prefix). Public channel
subscriptions have no auth requirement at the WebSocket level.

This design is intentional for single-branch, on-premise deployments (the LAN is trusted).
**Future hardening:** When device-auth broadcasting is strengthened, `admin.orders` should
be migrated to a `PrivateChannel` with a device-auth callback to enforce authorization
at the WebSocket level.

## Rules
- Sanctum/device auth boundaries are deliberate. Cookie/session auth and device-token auth use
  distinct guards/providers per route — do not blur them.
- Cross-origin credentials are handled deliberately (explicit stateful domains, explicit CORS),
  never loosened globally for convenience.
- **Never weaken or bypass authentication or authorization** as a shortcut. Fix root causes.
- **No secret exposure.** Never print real token/session values. Never read or commit `.env`,
  `secrets/**`, `config/credentials.json`, or `storage/oauth-*.key`.
- 419 / CSRF issues are resolved by correcting session/cookie/domain alignment, not by disabling
  CSRF protection.
- Auth changes are Tier 3: require a Contrarian risk analysis and Executioner opus review.
