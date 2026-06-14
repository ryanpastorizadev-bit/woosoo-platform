---
status: canonical
last_reviewed: 2026-06-14
scope: ecosystem
---

# Woosoo Delivery Dashboard

**As of:** 2026-06-14 · **Regenerated:** as cases close (Bucket lens is live from `state/`).
**Markdown is canonical; the Google Sheet mirror is a one-way export for stakeholders.**

**Data sources (authoritative):** [`business/WOOSOO_SPEC_DELTA.md`](WOOSOO_SPEC_DELTA.md) ·
[`../WOOSOO_ECOSYSTEM_OVERVIEW.md`](../WOOSOO_ECOSYSTEM_OVERVIEW.md) ·
[`../../state/QUEUE.md`](../../state/QUEUE.md) · [`../../state/DONE.md`](../../state/DONE.md).
Forward cost/effort figures are **estimates — confirm before sharing**; delivered ₱ figures are
from SPEC_DELTA and are authoritative.

---

## 1. Component status

| Component | Status | Role |
|---|---|---|
| woosoo-platform | ✅ Delivered | Docker orchestration, contracts, agent OS, deploy scripts |
| woosoo-nexus | ✅ Delivered | Laravel API + manager admin UI + POS/Krypton + Reverb |
| tablet-ordering-pwa | ✅ Delivered | Nuxt 3 customer kiosk PWA |
| woosoo-print-bridge | ✅ Delivered | Flutter Android Bluetooth print relay |
| woosoo-portal | 🔶 Prototype UI | Owner cloud reporting (Phase 2; sync not implemented) |

**4 / 5 delivered, 1 prototype.**

## 2. Progress by lens

> Each lens has a different denominator. Read them together, not as one number.

**Lens 1 — vs original signed spec** (denominator = 14 original in-scope features, SPEC_DELTA §3.1)
`███████▉░░ ≈79%`
10 delivered (incl. KDS → Print Bridge substitution) · 2 partial (staff-call/broadcast-auth
hardening; remote access LAN-only) · 2 not delivered (offline queueing+cloud sync; QR access).

**Lens 2 — vs current roadmap (cases / Buckets)**
- Bucket A — Stabilization (gates staging→main): `██████████ 100%` cleared (empty).
- Bucket B — Deploy readiness: code merged; remainder is **Pi-hardware ops** `███░░░░░░░ ~30%`.
- Bucket C — Deferred features: not started by design.
- 40+ APPROVED cases across DONE.md + QUEUE "Completed".

**Lens 3 — production readiness** (deploy gates, ops)
`████▌░░░░░ ≈40–50%` — code-side largely ready; Pi runtime ops + 3-table smoke test pending.

**Lens 4 — verified / tested** (split — do not average)
- Backend/logic: `█████████▌ high` — nexus 447/447, tablet 408, bridge 104–108.
- UI: `░░░░░░░░░░ ~0%` — no component/visual/E2E/a11y tests yet (see UI thread).

## 3. Feature inventory (original spec)

Legend: ✅ delivered · ⚠️ partial · 🔄 replaced (substitution) · ❌ not delivered

| Feature | Status | Component | Notes |
|---|---|---|---|
| Tablet ordering app per table | ✅ | tablet-ordering-pwa | Nuxt 3 PWA |
| Digital menu (photos, categories, modifiers) | ✅ | tablet/nexus | Packages, meat selection |
| Tap-to-order, quantity selection | ✅ | tablet | Cart management |
| Order summary, confirmation, live status | ✅ | tablet/nexus | Session state via Reverb |
| Staff call buttons (service/water/billing/cleanup) | ⚠️ | nexus | Service requests delivered; broadcast-auth hardening needed |
| Kitchen Display System (KDS) | 🔄 | print-bridge | Replaced by Print Bridge at client request; KDS re-add = CO-001 |
| Admin dashboard (menu & order management) | ✅ | nexus | Inertia + Vue 3 |
| 3rd-party POS integration | ✅ | nexus | Krypton driver, LAN `192.168.1.32` |
| Remote access to sales/closing data | ⚠️ | nexus | LAN-only; cloud (portal) is Phase 2 |
| Offline transaction queueing + cloud sync | ❌ | tablet/nexus | Machinery incomplete; needs contract decision |
| QR code-based access | ❌ | tablet | Not implemented |
| No login required on tablet | ✅ | nexus | Device-based Sanctum token |
| Responsive design for tablets | ✅ | tablet | Tablet-targeted viewport |
| Custom branding (Woosoo identity) | ✅ | tablet/nexus | Theming applied |

**Pending / known gaps (SPEC_DELTA §4):** Print-Bridge ACK-backlog TTL (Critical) ·
broadcast-channel auth hardening (Critical) · polling watermark loss (High) · tablet WS zombie
(addressed by TAB-CASE-009 watchdog) · Print-Bridge APK rebuild/install.

## 4. Cost — delivered + remaining (₱ PHP)

**Delivered (authoritative — SPEC_DELTA §1, §5):**

| Item | Amount |
|---|---|
| Original signed contract | ₱350,000 |
| Additional billed — Pi configuration | ₱25,000 |
| **Total billed to client** | **₱375,000** |
| Estimated fair market value as built | ₱875,000 |
| Scope absorbed by developer (no charge) | ~₱500,000 |

**Remaining — forward estimate (CONFIRM before sharing; only CO-001 is pre-costed):**

| Item | Basis | Est. |
|---|---|---|
| CO-001 — KDS re-addition (change order) | SPEC_DELTA §6 (pre-costed) | ₱100,000 |
| Spec-gap closures (offline queue+sync, QR, remote/cloud reporting) | per-item sizing pending | TBD |
| Critical hardening (ACK-backlog TTL, broadcast-auth, polling watermark) | per-item sizing pending | TBD |
| Improvement program (WSL staging, UI test suite, docs gap-fill, dashboard) | per-workstream sizing pending | TBD |

> The TBDs require an explicit effort-sizing pass against the SPEC_DELTA rate basis (PH 3–4 dev
> team) before they go to a stakeholder. Do not present them as quotes until sized.

## 5. Backlog / timeline (Buckets)

- **Bucket A — Stabilization:** ✅ cleared → `dev → staging → main` promotion unblocked.
- **Bucket B — Deploy readiness (Pi ops):** NEX-007 trigger, NEX-011 POS config, INFRA-001/002
  Pi verify, PRN-REBUILD-APK → then 3-table smoke test.
- **Bucket C — Deferred features:** KDS-EPIC, telemetry, discount sync, Pi control panel, plus the
  tooling/improvement program ([`../cases/plt-case-tooling-improvement-program.md`](../cases/plt-case-tooling-improvement-program.md)).

## 6. Google Sheet mirror

One-way export to a Google Sheet (via the Google Drive MCP) with tabs: **Component Status ·
Feature Inventory · Progress by Lens · Cost (Delivered + Remaining) · Backlog/Timeline**, using
the Sheet's native data-bar / % formatting for the visual progress bars. The Sheet is stamped
"generated from `docs/business/WOOSOO_DELIVERY_DASHBOARD.md` — do not edit here." Lens 2 can be
derived live from case frontmatter once the Run State→frontmatter mirror lands.

---

*Every percentage and ₱ figure above traces to a named source. Forward estimates are labelled and
must be sized before external use. This file is canonical; the Sheet is a generated mirror.*
