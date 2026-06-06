---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# Contract: Printer Relay (woosoo-nexus ↔ woosoo-print-bridge)

**Implementation verified against live code (2026-06-06): `PrinterHeartbeatRequest.php` (Nexus)
and `app_controller.dart::_startHeartbeat()` (Bridge).**

## Heartbeat (bridge → backend)

All fields except `printer_id` are nullable. `printer_id` is required and validated as a
non-empty string (max 100 chars).

```json
{
  "device_id": 123,
  "printer_id": "BT-1234",
  "printer_name": "Woosoo Printer",
  "bluetooth_address": "AA:BB:CC:DD:EE:FF",
  "app_version": "1.0.0+1",
  "session_id": 42,
  "last_print_event_id": 100,
  "last_printed_order_id": 99,
  "timestamp": "2026-06-06T10:00:00.000Z",
  "status": "printer_connected"
}
```

`status` values (derived by `_heartbeatStatus()` in the bridge):

| Value | Condition |
|---|---|
| `queue_failed` | One or more jobs in the failed state |
| `queue_pending` | Jobs pending, awaiting ack, or queue paused |
| `printer_connected` | No pending/failed jobs and BT printer connected |
| `online` | Default — bridge running but printer not yet connected |

## Rules
- `printer_id` is **required**. A missing/empty printer ID is a **validation error**, never a
  500 / unhandled exception.
- An offline printer must be reported clearly and actionably with a client-safe message.
- **Duplicate print prevention is mandatory.** Each print job follows a
  reserve → ack → failed lifecycle. Retry/backoff must never produce a duplicate physical print.
- Station routing must send each job to the correct station printer.
- The bridge consumes this contract; it must not edit the backend API contract directly.
  Cross-app contract changes require an explicit split and a docs-first update.
