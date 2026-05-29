---
name: printer-relay-debug
description: Verify woosoo-print-bridge relay behaviour — valid heartbeat, missing-printer-ID validation, clear offline reporting, and retry without duplicate prints.
---

# Printer Relay Debug (woosoo-print-bridge)

## Must verify
- A valid heartbeat payload succeeds.
- A missing printer ID returns a **validation error**, not a 500.
- An offline printer is reported clearly and actionably (client-safe message).
- Retry/backoff does **not** duplicate a print job — reserve → ack → failed lifecycle holds.
- Station routing sends each job to the correct station printer.

## Notes
- The bridge consumes the backend contract; it never edits backend API contracts directly.
- The Flutter test suite may be red — report the baseline honestly; never claim green without
  raw output.

See `contracts/printer-relay.contract.md`.
