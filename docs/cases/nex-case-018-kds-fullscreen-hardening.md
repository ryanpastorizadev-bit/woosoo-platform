---
status: canonical
last_reviewed: 2026-06-09
scope: woosoo-nexus
---

# CASE: nex-case-018-kds-fullscreen-hardening

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related cases: [[nex-case-016-kds-ui-only]]

## Run State
- task_slug: nex-case-018-kds-fullscreen-hardening
- tier: 1
- branch: agent/nex-case-018-kds-fullscreen-hardening
- status: IN_PROGRESS
- last_completed_agent: specialist:ranpo-backend
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-09 12:00

## Tier
1

## Branch
agent/nex-case-018-kds-fullscreen-hardening

## Problem

`Display.vue` IS coded for fullscreen (100dvw × 100dvh, no AppLayout wrapper, no letterbox).
Two issues remain:

**Issue A — 20px inner gutters read as "padding borders":**
- `kds-subbar { padding: 8px 20px }`
- `kds-grid-wrap { padding: 14px 20px 18px }`
- `.kds-command { padding: 0 20px }`
All content is inset 20px from every edge. On a kitchen display, this looks like borders/padding
rather than a deliberate design choice.

**Issue B — `:has()` fragility on Pi tablet Android WebView:**
The fullscreen reset uses `html:has(.kds-viewport), body:has(.kds-viewport)`. If the Pi tablet's
Android WebView doesn't support CSS `:has()`, the reset silently fails and the light cream body
gradient (#f8f4ed) bleeds around the dark board.

## Contrarian Review

**Verdict:** Proceed. Tier 1. Single file. Both changes confined to Display.vue.
User confirmed (c): both gutter reduction + kiosk-proof `:has()` replacement.

## Success Criterion

Task is done when: KDS board renders edge-to-edge content (≤8px gutters) and the
fullscreen body reset uses `body.kds-active` class (no `:has()` dependency).

## Proposed Fix (confirmed by user)

**Fix 1 — Reduce gutters:**
```css
.kds-subbar    { padding: 8px 8px }    /* was 8px 20px */
.kds-grid-wrap { padding: 14px 8px 18px } /* was 14px 20px */
.kds-command   { padding: 0 8px }      /* was 0 20px */
```

**Fix 2 — Replace :has() with body class:**
```js
onMounted(() => document.body.classList.add('kds-active'))
onUnmounted(() => document.body.classList.remove('kds-active'))
```
```css
/* Drop html:has()/body:has() block */
body.kds-active {
  overflow: hidden; margin: 0;
  width: 100%; height: 100%;
  background: var(--kds-bg0);
}
```

## Files Changed

- `resources/js/pages/KDS/Display.vue`

## Code Simplification
## Verification
## Documentation Sync
## Executioner Verdict
## Remaining Risks
