---
name: nuxt-pwa-flow
description: Audit and change the Nuxt 3 tablet ordering flow — explicit transitions, Pinia reset, API contract compatibility, loading/empty/error states, tablet viewport, PWA updates.
---

# Nuxt PWA Flow (tablet-ordering-pwa)

Expected tablet ordering flow:

```txt
Welcome → Guest Counter → Package Selection → Menu Screen → Review Order →
In Session → Order Refill → Thank You → Welcome
```

## Checklist
- Transitions are explicit and one-directional; no skipping the package step.
- Pinia state resets between sessions; no table/device/session leakage.
- API payloads stay intent-only: `{ guest_count, package_id, items:[{menu_id,quantity}] }`.
- Every async path has loading / empty / error states; loading flags settle in `finally`.
- No invented backend truth states; display states map to real backend states.
- Tablet viewport and PWA update behaviour verified.
- No hardcoded LAN IPs or API/Reverb hosts.

## Commands (only if defined in package.json; Verifier runs these)
```txt
npm run build
npm run lint
npm run test
npm run typecheck
```
