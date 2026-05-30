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

It also provides a project cost breakdown: the original contracted amount, total actually billed, estimated fair market value of what was built, developer-absorbed scope, and pending change orders.

---

## 1. Cost Summary

| | Amount | Notes |
|---|---|---|
| **Original signed contract** | ₱350,000.00 | 3-man team quote, May 20XX |
| **Additional billed — Pi configuration** | ₱25,000.00 | Raspberry Pi 5 setup and deployment configuration |
| **Total actually billed to client** | **₱375,000.00** | Only amount invoiced beyond original contract |
| Estimated fair market value of system as built | ₱875,000.00 | Reference only — not invoiced; see Section 5 |
| Scope absorbed by developer at no charge | ~₱500,000.00 | Additional features delivered beyond billing |

> **Note:** All features added beyond the original contract (Print Bridge per client request, Docker orchestration, Reverb, RBAC, monitoring) were delivered at no additional cost to the client. The ₱875,000 figure reflects estimated fair market value, not the actual invoice.

---

## 2. What Changed at the Architecture Level

### 2.1 Kitchen Display System → Woosoo Print Bridge (Client-Requested Change)

This was a **client-initiated scope change**, not a developer architectural decision. The client requested replacing the KDS with Bluetooth printer integration. The developer built the Woosoo Print Bridge relay specifically to fulfill that request — bridging the admin system and the Bluetooth printer hardware.

| | Origin Specification | Current System |
|---|---|---|
| **Component name** | Kitchen Display System (KDS) | Woosoo Print Bridge |
| **Technology** | Not specified (assumed display terminal or web UI) | Flutter Android APK |
| **Runtime** | Staff-facing screen in kitchen | Android device running as a local relay |
| **Order intake** | Real-time orders from tablets | Reverb WebSocket (`admin.orders` channel) + HTTP polling fallback |
| **Output** | Color-coded on-screen ticket display | Bluetooth print dispatch to kitchen/cashier thermal printers |
| **Staff interaction** | Tag orders as "In Progress" / "Completed" | ACK lifecycle: reserve → print → ack (or failed) |
| **Reliability model** | Not specified | Idempotent print job with reserve/ack/failed lifecycle; dead-letter recovery |
| **Why it changed** | — | **Client requested Bluetooth printer integration.** Print Bridge relay was built to bridge the admin system and Bluetooth printer per client direction. |

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
| Kitchen Display System (KDS) | ✅ Specified | 🔄 Replaced | Replaced by Woosoo Print Bridge at **client's request** (see Section 2.1) |
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

### 3.3a Client-Requested Scope Changes (delivered, not separately billed)

Changes made at the client's explicit direction that differ from the original specification.

| Feature | Client Request | Estimated Value |
|---|---|---|
| **Woosoo Print Bridge** | Client requested Bluetooth printer integration in place of KDS; relay built to bridge admin system and printer hardware | ₱150,000 |

### 3.3b Developer-Added Scope (delivered at no charge)

These features were not in the original specification and were not client-requested — they were added by the development team to deliver a production-grade system. None were separately invoiced.

| Feature | Description | Estimated Value |
|---|---|---|
| **Real-time WebSocket infrastructure** | Laravel Reverb server; broadcast channels for orders, sessions, service requests, print jobs | ₱75,000 |
| **On-premises Docker orchestration** | 8-service Docker Compose stack (Nginx, PHP, queue worker, scheduler, Reverb, MySQL, Redis, Nuxt PWA); multi-port Nginx routing | ₱75,000 |
| **Advanced admin UI** | Live order monitoring, print health dashboard, device health dashboard, session reset controls | ₱80,000 |
| **Role-Based Access Control (RBAC)** | Spatie permissions; multi-role admin hierarchy | ₱75,000 |
| **Multi-branch support** | Branch-scoped data and admin management | Included in RBAC |
| **Service request system** | Reverb-powered staff call channels per device | ₱45,000 |
| **Enhanced POS integration** | Krypton driver hardening; POS-down handling; session close detection; outbox pattern | ₱25,000 |
| **TOTAL (developer-added, uncompensated)** | | **~₱375,000** |

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

### 5.2 Current System — Estimated Fair Market Value ₱875,000 (Actual Billed: ₱375,000)

