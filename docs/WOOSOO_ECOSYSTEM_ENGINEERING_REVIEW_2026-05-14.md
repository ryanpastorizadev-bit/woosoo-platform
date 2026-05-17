---
status: canonical
last_reviewed: 2026-05-14
verified_by: route list + active test suite (Nexus tests partial; Print Bridge tests currently red)
scope: ecosystem
---

# Woosoo Ecosystem Engineering Review

## 1. Executive summary

- The Woosoo system runs as a **3-app chain** (Nexus + Tablet PWA + Print Bridge), not a single coherent product runtime. System truth is split: Nexus owns business truth, the PWA owns customer interaction state, the Print Bridge owns the real last-mile print outcome.
- The architecture is workable but **not yet contract-first**. Multiple session endpoints, two parallel print architectures (feature-flagged Nexus native + active Bridge), and inconsistent device-identity modeling create cross-app drift.
- The biggest correctness risks today are: (a) PWA simultaneously carrying live-only and offline-queue submit models, (b) ACK backlog that can strand printed jobs, (c) inconsistent branch scoping and broadcast authorization in Nexus.
- Cleanup is high-value but must follow contract decisions, not precede them. Pick one ordering model, one session contract, and one print architecture first; delete alternates afterwards.
- Observability is the foundation everything else depends on. There is no cross-app trace of an order from tablet → backend → print → ACK.

## 2. Runtime facts

### 2.1 Apps and roles

| App | Path | Real role today | Strongest area | Weakest area |
|---|---|---|---|---|
| `woosoo-nexus` | `woosoo-nexus/` | System backbone: admin, device auth, order/session APIs, refill logic, print-event truth, Reverb, monitoring, Docker runtime | Central business logic and operational breadth | Scoping/authorization consistency, route/contract drift, mixed old/new print paths |
| `tablet-ordering-pwa` | `tablet-ordering-pwa/` | Customer tablet client: bootstrap, ordering UX, session recovery, persisted local state, Echo/Reverb client | Recovery-oriented kiosk entry flow around `/` | Conflicting offline/submit architecture and duplicated state/submit abstractions |
| `woosoo-print-bridge` | `woosoo-print-bridge/` | Local printer worker: queue, poll/WS intake, Bluetooth dispatch, ACKs, dead-letter, operator tools | Single-worker print engine with real operator recovery tools | ACK lifecycle, polling watermark semantics, hardware/plugin fragility, stale tests |

### 2.2 Cross-app workflows

**Device bootstrap.** Nexus issues/validates device registration codes and stores device identity. PWA uses registration/login/refresh flows through device stores (`tablet-ordering-pwa/stores/Device.ts`, `pages/settings.vue`, `pages/auth/register.vue`). Print Bridge auto-attempts `GET /api/device/lookup-by-ip` and falls back to `POST /api/devices/register` (`woosoo-print-bridge/lib/services/api_service.dart`, `lib/state/app_controller.dart`). Nexus supports both security-code registration and IP-based auth/lookup (`woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`). **System issue:** device identity is not modeled once — sometimes "registered by code," sometimes "resolved by IP," sometimes "device token + table," sometimes "originating tablet ID seen in a print payload."

**Session lifecycle.** Nexus exposes several overlapping session endpoints (`GET /api/sessions/current`, `POST /api/sessions/join`, `GET /api/session/latest`, `GET /api/devices/latest-session`) with at least two different response shapes. PWA treats session start as a client-side lifecycle with server sync. Print Bridge uses `/api/devices/latest-session` only as ancillary metadata; polling is intentionally branch-wide. **System issue:** "session" means different things in each app.

**Order lifecycle.** PWA builds guest/package/menu state locally, then submits directly to Nexus via `POST /api/devices/create-order`. Nexus recalculates/normalizes the order, enforces active-order conflict rules, and broadcasts events. PWA path: `/` → `/order/start` → `/order/packageSelection` → `/menu` → `/order/review`. **System issue:** order creation is materially stronger in Nexus than in the PWA, but the client still carries a lot of quasi-transactional logic, local persistence, and conflict recovery. The intended online/offline contract is not singular.

**Print lifecycle.** Order/refill activity in Nexus creates print events. Reverb (`admin.orders`) and polling (`GET /api/printer/unprinted-events`) expose those events to the Print Bridge. The Bridge reserves (`POST /api/printer/print-events/{id}/reserve`), prints, ACKs (`/ack`), retries, or dead-letters locally. Nexus stores server-side print-event status and runs cleanup/retry scheduler jobs. **System issue:** Nexus still contains a feature-flagged native print-event path while the Print Bridge remains the active production printer path — two printing stories ship at once.

