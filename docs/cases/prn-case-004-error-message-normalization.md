---
status: canonical
last_reviewed: 2026-06-09
scope: woosoo-print-bridge
---

# CASE: prn-case-004-error-message-normalization

## Vault links
- Registry: [[CASE_REGISTRY]] · Contracts: [[CONTRACTS_HUB]] · Home: [[OPERATOR_HOME]]
- Related cases: [[prn-case-001-print-determinism]]

## Run State
- task_slug: prn-case-004-error-message-normalization
- tier: 1
- branch: agent/prn-case-004-error-message-normalization
- status: IN_PROGRESS
- last_completed_agent: specialist:relay-ops
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-09 13:00

## Tier
1

## Branch
agent/prn-case-004-error-message-normalization

## Problem

`lib/ui/screens/queue_screen.dart:146,395` display raw `$e` exception objects in operator UI.
`lib/services/reverb_service.dart:137` includes raw TLS handshake details in release-mode error
text visible to the operator.

Raw exception output is not actionable ("HandshakeException: Connection terminated during
handshake") and exposes implementation details. Should be normalized to clear operator actions.

## Contrarian Review

**Verdict:** Proceed. Tier 1. UI string changes only, no logic changes.

## Success Criterion

Task is done when: all operator-visible exception displays show a normalized, actionable message
(e.g., "Connection failed — check Wi-Fi") with no raw exception text.

## Proposed Fix

Replace `$e` / `$e.toString()` with a helper that maps exception types to operator messages:
- Network/socket exceptions → "Connection failed — check Wi-Fi or network"
- TLS/certificate exceptions → "Secure connection error — verify certificate"
- Generic fallback → "An error occurred. Restart the app if it persists."
Log the raw `$e` via `debugPrint` / logger for developer diagnostics.

## Files Changed

- `lib/ui/screens/queue_screen.dart`
- `lib/services/reverb_service.dart`

## Code Simplification

No further simplification needed — changes are inline normalizations with no added abstractions.

## Verification

`flutter analyze lib/ui/screens/queue_screen.dart lib/services/reverb_service.dart` — no issues (56.9s).

## Documentation Sync
## Executioner Verdict
## Remaining Risks
