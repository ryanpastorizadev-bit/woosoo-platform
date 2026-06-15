---
status: canonical
last_reviewed: 2026-06-15
scope: ecosystem
---

# Contract: Printer Relay (woosoo-nexus ↔ woosoo-print-bridge)

**Implementation verified against live code (2026-06-06): `PrinterHeartbeatRequest.php` (Nexus)
and `app_controller.dart::_startHeartbeat()` (Bridge).**

## Polling and Heartbeat

**Polling interval (HTTP fallback):** The Print Bridge polls `/api/printer/unprinted-events`
every **5 seconds** (was 30 seconds until 2026-06-01 to cap worst-case order-to-print latency
at ~6–10 seconds on a flaky LAN when WebSocket is down).

**Heartbeat interval:** The Print Bridge sends a POST to `/api/printer/heartbeat` every
**30 seconds** to signal that the device is alive and to report queue status.

### Heartbeat (bridge → backend)

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

## Job retention

The Print Bridge maintains a local job queue (Sembast DB) with automatic purge logic:

| Job state | TTL | Purpose |
|---|---|---|
| Completed / success | 30 days | Keep recent successful prints as a local audit trail |
| Dead-letter (failed after max retries) | 90 days | Extended retention for failed jobs to aid diagnosis |

The purge check runs every 24 hours. These TTLs are implementation-level only (not part of the
API contract); if the queue needs longer retention for compliance, the backend should archive
completed jobs to the POS history DB and signal the bridge to purge older locally.

## Rules
- `printer_id` is **required**. A missing/empty printer ID is a **validation error**, never a
  500 / unhandled exception.
- An offline printer must be reported clearly and actionably with a client-safe message.
- **Duplicate print prevention is mandatory.** Each print job follows a
  reserve → ack → failed lifecycle. Retry/backoff must never produce a duplicate physical print.
- Station routing must send each job to the correct station printer.
- The bridge consumes this contract; it must not edit the backend API contract directly.
  Cross-app contract changes require an explicit split and a docs-first update.