**Realtime updates.** Nexus runs Reverb. PWA uses Echo/Reverb. Bridge uses a Pusher-style WebSocket subscription to `admin.orders`. **System issue:** the channel/event model is not described by one source of truth. Some channels are loosely authorized (`service-requests.{deviceId}` always true, `admin.print` too open).

**Heartbeat / health.** Nexus exposes `/api/health`, Pulse, custom monitoring UI, and device heartbeat storage. Print Bridge posts `/api/printer/heartbeat` every 30 seconds with local queue/printer status. PWA has client recovery/update/offline status UX but no formal backend heartbeat contract. **System issue:** no single end-to-end view answers "tablet session healthy, backend healthy, print worker healthy, event pipeline healthy."

**Deployment.** Nexus Docker Compose is the nominal runtime authority (nginx/app/queue/scheduler/pulse/reverb/tablet-pwa/mysql/redis — `woosoo-nexus/compose.yaml`). **System issue:** production spans Laravel+Docker, Nuxt SPA/PWA, and Android Flutter — no unified runtime/deploy contract, rollback story, or version compatibility policy.

## 3. Contracts impacted

| Contract surface | Owner file(s) | last_verified | Drift risk | Downstream consumers |
|---|---|---|---|---|
| Endpoint names (session) | `woosoo-nexus/routes/api.php` | 2026-05-14 | **high** — overlapping aliases `/api/sessions/current`, `/api/session/latest`, `/api/devices/latest-session` | PWA session store; Bridge `ApiService` |
| Device auth endpoints | `woosoo-nexus/app/Http/Controllers/Api/V1/Auth/DeviceAuthApiController.php`; `tablet-ordering-pwa/config/api.ts` | 2026-05-14 | **high** — PWA still carries stale `/api/device/login` constants while live code uses `/api/devices/login` | PWA, Bridge |
| Request/response shapes | Nexus session controllers | 2026-05-14 | **medium** — `GET /api/sessions/current` returns `data` + timing metadata; `/api/devices/latest-session` returns `{ session: ... }` | PWA, Bridge |
| Auth assumptions | Nexus `AuthApiController`, `DeviceAuthApiController`; PWA `plugins/api.client.ts`; Bridge `ApiService` | 2026-05-14 | **high** — mixed guest, device-token, admin-session, and legacy GET-token behavior | PWA, Bridge |
| Device identity | Nexus auth controller; Bridge bootstrap; PWA device store | 2026-05-14 | **high** — IP-as-lookup vs IP-as-mutable-metadata; token vs table-based | PWA, Bridge |
| Session identity | PWA `stores/Session.ts`; Bridge `_startPolling()`; Nexus routes/controllers | 2026-05-14 | **high** — branch-wide polling with `sessionId = null` vs server-scoped session aliases | PWA, Bridge |
| Order IDs vs print event IDs | PWA order submit/recovery; Bridge `enqueueFromPayload()` | 2026-05-14 | **medium** — `order.order_id` vs `order.id`; `print_event_id` vs `id`; contract is shape-fragile | PWA, Bridge |
| Idempotency | Nexus `DeviceOrderApiController`, `DurableRefillGuard`; PWA `useOrderSubmit.ts`, `useOrderSubmission.ts`, `useSubmissionIdempotency.ts`; Bridge queue state machine | 2026-05-14 | **medium** — multiple PWA helpers compete for the same role | PWA |
| Timestamps / timezone | Nexus `server_time`, `session_started_at`, `printed_at`; PWA local timers + persisted flags; Bridge UTC watermarks + local `createdAt` | 2026-05-14 | **medium** — clock skew + offline replay window risk | All |
| Status enums | Nexus order/print/refill enums; Bridge `PrintJobStatus` (`pending`, `reserved`, `printing`, `printedAwaitingAck`, `success`, `failed`, `cancelled`) | 2026-05-14 | **medium** — Bridge statuses do not map 1:1 to server print-event status | PWA, Bridge |
| Heartbeat payloads | Bridge `sendHeartbeat()`; Nexus printer heartbeat/monitoring | 2026-05-14 | **low** — Bridge is printer-centric; PWA has no matching contract | Nexus admin |
| WebSocket channels/events | Bridge `ReverbService`; PWA `plugins/echo.client.ts`, `useBroadcasts.ts`; Nexus `routes/channels.php` | 2026-05-14 | **high** — channel auth is inconsistent (`service-requests.{deviceId}` always true, `admin.print` too open) | PWA, Bridge |
| Print lifecycle authority | Nexus print-event feature flag + printer APIs; Bridge runtime | 2026-05-14 | **high** — two parallel print narratives ship at once | Operations |
| Offline contract | PWA `OrderingStep3ReviewSubmit.vue`, `public/sw.ts`, `plugins/offline-outbox.client.ts`; Nexus order API; Bridge queue store | 2026-05-14 | **high** — PWA advertises offline but blocks offline initial orders | PWA |