| Work Item | Estimated Fair Value | Actually Billed |
|---|---|---|
| Tablet ordering interface (Nuxt 3 PWA) | ₱120,000 | Included in contract |
| Laravel API backend (hardened, production-grade) | ₱130,000 | Included in contract |
| Admin dashboard (Inertia.js + Vue 3) | ₱80,000 | Included in contract |
| Woosoo Print Bridge (client-requested) | ₱150,000 | Not separately billed |
| Real-time WebSocket infrastructure (Reverb) | ₱75,000 | Not separately billed |
| On-premises Docker Compose orchestration | ₱75,000 | Not separately billed |
| Advanced admin UI (monitoring, health dashboards) | ₱80,000 | Not separately billed |
| Role-Based Access Control (RBAC) | ₱75,000 | Not separately billed |
| Service request system | ₱45,000 | Not separately billed |
| Enhanced POS integration (Krypton hardening) | ₱25,000 | Not separately billed |
| Raspberry Pi configuration and deployment | ₱25,000 | **₱25,000 billed** |
| **Total** | **₱875,000** | **₱375,000** |

> The ₱875,000 is estimated fair market value based on Philippine market rates for a 3–4 developer team (Laravel, Flutter, Nuxt 3, DevOps). The client was invoiced ₱375,000 total. Approximately ₱500,000 in additional scope was absorbed by the development team at no charge.

---

### 5.3 Scope Delta

| | Amount |
|---|---|
| Original signed contract | ₱350,000 |
| Additional billed (Pi configuration) | ₱25,000 |
| **Total billed to client** | **₱375,000** |
| Estimated fair market value of system as built | ₱875,000 |
| **Scope absorbed by developer at no charge** | **~₱500,000** |

The ~₱500,000 absorbed by the developer breaks down as:
- Print Bridge (client-requested Bluetooth integration, replacing KDS): ₱150,000
- Real-time WebSocket infrastructure (Reverb): ₱75,000
- On-premises Docker orchestration: ₱75,000
- Advanced admin UI (monitoring, health dashboards): ₱80,000
- RBAC and multi-branch: ₱75,000
- Service request system and enhanced POS hardening: ₱70,000

> The Print Bridge is listed here because, while it was client-requested, it was not separately invoiced. It replaced the original KDS line item in the contract and was treated as a scope substitution with no additional charge.

---

## 6. Pending Change Orders

Change orders are client-initiated requests that fall outside the original contract scope.

### CO-001 — Kitchen Display System Re-addition

| | |
|---|---|
| **Requested by** | Client (post-testing feedback from restaurant staff and customers) |
| **Status** | Pending acceptance |
| **Estimated cost** | ₱100,000 |

**Background:** The original contract included a KDS. At the client's request, this was replaced by the Woosoo Print Bridge (Bluetooth printing). After real-world testing with staff and customers, the client has determined that a live kitchen display is also needed alongside the existing Bluetooth printing system.

This is the **second client-initiated scope change** on this item:
1. Change #1 (absorbed): KDS → Print Bridge, client asked to replace screen display with Bluetooth printing
2. Change #2 (this order): Add KDS back on top of the existing Print Bridge

Since the Print Bridge is already in production and the Reverb WebSocket infrastructure is fully operational, the KDS is a frontend display layer only — the backend events already fire.

**Scope:**

| Component | Estimated Cost |
|---|---|
| KDS display UI — real-time order feed, color-coded by status (New / In Progress / Completed) | ₱40,000 |
| Staff order status controls (mark In Progress / Completed) | ₱25,000 |
| Multi-station routing (e.g., grill station vs. cashier view) | ₱20,000 |
| On-site hardware setup and integration testing | ₱15,000 |
| **Total** | **₱100,000** |

---

## 7. Document Index

| Document | Status | Purpose |
|---|---|---|
| [Origin Specification](WOOSOO_ORIGIN_SPECIFICATION.md) | Archived | Original signed client brief (May 20XX) |
| [Nexus BRD](https://github.com/tech-artificer/woosoo-nexus/pull/138) | Draft PR | Current system BRD (3 functional apps) |
| [Platform BRD Supplement](WOOSOO_PLATFORM_BRD_SUPPLEMENT.md) | Canonical | woosoo-platform as 4th system component |
| **This document** | Canonical | Spec delta and cost analysis |
