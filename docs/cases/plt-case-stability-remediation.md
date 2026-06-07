---
status: canonical
last_reviewed: 2026-06-07
scope: ecosystem
---

# CASE: plt-case-stability-remediation

Platform orchestration plan: stabilize the restaurant stack on the Pi **before** starting KDS
(#137 + #143/#144). Authoritative backlog rows live in `state/QUEUE.md`; this document is the
human-readable runbook and priority narrative. KDS implementation spec = deferred (see
`state/QUEUE.md` KDS-EPIC row; Appendices B/C from the 2026-06-07 design session — not
duplicated here).

## Run State

- task_slug: plt-case-stability-remediation
- tier: 2
- branch: n/a (orchestration; per-item branches in sibling cases)
- status: IN_PROGRESS
- last_completed_agent: contrarian (plan review + Part A revision)
- next_agent: operator (Pi Bucket B) | specialist per queued case
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-07

## Handoff

- Phase in progress: Pi operator verification (P0–P1b); code items queued separately.
- Done so far: Part A revised against working tree + `state/QUEUE.md`; NEX-014 confirmed
  code-complete on `dev`; TAB-CASE-011 and NEX-CASE-015 added; legacy script paths corrected.
- Exact next action: Rebase `claude/happy-cannon-2nR48` onto `origin/dev`; run P0 Pi checklist
  (NEX-014); Pi smoke for NEX-011 + INFRA-003; then schedule TAB-CASE-011.
- Working-tree state: `docs/cases/plt-case-stability-remediation.md` (this file).
- Risks / do-not-redo: Do **not** re-implement NEX-014 script changes — already merged. Do not
  start KDS until P0–P2 Pi gates green and KDS B5 Tier-3 decisions locked.

---

# Stability-First Remediation Plan (before KDS)

*Revised 2026-06-07. Supersedes the pasted 2026-06-05 Part A draft (that draft was never
committed; only this file and `state/QUEUE.md` are durable.)*

## Context

Direction: **stabilize before KDS.** KDS (#137 + #143/#144) is deferred until the restaurant
stack is proven on the Pi.

Current reality (verified against the working tree + `state/QUEUE.md`, 2026-06-07):

- **Duplicate-print fix MERGED** (#163, NEX-011): `PrintOrder` re-dispatch removed from
  `markPrinted` ack paths + `is_printed` idempotency guard; `PrinterApiTest` updated.
- **Pi `npm ci` hardening MERGED** (INFRA-CASE-003) for #136.
- **Session-419 (NEX-014) is CODE-COMPLETE and MERGED — not "unimplemented."**
  `scripts/deployment/apply-woosoo-config.sh:454` already emits `SESSION_DOMAIN ""`, the
  `WOOSOO_ENV` profile switch exists, and `config/session.php`'s request-host fallback resolves
  `null` → request host. Case `nex-case-014` = **COMPLETE / APPROVED 2026-06-05**. **Remaining =
  operator deploy + verify on the Pi (Bucket B), not a code change.**
- **Admin redesign MERGED** (#161).
- Working branch `claude/happy-cannon-2nR48` is behind `origin/dev` — **rebase before any work.**

## Priority order (recommended)

| Pri | Item | Type | State |
|---|---|---|---|
| **P0** | NEX-014 session-419 | **ops verify** (code merged) | re-apply config on Pi; confirm 419 gone |
| **P1a** | #140 dup-print (NEX-011) | ops verify | Pi: BT-only print, one ticket/order; close #140 |
| **P1b** | #136 Pi build (INFRA-003) | ops verify | Pi rebuild on wlan0 with merged `.npmrc`; close #136 if green |
| **P1c** | TAB-CASE-011 | **bug (live UX)** | tablet active-order recovery filter omits `in_progress`/`served` |
| **P2** | NEX-CASE-015 | contract hygiene | tablet route accepts client-sent `totals`/`prices` — ignore/reject |
| **P2** | Docs #156 | docs | stale `relay-device/` paths in nexus `AI_ONBOARDING.md` |
| **P3** | Dependabot safe bumps | hygiene | land on `dev` (not only `main`); test per bump |
| **Deferred** | KDS #137/#143/#144; admin-display #145–#148; telemetry #152 | feature | after stability + B5 decisions locked |

---

## P0 — NEX-014 session-419: deploy + verify on Pi (code already merged)

> **Corrected:** the script edit is **already on `dev`**. Do **not** re-implement it. This is a
> Bucket B operator runbook.

**Why it's fixed in code:** `apply-woosoo-config.sh:452-454` emits `SESSION_DOMAIN` empty; with
empty domain, `config/session.php`'s `domain` closure returns `null` (use request host), so
IP-based LAN clients get a host-scoped cookie instead of one pinned to the box hostname.

**Operator steps (on the live Pi):**

1. Clear any pinned `SESSION_DOMAIN` in the live `.env`.
2. Set `WOOSOO_ENV=production` (or correct profile).
3. Re-run `scripts/deployment/apply-woosoo-config.sh`; restart the `app` container.
4. Verify from a LAN device hitting the **box IP**: `GET /sanctum/csrf-cookie` → host-only
   cookie (no `domain=`); login returns **422 on bad creds, not 419**; session persists across
   requests; tablet/device API unaffected.
5. Confirm `scripts/deployment/legacy/verify-client.sh:44` /
   `scripts/deployment/legacy/update-client.sh:94` show `SESSION_DOMAIN` empty post-apply.
6. Close the NEX-014 operator loop.

**Host-vars sanity (already in script — confirm, don't edit):** `SANCTUM_STATEFUL_DOMAINS`
(line 457) and `REVERB_ALLOWED_ORIGINS` (line 463) include the IP. **Gap:**
`CORS_ALLOWED_ORIGINS` (line 458) is hostname-only. Fine for same-origin admin login (419 is
session-domain, not CORS) — but if anything hits the API **cross-origin via IP**, file a
**separate** case to add IP origins; do **not** bundle into NEX-014.

Case file: `woosoo-nexus/docs/cases/nex-case-014-session-domain-login-419.md`

---

## P1 — Verify & close the merged fixes

### P1a — #140 duplicate order printing (NEX-011)

- **Done (merged #163):** `PrintOrder::dispatch()` removed from `markPrinted`/`markPrintedBulk`
  ack paths; `is_printed` guard added; `OrderService::processOrder` `afterCommit` (correct single
  trigger) untouched; tests assert `OrderPrinted` not `PrintOrder`.
- **To close:** on the Pi — confirm `NEXUS_PRINT_EVENTS_ENABLED=true`; **disable the 3rd-party
  Krypton printer (BT-only)**; submit an order → exactly one kitchen ticket; double
  `POST /api/order/{id}/printed` is idempotent (2nd: "already printed", no WS event). Then close
  #140.
- **Out of scope (split out):** configurable `PRINT_ROUTE` (BT-only/POS-only/dual/disabled)
  doesn't exist; the duplicate symptom is fixed — don't block #140 on building routing modes.

Case file: `woosoo-nexus/docs/cases/nex-case-011-duplicate-order-printing.md`

### P1b — #136 Pi Docker build (INFRA-003)

- **Done (merged):** `.npmrc` retry/timeout hardening.
- **To close:** rebuild on the **actual Pi (wlan0)** → green closes it. Fallback if still flaky:
  BuildKit cache-mount (`RUN --mount=type=cache,target=/root/.npm npm ci`) and/or
  `prefer-offline` (issue Option A/B) — a fallback, not a prerequisite.

Case file: `docs/cases/infra-case-003-pi-docker-build-npm-ci-wifi.md`

### P1c — TAB-CASE-011 (tablet active-order recovery)

- **Bug:** recovery filter in `stores/Order.ts` (~line 807) includes only
  `pending,confirmed,ready` — missing `in_progress` and `served`, which Nexus counts as
  non-terminal (`DeviceOrder.php` active scope). On reload mid-meal the tablet can lose an active
  order.
- **Fix:** include all backend non-terminal states + add a recovery test. Tablet repo
  (`chuya-frontend`). Real live-ordering stability item — keep in the stability pass.

Tracked in: `state/QUEUE.md` Bucket B-follow.

---

## P2 — NEX-CASE-015 (contract hygiene)

- `StoreDeviceOrderRequest` accepts client-sent `totals`/`prices`/`discounts`/`ordered_menu_id`/modifier
  fields. Tablet sends intent-only; backend should ignore/reject these on the tablet route to
  keep pricing POS-authoritative. Backend (`ranpo-backend`), Tier 2.

Tracked in: `state/QUEUE.md` Bucket B-follow.

---

## P2 — Docs accuracy (#156)

`docs/AI_ONBOARDING.md` (nexus): replace stale `relay-device/` references with
`woosoo-print-bridge` sibling-repo framing; fix branch context to `dev`; verify
`print-service/index.js` vs `woosoo-print-bridge` production route before editing. Run the docs
gate. Low risk — after Pi verification.

---

## P3 — Dependency hygiene (dependabot)

- **Land now (low risk), test per bump (`npm run build` + `vendor/bin/pest`):** `laravel/reverb`
  1.10.2 (#127), `laravel/sail` (#124), `typescript-eslint` (#125), `dedoc/scramble` (#128),
  `marked` (#129), `@tailwindcss/vite` (#117).
- **Defer (risky majors):** `@inertiajs/vue3` 2→3 (#126), `inertiajs/inertia-laravel` 2→3 (#115),
  `zod` 3→4 (#114), `predis` 2→3 (#89).
- **Branch-flow:** these PRs target `main` while feature/bug work is on `dev`.
  **Retarget/cherry-pick to `dev`** before promotion so the bumps don't diverge.

---

## Deferred until stability is done

KDS #137 (+ #143/#144), admin-display #145–#148, telemetry #152.

**Do not start** until P0–P2 Pi gates are green and the KDS B5 Tier-3 decisions are locked.

**Before KDS code (label fix):** the B1 table and B7 agent prompt from the 2026-06-07 design
session still map `served|completed → "Completed"`. Per the three-layer model (Appendix C5),
that must read **`served → "Served"`** (Layer 2 kitchen), with the card dropped when POS sets
`completed` (Layer 1 paid). Update B1/B7 when KDS work resumes.

---

## Recommended first actions

1. **Rebase** `claude/happy-cannon-2nR48` onto `origin/dev`.
2. **Do not code P0** — run the NEX-014 Pi operator checklist above; close the case in ops.
3. **Pi smoke pass** for NEX-011 + INFRA-003; close #140 and #136 if green.
4. Schedule **TAB-CASE-011** into the stability pass.
5. Only then schedule KDS Phase 0 (with B5 #1 decided before Phase 2).

---

## Substantive corrections vs. original pasted Part A (2026-06-05)

| Original | Revised |
|---|---|
| P0 = implement SESSION_DOMAIN fix | P0 = **ops verify** (fix already on `dev`) |
| NEX-014 "QUEUED; no app/deploy edits" | NEX-014 **COMPLETE 2026-06-05** |
| Missing tablet recovery bug | **P1c TAB-CASE-011** added |
| Missing contract hygiene | **P2 NEX-CASE-015** added |
| `scripts/deployment/verify-client.sh` | **`scripts/deployment/legacy/`** paths |
| KDS label map implicit | **B1/C5 drift** flagged for deferred KDS work |

## Related canonical state

- Backlog: `state/QUEUE.md`
- Session scratchpad (not authoritative): `CLAUDE.local.md`
- NEX-014 case: `woosoo-nexus/docs/cases/nex-case-014-session-domain-login-419.md`
- NEX-011 case: `woosoo-nexus/docs/cases/nex-case-011-duplicate-order-printing.md`
- INFRA-003 case: `docs/cases/infra-case-003-pi-docker-build-npm-ci-wifi.md`
