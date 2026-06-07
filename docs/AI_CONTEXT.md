---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# Woosoo AI Project Context

Load this file when an AI agent needs business and architecture context beyond the root `AGENTS.md`. Per-task token cost should stay low — read only the sections relevant to the task.

For the full ecosystem map (five components, delivery status, flows), see
[`docs/WOOSOO_ECOSYSTEM_OVERVIEW.md`](WOOSOO_ECOSYSTEM_OVERVIEW.md).

## System Overview

**Woosoo** is the ecosystem name. **Nexus** (`woosoo-nexus`) is the Laravel backend and manager
admin — not the umbrella label for all apps.

Three **production** apps form an operational chain, plus platform governance and a portal prototype:

| App | Path | Role | Status |
|-----|------|------|--------|
| **woosoo-platform** | `.` | Docker orchestration, contracts, agent OS, deployment docs | Production |
| **woosoo-nexus** | `woosoo-nexus/` | Laravel API + **Inertia manager admin**, POS/Krypton, Reverb, print-event orchestration | Production |
| **tablet-ordering-pwa** | `tablet-ordering-pwa/` | Nuxt 3 SPA/PWA: customer tablet ordering, session/recovery UX, Echo/Reverb client | Production |
| **woosoo-print-bridge** | `woosoo-print-bridge/` | Flutter Android relay: WebSocket/polling intake, Bluetooth printer dispatch, ACK lifecycle | Production |
| **woosoo-portal** | external / `ryanpastorizadev-bit/woosoo-portal` | Owner cloud reporting UI (Laravel 13/Inertia prototype; Nexus sync Phase 2) | Prototype UI |

System truth is split:

- **Nexus** owns business truth (pricing, modifiers, package rules, POS mapping, order state, print-event state).
- **PWA** owns customer interaction state, local recovery, and persisted draft/session data.
- **Print bridge** owns the real last-mile print outcome (printer health, ACK, dead-letter) — **canonical production print path**.
- **Portal** (when integrated) will consume EOD sync batches from Nexus; not connected today.

**Manager admin** is embedded in `woosoo-nexus` (Inertia/Vue), not a separate deployable app.

## Core Architecture Rules

> Immutable enforcement rules (one-app scope, order state machine, no raw errors to customers): see AGENTS.md → "Immutable Rules".

- Backend is source of truth for pricing, modifiers, package rules, POS mapping, order state.
- Tablet sends **intent only**: `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`.
- Order states: the `OrderStatus` enum (`pending, confirmed, in_progress, ready, served, completed, cancelled, voided, archived`); terminal = `completed | cancelled | voided | archived`. See `contracts/order-state.contract.md`. Do not invent states beyond the enum.
- All packages include unlimited sides and meats within their modifier set. Three packages: Classic Feast, Noble Selection, Royal Banquet.
- Printing: **Print Bridge** executes jobs in production (`NEXUS_PRINT_EVENTS_ENABLED` defaults off). Station-based; jobs must be idempotent at reserve/ack/failed.
- POS integration uses a static LAN IP: `192.168.1.32` (restaurant network profile).
- LAN-first is production-ready; full offline tablet queueing and Nexus→portal EOD sync are **not** delivered — see `docs/business/WOOSOO_SPEC_DELTA.md`.

## Cross-App Contracts (canonical references)

| Contract surface | Source of truth | See |
|------------------|-----------------|-----|
| Device registration / auth | `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php` | Nexus audit doc |
| Session lifecycle | Nexus session controllers + `/api/sessions/*` routes | Nexus audit + Ecosystem audit |
| Order submit | `POST /api/devices/create-order` (Nexus) | Tablet audit + Nexus audit |
| Print event lifecycle | `POST /api/printer/print-events/{id}/{reserve,ack,failed}` | Print Bridge audit + `contracts/printer-relay.contract.md` |
| Reverb channels/events | `woosoo-nexus/routes/channels.php` | `contracts/websocket-events.contract.md` |
| Heartbeat | `POST /api/printer/heartbeat` (bridge), `/api/health` (Nexus) | Print Bridge audit + Nexus audit |
| Cloud EOD sync (planned) | not implemented | `docs/cases/woosoo-cloud-portal-sync-plan-review.md` |

Authoritative audit documents (read on demand):

- `docs/WOOSOO_ECOSYSTEM_OVERVIEW.md` — ecosystem map and delivery status.
- `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` — cross-app review.
- `woosoo-nexus/docs/archive/2026-05/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` — backend audit copy currently present in this checkout; verify claims against live source/contracts.
- `tablet-ordering-pwa/docs/archive/2026-05/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md` — tablet audit copy currently present in this checkout; verify claims against live source/contracts.
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md` — print bridge audit.

## Error Handling

Customer-facing screens: friendly messages only. Example fallback: "We could not send your order yet. Please ask a staff member for assistance." Technical details (stack traces, SQL errors, exception dumps) go to logs only.

## Config Integrity

Watch for key mismatches: app key, Reverb key, API keys, POS IP. Admin tooling should support a `woosoo:verify-integrity` command. Do not write secrets to `.env` without backup and review.

## Workspace Boundary Rule

One app per task unless documented integration. Cross-app changes require updating the relevant contract section in the corresponding audit doc first.

## Pre-merge Checklist

Run `scripts/pre-merge-check.sh --app <name>` (Bash) or `scripts/pre-merge-check.ps1 -App <name>` (PowerShell). Without passing, do not mark work complete. Per-app commands are documented in the root `AGENTS.md`.

## Token Budget Discipline

This file is loaded on demand. Do not paste its full contents into prompts — link to the relevant section instead. Detailed contracts and runtime facts live in the audit docs above and are loaded only when the task requires them.
