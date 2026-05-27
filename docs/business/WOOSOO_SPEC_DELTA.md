---
status: canonical
last_reviewed: 2026-05-27
scope: business
---

# Woosoo — Specification Delta & Project Cost Analysis

**Origin specification:** `docs/business/WOOSOO_ORIGIN_SPECIFICATION.md` (May 20XX, archived)  
**Current specification:** `docs/business/NEXUS_BUSINESS_REQUIREMENTS_DOCUMENT.md` (tech-artificer/woosoo-nexus PR #138) + `docs/business/WOOSOO_PLATFORM_BRD_SUPPLEMENT.md`  
**Prepared by:** Ryan H. Pastoriza  
**Date:** 2026-05-27

---

## Purpose

This document compares the original signed specification for the Woosoo KBBQ table ordering system against the current delivered and in-progress system. It records what was delivered as specified, what changed in architecture, what was added beyond original scope, and what is still pending.

It also provides a project cost breakdown: the original contracted amount, the estimated cost of the current system as built, and the estimated cost of scope added beyond the original contract.

---

## 1. Cost Summary

| | Amount | Notes |
|---|---|---|
| **Legacy specification (signed contract)** | ₱350,000.00 | Original 3-man team quote, May 20XX |
| **Current system (estimated cost as built)** | ₱875,000.00 | Estimated; see Section 5 for breakdown |
| **Scope delta (additional work beyond contract)** | **₱525,000.00** | Features and architectural changes not in original scope |

> **Note:** The current system cost is an estimate based on scope expansion. It is not a revised invoice — it reflects the complexity of what was built relative to the original contract baseline.

---

## 2. What Changed at the Architecture Level

### 2.1 Kitchen Display System → Woosoo Print Bridge

The single largest architectural departure from the original specification.

| | Origin Specification | Current System |
|---|---|---|
| **Component name** | Kitchen Display System (KDS) | Woosoo Print Bridge |
| **Technology** | Not specified (assumed display terminal or web UI) | Flutter Android APK |
| **Runtime** | Staff-facing screen in kitchen | Android device running as a local relay |
| **Order intake** | Real-time orders from tablets | Reverb WebSocket (`admin.orders` channel) + HTTP polling fallback |
| **Output** | Color-coded on-screen ticket display | Bluetooth print dispatch to kitchen/cashier thermal printers |
| **Staff interaction** | Tag orders as "In Progress" / "Completed" | ACK lifecycle: reserve → print → ack (or failed) |
| **Reliability model** | Not specified | Idempotent print job with reserve/ack/failed lifecycle; dead-letter recovery |
| **Why it changed** | KDS screen requires hardware display per station | Print relay + Bluetooth printers serve multiple stations from one device; lower hardware cost |

### 2.2 Cloud-Hosted → On-Premises (Raspberry Pi)

| | Origin Specification | Current System |
|---|---|---|
| **Hosting model** | "Cloud-hosted server"; cloud sync | On-premises Raspberry Pi 5 (LAN-only) |
| **Deployment** | Not specified | Docker Compose: 8 services on platform root |
| **Database** | Cloud-synced | MySQL 8.0 on Pi; no cloud replication |
| **Real-time** | "Cloud syncing" | Laravel Reverb WebSocket on Pi; LAN-scoped |
| **Admin access** | "Remote access to live and end-of-day sales" | Admin dashboard on LAN; no remote cloud access in current build |

### 2.3 Offline Mode — Contradictory, Not Production-Ready

| | Origin Specification | Current System |
|---|---|---|
| **Offline spec** | "Operates on local network with offline capabilities"; queued transactions stored locally and synced | Contradictory: offline machinery exists (service worker, IndexedDB) but active submit path is mostly live-only |
| **Status** | In-scope requirement | Outstanding gap; needs a contract decision (live-only OR true offline) before it can be called delivered |

---

## 3. Feature-by-Feature Comparison

### 3.1 Original In-Scope Items

| Feature | Origin Specification | Current Status | Notes |
|---|---|---|---|
| Tablet ordering app per table | ✅ Specified | ✅ Delivered | Nuxt 3 PWA (Grillpad); `tablet-ordering-pwa/` |
| Digital menu (photos, categories, modifiers) | ✅ Specified | ✅ Delivered | Menu browsing, packages, meat selection |
| Tap-to-order, quantity selection | ✅ Specified | ✅ Delivered | Cart management |
| Order summary, confirmation, live status | ✅ Specified | ✅ Delivered | Order confirmation; session state via Reverb |
| Staff call buttons (service, water, billing, cleanup) | ✅ Specified | ⚠️ Partial | Service request system delivered; broadcast auth has security gaps requiring hardening |
| Kitchen Display System (KDS) | ✅ Specified | 🔄 Replaced | Replaced by Woosoo Print Bridge (see Section 2.1) |
| Admin dashboard (menu & order management) | ✅ Specified | ✅ Delivered | Laravel admin UI via Inertia.js + Vue 3 |
| 3rd Party POS integration | ✅ Specified | ✅ Delivered | Krypton POS driver; read-write via LAN IP `192.168.1.32` |
| Remote access to sales and closing data | ✅ Specified | ⚠️ Local only | Admin dashboard is LAN-accessible; no remote cloud access currently |
| Offline transaction queueing and cloud sync | ✅ Specified | ❌ Not delivered | Offline machinery incomplete; see Section 2.3 |
| QR code-based access | ✅ Specified | ❌ Not delivered | Not present in current system |
| No login required on tablet | ✅ Specified | ✅ Delivered | Device-based auth (Sanctum token per registered device, no per-user login) |
| Responsive design for tablets | ✅ Specified | ✅ Delivered | Tablet-targeted viewport |
| Custom branding (Woosoo identity) | ✅ Specified | ✅ Delivered | Theming applied |

### 3.2 Original Out-of-Scope Items (still not delivered)

| Feature | Status |
|---|---|
| Online ordering (web or mobile) | ❌ Still out of scope |
| Payment processing via tablet | ❌ Still out of scope |
| Loyalty awards | ❌ Still out of scope |

### 3.3 Added Beyond Original Scope

These features and systems were not in the original specification and represent additional delivered value.

| Feature | Description | Approx. Additional Cost |
|---|---|---|
| **Woosoo Print Bridge** | Flutter Android relay replacing KDS; WebSocket + polling intake, Bluetooth print dispatch, ACK lifecycle, retry logic | ₱150,000 |
| **Real-time WebSocket infrastructure** | Laravel Reverb server; broadcast channels for orders, sessions, service requests, print jobs | ₱75,000 |
| **On-premises Docker orchestration** | 8-service Docker Compose stack (Nginx, PHP, queue worker, scheduler, Reverb, MySQL, Redis, Nuxt PWA); multi-port Nginx routing | ₱75,000 |
| **Advanced admin UI** | Live order monitoring, print health dashboard, device health dashboard, session reset controls | ₱80,000 |
| **Role-Based Access Control (RBAC)** | Spatie permissions; multi-role admin hierarchy | ₱75,000 |
| **Multi-branch support** | Branch-scoped data and admin management | Included in RBAC item |
| **Service request system** | Reverb-powered staff call channels per device | ₱45,000 |
| **Enhanced POS integration** | Krypton driver hardening; POS-down handling; session close detection; outbox pattern | ₱25,000 |
| **TOTAL** | | **₱525,000** |

---

## 4. What Is Still Pending (Gap from Both Specifications)

These items are gaps relative to the original specification or known issues in the current system that have not yet been resolved.

| Item | Severity | Origin Spec? | Notes |
|---|---|---|---|
| Offline transaction queueing | Medium | ✅ Required | Not production-ready; contradictory code paths |
| QR code-based tablet access | Low | ✅ Required | Not implemented |
| Remote cloud access to sales data | Medium | ✅ Required | Admin is LAN-only; no cloud dashboard |
| Print Bridge ACK backlog (jobs stuck in `printedAwaitingAck`) | Critical | — | Print reliability gap; no TTL on stuck jobs |
| Broadcast channel auth hardening | Critical | — | `admin.print` and `service-requests` channels return `true` to all subscribers |
| Polling watermark loss (Bridge) | High | — | Bridge loses unprinted events after long downtime |
| Tablet WebSocket zombie state | Medium | — | Silent Reverb disconnect not detected; `SessionReset` broadcasts dropped |
| Print Bridge APK rebuild/install | Medium | — | Latest firmware (`830fdfd`) committed but APK not yet rebuilt and installed |

---

## 5. Project Cost Breakdown

### 5.1 Legacy Specification — ₱350,000.00 (Signed Contract)

| Work Item | Scope |
|---|---|
| Tablet ordering interface (Nuxt.js, per-table) | Included |
| Digital menu (photos, categories, modifiers) | Included |
| Kitchen Display System (KDS) | Included |
| Laravel API backend | Included |
| Admin dashboard | Included |
| Offline queueing + cloud sync | Included |
| QR code access | Included |
| 3rd party POS integration | Included |
| Remote sales reporting | Included |
| **Team** | 3-man development team |
| **Model** | One-time project |
| **Post-launch support** | 24 months free bug fixing |

**Payment milestones:** 30% kickoff / 30% MVP / 30% final delivery / 10% post-launch support

---

### 5.2 Current System — ₱875,000.00 (Estimated)

| Work Item | Estimated Cost |
|---|---|
| Tablet ordering interface (Nuxt 3 PWA) | ₱120,000 |
| Laravel API backend (hardened, production-grade) | ₱130,000 |
| Admin dashboard (Inertia.js + Vue 3) | ₱80,000 |
| Woosoo Print Bridge (Flutter Android relay) | ₱150,000 |
| Real-time WebSocket infrastructure (Reverb) | ₱75,000 |
| On-premises Docker Compose orchestration | ₱75,000 |
| Advanced admin UI (monitoring, health dashboards) | ₱80,000 |
| Role-Based Access Control (RBAC) | ₱75,000 |
| Service request system | ₱45,000 |
| Enhanced POS integration (Krypton hardening) | ₱25,000 |
| QA, integration testing, deployment | ₱20,000 |
| **Total (estimated)** | **₱875,000** |

> Estimates are based on Philippine market rates for a 3–4 developer team (Laravel, Flutter, Nuxt 3, DevOps). The current system scope is approximately **2.5× the original contract**.

---

### 5.3 Scope Delta — ₱525,000.00 (Additional Beyond Original Contract)

| | |
|---|---|
| **Original signed contract** | ₱350,000 |
| **Estimated cost of current system as built** | ₱875,000 |
| **Delta (additional scope delivered beyond contract)** | **₱525,000** |

The additional ₱525,000 represents:
- Architectural pivot from KDS to a production-grade Flutter print relay (₱150,000)
- Real-time infrastructure that did not exist in the original spec (₱75,000)
- On-premises Docker orchestration vs. a simple cloud-hosted deployment (₱75,000)
- Expanded admin capabilities beyond menu/order management (₱80,000)
- RBAC and multi-branch (₱75,000)
- Service request system and enhanced POS hardening (₱70,000)

---

## 6. Document Index

| Document | Status | Purpose |
|---|---|---|
| [Origin Specification](WOOSOO_ORIGIN_SPECIFICATION.md) | Archived | Original signed client brief (May 20XX) |
| [Nexus BRD](https://github.com/tech-artificer/woosoo-nexus/pull/138) | Draft PR | Current system BRD (3 functional apps) |
| [Platform BRD Supplement](WOOSOO_PLATFORM_BRD_SUPPLEMENT.md) | Canonical | woosoo-platform as 4th system component |
| **This document** | Canonical | Spec delta and cost analysis |
