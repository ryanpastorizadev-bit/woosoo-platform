# Raw Intake

Append-only raw issue log. Raw entries are reports, not implementation tasks.

---

## Format

```markdown
### RAW-YYYYMMDD-NNN
Date:        YYYY-MM-DD
Source:      User / Client / Logs / Screenshot / Manual Testing / Production
Urgency:     Low / Medium / High / Critical
App:         Unknown / woosoo-nexus / tablet-ordering-pwa / woosoo-print-bridge / woosoo-platform

Raw report:
<verbatim report>

Notes:
<agent observation>

Status: needs_triage
```

---

### RAW-20260517-001
Date:        2026-05-17
Source:      User
Urgency:     Critical
App:         woosoo-nexus

Raw report:
This paste shows **two real backend issues**:

1. **POS stored procedure missing**
   `get_open_orders_for_session` does not exist on POS DB (`SQLSTATE 1305`) at `19:44:47` (line 70).

2. **Realtime publish failure to Reverb**
   Laravel failed to broadcast with `cURL error 7` to `http://192.168.100.7:8080/apps/woosoo/events` (lines 84, 186), so order creation succeeded but realtime broadcast failed.

Also present:
- `Legacy non-idempotent print event path used` warning (line 81): request lacked `client_submission_id`.
- Repeated relay heartbeat scans are normal info logs (`processed: 0`), not failures.

So root problems in this paste are **POS DB procedure drift** and **Nexus → Reverb internal connectivity on port 8080**.

Notes:
Immediate triage from raw report only: likely Tier 3 backend/platform issue because it touches POS DB behavior, realtime order broadcasts, and print idempotency warning context. Suspected primary app is woosoo-nexus; Reverb connectivity may involve infrastructure but should be confirmed during triage before splitting.

Status: needs_triage
