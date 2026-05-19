# Hook: intake

**Triggers:** raw issue · bug · error · log · complaint · "intake this"

Raw intake records reports only. It does not create case files and does not implement fixes.

---

## Step 1 — Read `inbox/RAW.md`

Check whether the same issue already has a RAW entry.

If a duplicate exists:
- reference the existing RAW ID
- do not append a duplicate

If no duplicate exists:
- append a new RAW entry

---

## Step 2 — Append Format

```markdown
### RAW-YYYYMMDD-NNN
Date:        YYYY-MM-DD
Source:      User / Client / Logs / Screenshot / Manual Testing / Production
Urgency:     Low / Medium / High / Critical
App:         Unknown / woosoo-nexus / tablet-ordering-pwa / woosoo-print-bridge / woosoo-platform

Raw report:
<paste verbatim; do not paraphrase>

Notes:
<agent observation, if any>

Status: needs_triage
```

---

## Step 3 — Immediate Triage Summary

Answer from the raw report only. Do not load source files.

```text
Affected app:        <best guess; state uncertainty>
Suspected area:      API / UI / print / auth / state / other
Severity:            Critical / High / Medium / Low
Tier:                1 / 2 / 3
Symptoms:            <observed behavior>
Expected behavior:   <desired behavior>
Observed behavior:   <actual behavior>
Missing evidence:    <what would confirm root cause>
Dep check needed:    yes/no; if yes, name the likely contract
```

---

## Step 4 — Escalation Check

Escalate to Tier 3 if the report involves:
- order state
- payment or pricing
- auth or token behavior
- printer or print queue
- cross-app contract behavior
- database migration
- production impact

---

## Step 5 — Output

```markdown
## Intake Result

Entry ID:   RAW-YYYYMMDD-NNN
Severity:   <severity>
Tier:       <tier>
App:        <app>
Suspected:  <area>

Triage summary:
<2-3 sentences>

Missing to confirm:
- <item>

Recommended next step:
Run `triage RAW-YYYYMMDD-NNN` to convert this into a flat case file under `docs/cases/`.
```
