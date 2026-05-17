---
status: canonical
last_reviewed: 2026-05-17
scope: ecosystem
---

# Contract: Printer Relay (woosoo-nexus ↔ woosoo-print-bridge)

**Implementation must be verified against actual code. Payload fields marked `<placeholder>`
are not yet confirmed and must be checked against the real implementation before relied upon.**

## Heartbeat (bridge → backend)

```json
{
  "printer_id": "<placeholder: required, non-empty>",
  "station": "<placeholder>",
  "status": "<placeholder: online | offline>",
  "timestamp": "<placeholder: ISO-8601>"
}
```

## Rules
- `printer_id` is **required**. A missing/empty printer ID is a **validation error**, never a
  500 / unhandled exception.
- An offline printer must be reported clearly and actionably with a client-safe message.
- **Duplicate print prevention is mandatory.** Each print job follows a
  reserve → ack → failed lifecycle. Retry/backoff must never produce a duplicate physical print.
- Station routing must send each job to the correct station printer.
- The bridge consumes this contract; it must not edit the backend API contract directly.
  Cross-app contract changes require an explicit split and a docs-first update.
