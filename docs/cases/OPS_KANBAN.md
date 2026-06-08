---
status: canonical
last_reviewed: 2026-06-08
scope: ecosystem
kanban-plugin: basic
---

# Ops Kanban (Bucket B — Pi deploy readiness)

Visual board for **operator/hardware** work. Open in **Kanban view** (community plugin).
Agents still use `state/QUEUE.md` + case `## Run State` — drag cards here for your own tracking only.

Refresh cards when `state/QUEUE.md` changes. Link: [[OPERATOR_HOME]] · Runbook: [[plt-case-stability-remediation]]

---

## P0 — Session 419

- [ ] [[plt-case-stability-remediation#P0 — NEX-014 session-419: deploy + verify on Pi (code already merged)]] — re-apply config; 419 gone #ops/pi #priority/p0
- [ ] Run `sudo bash scripts/deployment/pi-stability-verify.sh` (P0 auto-checks)

## P1a — Duplicate print (#140)

- [ ] [[nex-case-011-duplicate-order-printing]] — BT-only; disable Krypton 3rd-party printer #ops/pi
- [ ] One ticket per order smoke; close #140 if green

## P1b — Pi build (#136)

- [ ] [[infra-case-003-pi-docker-build-npm-ci-wifi]] — wlan0 rebuild with merged `.npmrc` #ops/pi
- [ ] Close #136 if green

## P1 — POS trigger

- [ ] [[nex-case-007-pos-payment-outbox-session-reset]] — `php artisan pos:setup-payment-trigger` on Pi #ops/pi

## P2 — APK + infra

- [ ] [[prn-rebuild-apk-scp-pi]] — Flutter APK build + install on Pi tablet
- [ ] [[infra-case-004-script-flow-unification]] — Pi runtime verify (PR #45 merged)

## Done (move here when green)

- [x] [[nex-case-015-tablet-intent-payload-hardening]] — PR #178 merged 2026-06-07
- [x] [[tab-case-011-active-order-recovery-filter]] — tablet PR #199 merged 2026-06-07

## Deferred (not KDS implementation)

- [ ] [[kds-implementation-plan]] — blocked on Pi gates + B5 decisions #deferred
