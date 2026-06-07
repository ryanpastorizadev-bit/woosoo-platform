---
status: canonical
last_reviewed: 2026-06-06
scope: ecosystem
---

# Woosoo Document Context

Use this page as the concise orientation layer for work in `woosoo-platform`,
`woosoo-nexus`, `tablet-ordering-pwa`, `woosoo-print-bridge`, and `woosoo-portal`. For any
implementation decision, verify against live source and the contract files.

Full ecosystem map: [`WOOSOO_ECOSYSTEM_OVERVIEW.md`](WOOSOO_ECOSYSTEM_OVERVIEW.md).

## System Roles

| Area | Path | Role | Status |
| --- | --- | --- | --- |
| Platform governance | `.` | Agent protocol, contracts, case files, orchestration state, deployment docs, and platform-root Docker/deployment guidance. | Production |
| Nexus | `woosoo-nexus/` | Laravel backend **and manager admin UI** (Inertia). Owns API contracts, POS/Krypton integration, order truth, Reverb broadcasts, print-event orchestration, and backend validation. | Production |
| Tablet PWA | `tablet-ordering-pwa/` | Nuxt 3 customer tablet app. Owns kiosk interaction, package/menu browsing, local UI/session recovery, and Echo/Reverb client behavior. | Production |
| Print Bridge | `woosoo-print-bridge/` | Flutter Android print relay. Owns printer identity, heartbeat, queue intake, Bluetooth dispatch, and reserve/ack/failed handling. **Production print executor.** | Production |
| Owner portal | `woosoo-portal` (GitHub) / local `woosoo-cloud-portal` | Laravel/Inertia owner reporting UI foundation. Mock operational data today; Nexus EOD sync Phase 2. | Prototype UI |

The production apps form a chain. The tablet captures customer intent, Nexus validates and
persists business truth, and the Print Bridge proves the last-mile printer outcome. The owner
portal is a separate repo intended for cross-branch reporting once sync is implemented.

## Critical Invariants

- Backend owns truth for pricing, modifiers, package rules, POS mapping, order state, and print-event state.
- Tablet order submission is intent-only: `{ guest_count, package_id, items: [ { menu_id, quantity } ] }`.
- Tablet must not send pricing, tax, modifiers, totals, POS mapping, or order state.
- Customer-facing screens must show friendly messages only; raw SQL, stack traces, and technical errors belong in logs.
- One app per task and commit unless the work is explicitly scoped as integration/contract work.
- Order states come from `contracts/order-state.contract.md` and `woosoo-nexus/app/Enums/OrderStatus.php`; do not invent new states.
- Terminal order states are `completed`, `cancelled`, `voided`, and `archived`.
- Print delivery must be idempotent at the reserve/ack/failed lifecycle; Print Bridge is the active production path.
- Do not hardcode LAN IPs or API/Reverb hosts in tablet or bridge code.
- Manager admin is part of Nexus — not a fifth runtime service on the LAN stack.

## Cross-App Flow

1. Tablet sends order intent to Nexus with device auth.
2. Nexus validates package/menu intent, derives business data, writes through POS/Krypton and local persistence, then emits order/print signals after commit.
3. Print Bridge receives print work through WebSocket or polling, reserves the job, prints to the mapped station printer, then ACKs or marks failure.
4. Nexus remains the contract owner for API state, while Print Bridge owns the physical printer result.
5. *(Planned)* Nexus pushes EOD batches to woosoo-portal — not implemented; see `docs/cases/woosoo-cloud-portal-sync-plan-review.md`.

## Source Of Truth

- `AGENTS.md` - operating protocol, one-app rule, hook routing, and validation expectations.
- `docs/WOOSOO_ECOSYSTEM_OVERVIEW.md` - five-component map and delivery status.
- `docs/AI_CONTEXT.md` - compact business and architecture context.
- `docs/README.md` - canonical documentation index.
- `contracts/order-state.contract.md` - order state enum and transition contract.
- `contracts/tablet-api.contract.md` - tablet-to-backend payload contract.
- `contracts/printer-relay.contract.md` - printer heartbeat and print idempotency contract.
- `contracts/websocket-events.contract.md` - Reverb event and channel map.
- `docs/cases/<task-slug>.md` - durable per-task resume point and agent-chain checkpoint.
- `state/WORK.md` - convenience cache only; never treat it as authoritative over case files.

Current checkout note: `woosoo-nexus/.agents.md` exists, but
`tablet-ordering-pwa/.agents.md` and `woosoo-print-bridge/.agents.md` are not
present in this checkout. Use `AGENTS.md`, the contracts, and live app docs/source
for those apps until app-local scope files are restored.

## Audit References

- `docs/WOOSOO_ECOSYSTEM_OVERVIEW.md` - ecosystem map.
- `docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` - ecosystem review.
- `woosoo-nexus/docs/archive/2026-05/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md` - Nexus audit copy currently present in this checkout.
- `tablet-ordering-pwa/docs/archive/2026-05/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md` - Tablet audit copy currently present in this checkout.
- `woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md` - Print Bridge audit.

The Nexus and Tablet audit copies live under archive paths in this checkout, so
verify any implementation claim against live source and contracts before relying
on those older audit files.

## Validation Commands

Run validation from the platform root:

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
.\scripts\pre-merge-check.ps1 -App tablet-ordering-pwa
.\scripts\pre-merge-check.ps1 -App woosoo-print-bridge
```

Equivalent Bash entrypoints:

```bash
bash scripts/pre-merge-check.sh --app woosoo-nexus
bash scripts/pre-merge-check.sh --app tablet-ordering-pwa
bash scripts/pre-merge-check.sh --app woosoo-print-bridge
```

For docs-only work, run link/path checks with `rg`, inspect `git diff --stat`,
and record why no app pre-merge gate applies.