## 4. Issues by severity

### Critical (blocks production correctness)

1. **Offline/order submission behavior is contradictory in the PWA.** The PWA contains both live-only and offline-queue models simultaneously; the active submit path is mostly live-only despite the advertised offline machinery. → File: `tablet-ordering-pwa/components/OrderingStep3ReviewSubmit.vue`, `public/sw.ts`, `plugins/offline-outbox.client.ts`. Fix direction: pick one model and delete the other.
2. **Two print architectures ship at once.** Nexus native print-event path is feature-flagged but present; the Bridge is the real production printer. → Fix direction: declare the Bridge the single canonical path and de-emphasize/remove the misleading native surface.
3. **ACK retry behavior can strand printed jobs.** Bridge can park jobs in `printedAwaitingAck` indefinitely if backend stays unavailable; no purge/TTL policy. → File: `woosoo-print-bridge/lib/state/app_controller.dart`, `lib/models/print_job.dart`. Fix direction: explicit age/attempt ceilings + operator visibility + deterministic terminal path.

### High (degrades reliability or operator visibility)

4. **Session identity inconsistency.** PWA can locally "start" a session while backend bootstrap had warnings; Bridge treats session as informational; Nexus exposes multiple aliases. → Fix direction: choose one canonical session contract and migrate both clients.
5. **Authorization and scoping gaps in Nexus.** Branch scoping is inconsistent; `admin.print` channel and service-request channels are too open; some admin/device queries are broader than intended. → File: `woosoo-nexus/routes/channels.php`, controller policies. Fix direction: branch-aware policy cleanup + tighter broadcast auth.
6. **Realtime is multi-writer.** PWA terminal/session state can be changed by watchers, timers, polling, and Reverb; Bridge consumes branch-wide events. → Fix direction: designate single writer per state slice, document in audits.
7. **Polling watermark loss risk.** Bridge polling `_since = now - 10 minutes` after long downtime trades flood-safety for silent loss of older unprinted events. → File: `woosoo-print-bridge/lib/services/polling_service.dart`. Fix direction: server-side resume cursor with explicit ACK of consumed range.
8. **Stale state risk in both clients.** PWA mixes Pinia persistence, manual storage writes, sessionStorage, Dexie, and SW queues. Bridge accumulates queue/history/metrics locally without retention. → Fix direction: retention policies + state-slice ownership rules.

### Medium (cleanup / dead code / stale docs)

9. **No canonical contract surface.** Nexus routes/tests are closer to reality than docs; PWA config constants and Bridge tests show drift. → Fix direction: generate canonical contracts from controllers/tests; freeze and version.
10. **Observability is fragmented.** Pulse (Nexus) + Bridge local logs + PWA recovery diagnostics — no cross-app trace. → Fix direction: correlation IDs + structured logs + shared error envelope.
11. **Deployment/config coupling fragile.** Compose is nominal authority but actual compatibility depends on PWA build and Bridge APK; no formal compatibility matrix.
12. **Stale docs and dead code in all three apps.** See per-app audits for the specific files.

## 5. Action items (prioritized)

Each slice is independently releasable. Acceptance criteria + rollback note are required before merging.

