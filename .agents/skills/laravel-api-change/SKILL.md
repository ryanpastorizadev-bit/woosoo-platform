---
name: laravel-api-change
description: Safe Laravel API changes in woosoo-nexus — routes, controllers, FormRequests, models, resources, policies, transactions, response shape, client-safe errors, tests.
---

# Laravel API Change (woosoo-nexus)

Use when changing backend API surface in `woosoo-nexus/**`.

## Checklist
- Locate the existing route, controller, FormRequest, model, resource, and policy/guard before
  writing anything. Reuse existing patterns.
- Validation lives in FormRequests, not controllers. Authorization in policies/guards.
- Wrap multi-write operations in DB transactions. No partial order state on failure.
- **POS-first:** never add compensating POS deletes; POS rows are authoritative on local failure.
- Response shape stays stable unless this is an approved, documented contract change.
- Order state machine: `confirmed → completed | voided | cancelled` — never invent states.
- Errors returned to the tablet/customer must be client-safe; technical detail goes to logs.
- Add or update tests for the changed behaviour.

## Commands (Verifier runs these)
```txt
php artisan route:list
php artisan test
php artisan test --filter=<RelevantTest>
```
A `--filter` run proves only the targeted case — full suite is the proof of health.
