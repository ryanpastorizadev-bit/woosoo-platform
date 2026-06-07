---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# Woosoo Ecosystem Overview

**Woosoo** is a local-first restaurant operations platform: multiple independent applications
share a common backend on the restaurant LAN. **Nexus** (`woosoo-nexus`) is the Laravel backend
and manager admin — not the name of the whole ecosystem.

Use the **Delivered / Prototype / Planned** column below before treating any feature as
production-ready. Verify implementation claims against live source and
[`contracts/`](../contracts/).

---

## Core philosophy

- **Local-first:** Production runs on-premises (Raspberry Pi + LAN). Service does not depend on
  public cloud uptime during dining hours.
- **Backend owns truth:** The tablet sends intent only
  (`{ guest_count, package_id, items: [{ menu_id, quantity }] }`). Nexus computes pricing,
  modifiers, POS mapping, and order state.
- **Split runtime truth:** Nexus owns business data, the tablet owns customer interaction/recovery
  state, and the Print Bridge owns the physical print outcome (ACK/dead-letter).

**Nuance:** LAN-first is delivered. Full offline tablet queueing and Nexus→cloud EOD sync are
**not** delivered end-to-end yet. See [`business/WOOSOO_SPEC_DELTA.md`](business/WOOSOO_SPEC_DELTA.md).

---

## Components

| Component | Repository | Status | Role |
| --- | --- | --- | --- |
| **woosoo-platform** | [`ryanpastorizadev-bit/woosoo-platform`](https://github.com/ryanpastorizadev-bit/woosoo-platform) | Delivered | Docker orchestration, contracts, agent OS, deployment scripts, governance docs |
| **woosoo-nexus** | [`tech-artificer/woosoo-nexus`](https://github.com/tech-artificer/woosoo-nexus) | Delivered | Laravel API, **Inertia manager admin UI**, POS/Krypton, Reverb, print-event orchestration |
| **tablet-ordering-pwa** | [`tech-artificer/tablet-ordering-pwa`](https://github.com/tech-artificer/tablet-ordering-pwa) | Delivered | Nuxt 3 customer kiosk PWA; Echo/Reverb client |
| **woosoo-print-bridge** | [`tech-artificer/woosoo-print-bridge`](https://github.com/tech-artificer/woosoo-print-bridge) | Delivered | Flutter Android relay; Bluetooth thermal print; reserve/ack/failed lifecycle |
| **woosoo-portal** | [`ryanpastorizadev-bit/woosoo-portal`](https://github.com/ryanpastorizadev-bit/woosoo-portal) | Prototype UI | Owner cloud reporting layer (Laravel/Inertia UI foundation; integration Phase 2) |

**Admin UI:** The manager admin portal is **inside woosoo-nexus** (same Laravel deploy, Inertia +
Vue 3). It is not a separate runtime app.

**Print path:** `woosoo-print-bridge` is the **production print executor**. Nexus native print
events exist but are gated by `NEXUS_PRINT_EVENTS_ENABLED` (defaults off).

---

## Architecture (simplified)

```text
                    ┌─────────────────────────┐
                    │      woosoo-portal      │  Prototype UI (owner cloud; sync TBD)
                    └───────────┬─────────────┘
                                │  planned EOD sync
                                ▼
┌───────────────────────────────────────────────────────────────┐
│  woosoo-platform  —  compose.yaml, contracts, deploy scripts │
└───────────────────────────────┬───────────────────────────────┘
                                │ orchestrates
                                ▼
┌───────────────────────────────────────────────────────────────┐
│  woosoo-nexus  —  API + manager admin + Reverb + MySQL       │
└───────┬─────────────────┬────────────────────┬────────────────┘
        │                 │                    │
        ▼                 ▼                    ▼
  tablet-ordering-pwa   (admin UI)      woosoo-print-bridge
  customer tablets      same process     kitchen print relay
```

---

## Operational flows

### Ordering

Customer → tablet PWA → Nexus API → MySQL/POS. Tablet payload is intent-only; see
[`contracts/tablet-api.contract.md`](../contracts/tablet-api.contract.md).

### Printing

Order/refill in Nexus → print events on `admin.orders` (+ polling fallback) → Print Bridge
reserves → prints → ACKs or fails. See
[`contracts/printer-relay.contract.md`](../contracts/printer-relay.contract.md).

### Real-time

Laravel Reverb broadcasts to tablets, Nexus admin, and Print Bridge. Canonical event map:
[`contracts/websocket-events.contract.md`](../contracts/websocket-events.contract.md).

Key tablet lifecycle events: `order.completed`, `order.voided`, `order.cancelled`,
`session.reset`.

### Cloud sync (planned)

Local branch → manual EOD batch push → woosoo-portal. **Not implemented.** Nexus sync module
and `contracts/cloud-sync-batch.contract.md` do not exist yet. Plan review:
[`cases/woosoo-cloud-portal-sync-plan-review.md`](cases/woosoo-cloud-portal-sync-plan-review.md).

---

## Packages (production menu)

Three KBBQ packages (unlimited sides/meats within modifier set):

- Classic Feast
- Noble Selection
- Royal Banquet

---

## Deployment

Docker authority is **platform repo root** only (`compose.yaml` — 8 services: nginx, app,
queue, scheduler, reverb, tablet-pwa, mysql, redis). See
[`deployment/DEPLOYMENT_GUIDE.md`](deployment/DEPLOYMENT_GUIDE.md).

Network switching (home vs restaurant LAN): `scripts/deployment/switch-network.sh`.

---

## Documentation map

| Doc | Purpose |
| --- | --- |
| [`README.md`](README.md) | Canonical doc index |
| [`AI_CONTEXT.md`](AI_CONTEXT.md) | Compact agent context |
| [`WOOSOO_DOCUMENT_CONTEXT.md`](WOOSOO_DOCUMENT_CONTEXT.md) | One-page orientation |
| [`WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md`](WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md) | Cross-app engineering audit |
| [`business/WOOSOO_SPEC_DELTA.md`](business/WOOSOO_SPEC_DELTA.md) | Origin spec vs delivered system |

---

## Naming conventions

| Term | Meaning |
| --- | --- |
| **Woosoo** | The ecosystem / product family |
| **Nexus** | The `woosoo-nexus` Laravel backend (+ embedded manager admin) |
| **woosoo-portal** | GitHub repo for owner cloud portal |
| **woosoo-cloud-portal** | Common local folder name during development (composer: `woosoo/cloud-portal`) |

Do not use `woosoo-pportal`.