1. **Contract freeze.** Publish one canonical device/session/order/print contract surface in `docs/contracts/` (or extend existing per-app contract docs) and align tests to it before any new feature work. *Acceptance:* every endpoint listed in Section 3 has a single authoritative entry; integration tests reference that entry. *Rollback:* contract docs are additive — revert by removing the new files.
2. **Resolve the PWA order/offline contradiction.** Pick live-only or true offline; delete the alternates. *Acceptance:* only one submit path remains; offline machinery either backs every initial order or is removed. *Rollback:* git revert.
3. **Pick the production print architecture.** Officially declare the Bridge canonical; remove or feature-gate-off the Nexus native print-event surface. *Acceptance:* one print path is reachable in production config; the other is either removed or hard-disabled. *Rollback:* re-enable the flag.
4. **Fix Bridge print determinism.** ACK backlog rules, polling watermark semantics, manual-print verification shortcuts. See Print Bridge audit for slice list.
5. **Fix Nexus scoping/security gaps.** Branch-aware policies, broadcast auth, legacy token surface retirement. See Nexus audit for slice list.
6. **Normalize session semantics.** Collapse session endpoint aliases; document the chosen response shape; migrate PWA and Bridge to it.
7. **Stale-state cleanup.** Refill submission recovery in Nexus; Bridge retention rules; PWA hydration validity checks.
8. **Prune dead code and stale docs.** Once canonical paths exist, delete alternates aggressively. The 2026-05-14 archive pass started this; finish per-app once contracts are frozen.
9. **End-to-end observability.** Cross-app tracing/monitoring so support can follow one order through tablet → backend → print → ACK.
10. **Harden deployment/rollback.** Version compatibility matrix across Laravel + PWA build + Bridge APK; immutable runtime cleanup; rollback guidance.

### What to test first

1. Fresh device registration for tablet and bridge against the same branch.
2. Session bootstrap from clean state and from persisted stale state.
3. Initial order submit with idempotent retry and 409 conflict recovery.
4. Refill submit with retry and stale submission recovery.
5. Print event reserve → print → ACK → retry → dead-letter flows.
6. WebSocket-down fallback to polling and long-offline recovery.
7. Terminal order/session realtime transition handling in the PWA.
8. Unauthorized token refresh/relogin behavior in both PWA and Bridge.

## 6. Verification plan

For ecosystem-level changes:

```bash
# Per-app gates
bash scripts/pre-merge-check.sh --app woosoo-nexus
bash scripts/pre-merge-check.sh --app tablet-ordering-pwa
bash scripts/pre-merge-check.sh --app woosoo-print-bridge
```

Manual end-to-end smoke (after contract changes):

1. Power-cycle a tablet; confirm it bootstraps against current Nexus build without manual intervention.
2. Submit an order through the PWA; confirm Nexus broadcasts on `admin.orders` and the Bridge prints + ACKs within 30s.
3. Disconnect the Bridge from the network for ≥10 min; reconnect; confirm no print events are silently lost.
4. Inspect Nexus admin monitoring for matching device heartbeat + session + order + print-event records.

Failure of any step blocks merge.

## 7. Cross-references

- [Nexus audit](../woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md) — backend specifics
- [Tablet PWA audit](../tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md) — tablet client specifics
- [Print Bridge audit](../woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md) — print bridge specifics
- [Roadmap review](WOOSOO_ROADMAP_REVIEW.md) — strategic roadmap (currently `status: under-review`)
- [AI context](AI_CONTEXT.md) — business and architecture context for AI agents
- [Documentation audit 2026-05-14](audits/DOCS_AUDIT_2026-05-14.md) — what moved where in this cleanup pass

### Per-app cleanup pointers (from this review)

**woosoo-nexus:** orphaned `app/Http/Controllers/Api/V1/PrintController.php`, `app/Http/Controllers/Api/EventReplayController.php`, `app/Http/Controllers/Api/V1/ServiceMonitorController.php`; unreachable `resources/js/pages/auth/Register.vue`; duplicate `resources/js/pages/reports/sales/*`; duplicated token/session alias implementations in routes/controllers.

**tablet-ordering-pwa:** overlapping submit/idempotency helpers `useOrderSubmit.ts`, `useOrderSubmission.ts`, `useSubmissionIdempotency.ts`; likely superseded `useOfflineOrderQueue.ts`; stale `config/api.ts` endpoint constants; redundant registration surface `pages/auth/register.vue`; redundant recovery logic in `pages/menu.vue` and `pages/order/packageSelection.vue`.

**woosoo-print-bridge:** unused `lib/services/performance_monitor.dart`, likely unused `lib/core/time.dart`, likely unused `share_plus` dependency; `/orders` screen duplicates queue-history concerns without authoritative backend history.

Cross-system themes: compatibility aliases without deprecation plans; duplicate implementations kept "just in case"; docs describing intended architecture rather than active runtime; test/runtime drift in Bridge and stale config/runtime drift in PWA; admin/runtime control surfaces in Nexus that mix current and legacy deployment assumptions.
