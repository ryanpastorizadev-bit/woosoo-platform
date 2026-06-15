---
status: canonical
last_reviewed: 2026-06-14
scope: business
---

# Woosoo Delivery Dashboard

> **Source discipline:** Every percentage and ₱ figure in this document traces to a named source. Forward estimates are explicitly labeled *estimate — confirm before sharing*. Regenerate this dashboard as cases close and tests run.

**Sources:** [[business/WOOSOO_SPEC_DELTA]] (cost + spec figures) · `state/QUEUE.md` (case/bucket status) · `state/DONE.md` (verified completions) · individual case files · deploy gates in `AGENTS.md`.

---

## Progress at a glance

| Lens | Progress | Source |
|---|---|---|
| vs original spec | `████████░░` 80% (10/13 delivered, 2 partial, 2 not delivered) | SPEC_DELTA §3.1 |
| vs roadmap — Bucket A | `██████████` 100% (cleared) | QUEUE.md |
| vs roadmap — Bucket B | `███████░░░` code ~done / Pi ops ~30% | QUEUE.md |
| Production readiness | `████░░░░░░` ≈40–50% (Pi hardware + smoke test pending) | AGENTS.md deploy gates |
| Tested — backend | `██████████` High (nexus 438+, tablet 408, bridge 108) | DONE.md case rows |
| Tested — UI | `░░░░░░░░░░` ~0% (zero component/visual/E2E/a11y tests) | Thread D audit |

---

## Lens 1 — vs original signed specification

**Denominator:** 13 original in-scope features from SPEC_DELTA §3.1 (May 20XX signed contract).

| Feature | Status | Notes |
|---|---|---|
| Tablet ordering app per table | ✅ Delivered | Nuxt 3 PWA (`tablet-ordering-pwa/`) |
| Digital menu (photos, categories, modifiers) | ✅ Delivered | Menu browsing, packages, meat selection |
| Tap-to-order, quantity selection | ✅ Delivered | Cart management |
| Order summary, confirmation, live status | ✅ Delivered | Reverb WebSocket session state |
| Staff call buttons (service, water, billing, cleanup) | ⚠️ Partial | Service request system delivered; broadcast auth has security gaps requiring hardening |
| Kitchen Display System (KDS) | 🔄 Replaced | Replaced by Print Bridge at **client request**; Print Bridge delivered and operational |
| Admin dashboard (menu & order management) | ✅ Delivered | Laravel admin UI via Inertia.js + Vue 3 |
| 3rd party POS integration | ✅ Delivered | Krypton POS driver; read-write via LAN IP |
| Remote access to sales and closing data | ⚠️ Partial | Admin dashboard LAN-accessible; no cloud/remote access |
| Offline transaction queueing and cloud sync | ❌ Not delivered | Offline machinery incomplete; contradictory code paths |
| QR code-based access | ❌ Not delivered | Not implemented |
| No login required on tablet | ✅ Delivered | Device-based Sanctum token auth |
| Responsive design for tablets | ✅ Delivered | Tablet-targeted viewport |
| Custom branding (Woosoo identity) | ✅ Delivered | Theming applied |

**Totals:** 10 delivered (incl. KDS→Print Bridge substitution) · 2 partial · 2 not delivered · **≈ 80% of original spec**

*Source: SPEC_DELTA §3.1*

---

## Lens 2 — vs current roadmap (cases / Buckets)

*Source: `state/QUEUE.md` as of 2026-06-14.*

### Bucket A — Stabilization (gates staging → main)

> ✅ **Empty — 100% cleared** as of 2026-06-02. Every stabilization gate is APPROVED + merged to dev. The staging → main promotion is UNBLOCKED.

### Bucket B — Deploy readiness

**Code side:** largely merged to dev/staging.
**Ops side:** Pi hardware steps pending (hardware access required).

