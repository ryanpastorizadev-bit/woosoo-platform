---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Contract: Auth & Session (Sanctum / device auth)

**Implementation must be verified against actual code. This document records the contract.**

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
