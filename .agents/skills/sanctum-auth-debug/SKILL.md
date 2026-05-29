---
name: sanctum-auth-debug
description: Diagnose Sanctum/device auth issues — 419/CSRF, stateful domains, cross-origin cookies, device tokens, guard/provider mismatch — without weakening auth or exposing secrets.
---

# Sanctum Auth Debug

Use for 419 errors, CSRF mismatch, device-token problems, or guard/provider confusion.

## Checklist
- Confirm `SANCTUM_STATEFUL_DOMAINS`, session domain, and CORS config align with the caller
  origin (read config keys, not secret values).
- 419 = CSRF/session mismatch: check cookie domain, `withCredentials`, and the
  `/sanctum/csrf-cookie` round-trip ordering.
- Device-token auth vs cookie/session auth: verify the right guard/provider is used per route.
- Cross-origin credentials must be handled deliberately, not loosened globally.

## Hard rules
- Never print real token values or session contents.
- Never read or commit `.env` / keys.
- Never weaken or bypass auth as a shortcut. Fix the root cause.

See `contracts/auth-session.contract.md`.