| Priority | Case | Status |
|---|---|---|
| P1 | NEX-CASE-011 — duplicate print / POS config | Code merged; POS `NEXUS_PRINT_EVENTS_ENABLED=true` + disable 3rd-party Krypton (Pi ops) |
| P1 | NEX-CASE-014 — SESSION_DOMAIN host-binding | Code merged → dev |
| P1 | NEX-CASE-007 — POS payment trigger (deploy step) | Code landed; run `pos:setup-payment-trigger` on Pi |
| P2 | INFRA-CASE-004 — deploy script hardening | Merged dev; Pi runtime = Bucket B |
| P2 | INFRA-CASE-002 — deploy stability wrappers | Stage A on dev; Stage B Pi verification pending |
| P2 | INFRA-CASE-001 — Pi platform-root migration | Built; untested on Pi hardware |
| P3 | PRN-REBUILD-APK — rebuild + scp Flutter APK | In progress (verifier) |

**Bucket B code completion: ~80%. Pi hardware ops: ~30%.**

### Bucket B-follow — Post-promotion correctness

| Case | Status |
|---|---|
| TAB-CASE-011 — active-order recovery filter | ✅ Complete 2026-06-07 |
| NEX-CASE-015 — intent-only device order payload | ✅ Complete 2026-06-07 |
| PLT-CASE-EXECUTIONER-SIMPLIFIER-GATE | Queued |
| PLT-CASE-CHAIN-DOC-SYNC | Queued |
| PLT-CASE-TOOLING-IMPROVEMENT-PROGRAM | This program — in progress |

### Bucket C — Deferred features

| Case | Status |
|---|---|
| PLT-CASE-003 — cross-app orchestration | Deferred (deps confirmed, priority) |
| KDS-EPIC — Kitchen Display System v1.0 | Deferred (after Bucket B Pi ops) |
| Device telemetry | Deferred |
| POS→tablet discount sync | Deferred |
| Pi Control Panel | Deferred |

**Verified completions (DONE.md + QUEUE.md Completed):** 40+ APPROVED cases, including nexus 438+ tests, tablet 408 tests, bridge 108 tests. *Source: individual case Executioner Verdicts.*

---

## Lens 3 — Production readiness (deploy gates)

*Source: `AGENTS.md` deploy gates.*

| Gate | Status | Notes |
|---|---|---|
| Code stabilization (Bucket A) | ✅ Cleared | All gates APPROVED + merged |
| Deploy scripts hardened | ✅ Code merged | INFRA-CASE-004 on dev |
| POS payment trigger on Pi | ⏳ Pending | Pi ops — `pos:setup-payment-trigger` |
| POS printer config on Pi | ⏳ Pending | `NEXUS_PRINT_EVENTS_ENABLED=true` + disable Krypton 3rd-party |
| Print Bridge APK on Pi tablet | ⏳ Pending | Flutter rebuild + SCP |
| 3-table smoke test (live orders → print) | ⏳ Pending | Requires above three steps |
| Broadcast auth hardening | ⚠️ Critical gap | `admin.print`/`service-requests` return `true` to all (SPEC_DELTA §4) |

**Production readiness: ≈40–50%.** Code side mostly green; gated on Pi hardware access + 3 Pi ops steps + broadcast-auth hardening.

**Critical open items (do not go live without addressing):**
- Broadcast channel auth hardening — `admin.print` and `service-requests` channels return `true` to all subscribers.
- Print Bridge ACK backlog TTL — jobs stuck in `printedAwaitingAck` with no timeout.
- Polling watermark loss — Bridge loses unprinted events after long downtime.

*Source: SPEC_DELTA §4*

---

## Lens 4 — Verified / tested

| Area | Status | Details |
|---|---|---|
| Nexus backend | ✅ High | 438+ tests (as of NEX-CASE-013 2026-06-01); all Executioner APPROVED |
| Tablet PWA | ✅ High | 408 tests (TAB-CASE-009 2026-06-01); typecheck + lint clean |
| Print Bridge | ✅ High | 108 tests (PRN-CASE-002 2026-05-18); flutter analyze clean |
| Nexus admin UI (Vue components) | ❌ ~0% | No Vitest, no Playwright, no visual regression, no a11y tests |
| Tablet PWA UI | ❌ ~0% | Same — sibling repo |
| Runtime error visibility | ✅ Added | `window.onerror` + `unhandledrejection` in `app.ts` (this session) |

