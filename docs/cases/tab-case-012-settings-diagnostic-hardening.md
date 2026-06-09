---
status: canonical
last_reviewed: 2026-06-09
scope: tablet-ordering-pwa
---

# CASE: tab-case-012-settings-diagnostic-hardening

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related cases: [[tab-case-009-broadcast-silent-death-detector]]

## Run State
- task_slug: tab-case-012-settings-diagnostic-hardening
- tier: 1
- branch: agent/tab-case-012-settings-diagnostic-hardening
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-09 12:00

## Tier
1

## Branch
agent/tab-case-012-settings-diagnostic-hardening

## Problem

`pages/settings.vue:1176` renders raw `testOrderError` text in a `<pre>` block inside the
`showDiagnostics` panel:
```html
<pre class="text-xs text-red-300 ...">{{ testOrderError }}</pre>
```

`settings.vue:1203` instructs the operator to enable `APP_DEBUG=true` in `.env`.

This panel is admin-gated (`showDiagnostics` flag) and not customer-facing. However:
1. Raw exception text can include stack traces and internal API paths
2. `APP_DEBUG=true` instruction normalizes a dangerous practice on live tablets

## Contrarian Review

**Verdict:** Proceed. Tier 1. Single file, UI-only. Low risk — admin-gated surface.

## Success Criterion

Task is done when: the diagnostics panel shows a normalized error summary (HTTP status +
one-line message) and the `APP_DEBUG=true` instruction is removed from the UI.

## Proposed Fix

1. Normalize `testOrderError`: extract HTTP status and a one-line message from the error,
   never display raw exception text. E.g., "HTTP 500 — Server error. Check backend logs."
2. Replace the `APP_DEBUG=true` instruction with:
   "Check backend logs or contact your system administrator."

## Files Changed

- `pages/settings.vue`

## Code Simplification

SKIPPED — Tier 1, UI-only string changes. Existing error builder simplified by removing leakage paths; no new abstractions added.

## Verification

PASS (verifier, 2026-06-09):
- `APP_DEBUG` — zero matches in settings.vue
- `fullError` — zero matches
- `headers: error` — zero matches
- `Check backend logs` — 3 matches (error builder + UI bullets)
- `errorDetails` contains only: `message`, `status`, `statusText`, `data`
- ESLint: 0 errors, 63 pre-existing warnings (none from this change)

## Documentation Sync

SKIPPED — Tier 1, admin-gated UI surface. No public docs or contracts reference the diagnostic error display behavior.

## Executioner Verdict

APPROVED (executioner, 2026-06-09): Success criterion met. Normalized error summary replaces raw exception text; APP_DEBUG=true instruction removed.

## Remaining Risks

Low. Diagnostics panel is admin-gated (showDiagnostics flag). The normalized messages may be less diagnostic for operators, but backend logs are the correct artifact for debugging.
