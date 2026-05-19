---
status: canonical
last_reviewed: 2026-05-14
scope: ecosystem
---

# Woosoo AI Project Context

Load this file when an AI agent needs business and architecture context beyond the root `AGENTS.md`. Per-task token cost should stay low — read only the sections relevant to the task.

## System Overview

Three apps form a chain, not a single coherent runtime:

| App | Path | Role |
|-----|------|------|
| **woosoo-nexus** | `woosoo-nexus/` | Laravel backend: admin UI, API, POS/Krypton integration, Reverb broadcasting, print event orchestration, Docker runtime |
| **tablet-ordering-pwa** | `tablet-ordering-pwa/` | Nuxt 3 SPA/PWA: customer-facing tablet ordering, session/recovery UX, Echo/Reverb client |
| **woosoo-print-bridge** | `woosoo-print-bridge/` | Flutter Android relay: WebSocket/polling intake, Bluetooth printer dispatch, ACK lifecycle |

System truth is split:

- **Nexus** owns business truth (pricing, modifiers, package rules, POS mapping, order state, print-event state).
- **PWA** owns customer interaction state, local recovery, and persisted draft/session data.
- **Print bridge** owns the real last-mile print outcome (printer health, ACK, dead-letter).

## Core Architecture Rules

- Backend is source of truth for pricing, modifiers, package rules, POS mapping, order state.
- Tablet sends **intent only**: `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`.
- Order states: `confirmed → completed | voided | cancelled`. No additional states.
- All packages include unlimited sides and meats within their modifier set. Three packages: Classic Feast, Noble Selection, Royal Banquet.
- Printing: station-based, sides → cashier. Print jobs must be idempotent at the reserve/ack level.
- POS integration uses a static LAN IP: `192.168.1.32`.

## Cross-App Contracts (canonical references)

| Contract surface | Source of truth | See |
|------------------|-----------------|-----|
| Device registration / auth | `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php` | Nexus audit doc |
| Session lifecycle | Nexus session controllers + `/api/sessions/*` routes | Nexus audit + Ecosystem audit |
| Order submit | `POST /api/devices/create-order` (Nexus) | Tablet audit + Nexus audit |
| Print event lifecycle | `POST /api/printer/print-events/{id}/{reserve,ack,failed}` | Print Bridge audit + Nexus audit |
| Reverb channels/events | `woosoo-nexus/routes/channels.php` | Ecosystem audit |
| Heartbeat | `POST /api/printer/heartbeat` (bridge), `/api/health` (Nexus) | Print Bridge audit + Nexus audit |

Authoritative audit documents (read on demand):

- `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` — cross-app review.
- `woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` — backend audit.
- `tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md` — tablet audit.
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

This file is loaded on demand. Do not paste its full contents into prompts — link to the relevant section instead. Detailed contracts and runtime facts live in the four audit docs above and are loaded only when the task requires them.