> **Split bar:** Backend test coverage is high; UI test coverage is near-zero. These are two different risk surfaces. Thread D of the improvement program addresses the UI gap in phases.

---

## Feature inventory

*Columns: Feature · Spec status · Case ID(s) · Backend verified? · UI verified?*
*Source rows: SPEC_DELTA §3.1–3.3 + NEXUS BRD business modules + §4 pending list.*

| Feature | Spec status | Case ID(s) | Backend | UI |
|---|---|---|---|---|
| Tablet ordering app | ✅ Delivered | TAB-CASE-001/002/003 | ✅ | ❌ |
| Digital menu | ✅ Delivered | — | ✅ | ❌ |
| Tap-to-order / cart | ✅ Delivered | TAB-CASE-001 | ✅ | ❌ |
| Order summary + live status | ✅ Delivered | TAB-CASE-010 | ✅ | ❌ |
| Staff call / service requests | ⚠️ Partial | NEX-CASE-006 | ✅ | ❌ |
| Print Bridge (KDS replacement) | 🔄 Replaced | PRN-CASE-001/002 | ✅ | ❌ |
| Admin dashboard | ✅ Delivered | NEX-CASE-009/012/020 | ✅ | ❌ |
| POS integration (Krypton) | ✅ Delivered | NEX-CASE-007/013 | ✅ | ❌ |
| Remote / cloud sales access | ⚠️ LAN only | — | N/A | — |
| Offline queueing + cloud sync | ❌ Not delivered | — | — | — |
| QR code access | ❌ Not delivered | — | — | — |
| Device auth (no-login tablet) | ✅ Delivered | NEX-CASE-001/008 | ✅ | ❌ |
| Responsive / branding | ✅ Delivered | nexus-ui-handoff | N/A | ❌ |
| Broadcast auth hardening | ⚠️ Security gap | NEX-CASE-001 partial | ⚠️ | — |
| Print Bridge ACK TTL | ❌ Gap | — | — | — |
| Polling watermark loss | ❌ Gap | — | — | — |
| KDS re-addition (CO-001) | Pending CO | KDS-EPIC | — | — |

---

## Cost model

### Delivered (authoritative — source: SPEC_DELTA §1 + §5)

| | Amount |
|---|---|
| Original signed contract | ₱350,000 |
| Additional billed — Pi configuration | ₱25,000 |
| **Total billed to client** | **₱375,000** |
| Estimated fair market value as built | ₱875,000 (reference only) |
| Developer-absorbed scope | ~₱500,000 |

### Remaining — forward estimates (confirm before sharing with client)

| Item | Estimate | Source/basis |
|---|---|---|
| CO-001 KDS re-addition | **₱100,000** | SPEC_DELTA §6 (already costed) |
| Offline queueing + cloud sync (spec gap) | *estimate — TBD* | Contract-scope gap; requires dedicated sizing |
| QR code access (spec gap) | *estimate — TBD* | Contract-scope gap |
| Remote/cloud sales reporting (spec gap) | *estimate — TBD* | Likely woosoo-portal Phase 2 |
| Broadcast auth hardening | *estimate — TBD* | Critical; sizing via NEX-CASE-001 follow-on |
| Print Bridge ACK TTL + polling watermark | *estimate — TBD* | SPEC_DELTA §4 items |
| Improvement program (Threads B–D): WSL staging, UI tests (Vitest + Playwright + visual + a11y), doc gap-fill | *estimate — TBD* | Thread-by-thread sizing needed |

> All estimates above are **forward-looking and unconfirmed**. Do not present to the client as agreed scope or pricing until explicitly reviewed and authorized.

---

## How to update this dashboard

1. When a case completes: update the Bucket row and the feature inventory row.
2. When Pi ops run: update Lens 3 gate status.
3. When tests are added: update Lens 4 counts.
4. When a change order is accepted: move from "estimate — TBD" to a firm figure.
5. Re-run the `## Progress at a glance` progress bars after each meaningful update.
6. The Google Sheet mirror (if active) is **one-way (md → Sheet)** and is read-only for stakeholders; this markdown file is authoritative.
