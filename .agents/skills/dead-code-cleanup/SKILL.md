---
name: dead-code-cleanup
description: Pre-completion hygiene sweep — remove unused imports/components, temp files, debug logs, commented-out code, stale helpers, orphaned docs, abandoned scripts.
---

# Dead Code Cleanup

Run before declaring a task complete. Check and remove:

- Unused imports and unused components introduced by this change.
- Temporary files and scratch files created during investigation.
- Duplicate files and abandoned scripts.
- Debug logs and `console.log` / `dd()` / `dump()` left in.
- Commented-out code blocks.
- Stale test helpers no longer referenced.
- Orphaned docs created and then obsoleted by this task.

**Rule:** if a file was created temporarily, remove it before completion. The working tree must
contain only the intended change.

---

## Anti-Orphan Audit Checklist (run before every release)

Ecosystem-level sweep across all 3 app repos. Annotate each item NOT VERIFIED if evidence
is unavailable — do not infer, invent, or extrapolate. Request proof.

**Routes & endpoints**
- [ ] Unused routes (Laravel `routes/api.php`, `routes/web.php`)
- [ ] Unused API endpoints (no consumer anywhere in tablet / bridge / admin)

**Frontend**
- [ ] Unused Vue pages (`pages/**/*.vue` with no navigation link or route)
- [ ] Unused composables (`composables/use*.ts` with no import)
- [ ] Unused Pinia stores (`stores/*.ts` with no consumer)

**Backend events & jobs**
- [ ] Unused Laravel events (declared but never dispatched, or dispatched with no listener)
- [ ] Unused listeners (registered in `EventServiceProvider` but no matching event)
- [ ] Unused jobs (never dispatched anywhere)
- [ ] Unused broadcast channels (subscribed by no consumer)

**Database**
- [ ] Unused migrations (created tables/columns with no model or query reference)
- [ ] Unused database columns (present in schema, absent from models/queries)

**Config & environment**
- [ ] Unused env variables (declared in `.env.example`, never read)
- [ ] Unused Docker services (defined in `compose.yaml`, never referenced)

**Dependencies**
- [ ] Unused npm packages (`package.json` entries with no import anywhere)
- [ ] Unused Composer packages (`composer.json` entries with no use statement anywhere)

**Logic duplication**
- [ ] Duplicate business logic (same rule implemented independently in ≥ 2 repos)
- [ ] Duplicate validation rules (same field validated differently across repos)
- [ ] Duplicate status definitions (same state named differently: e.g. `preparing` vs `in_progress`)
- [ ] Duplicate enums (same set of values defined in multiple files)
- [ ] Duplicate constants (same magic string/number defined in multiple places)

**Known confirmed orphans (as of 2026-06-13 — verify before deleting)**
- [ ] `woosoo-nexus`: `PrintController.php`, `EventReplayController.php`,
  `ServiceMonitorController.php` — orphaned controllers
- [ ] `woosoo-nexus`: `Admin/Orders/Index.vue` subscribes `admin.print` channel — no producer
- [ ] `woosoo-nexus` broadcast: `payment.completed`, `menu.updated`, `package.updated`,
  `table-service` — dead producers with no consumer
- [ ] `tablet-ordering-pwa`: `useOfflineOrderQueue.ts` — likely superseded
- [ ] `tablet-ordering-pwa`: 3 competing idempotency helpers (`useOrderSubmit.ts`,
  `useOrderSubmission.ts`, `useSubmissionIdempotency.ts`) — merge into one
- [ ] `tablet-ordering-pwa`: `config/api.ts` stale `/api/device/login` constant
- [ ] `woosoo-print-bridge`: `performance_monitor.dart`, `time.dart` — likely unused
- [ ] `woosoo-print-bridge`: `share_plus` dependency — verify usage before removing

See `docs/cases/plt-case-010-orphan-remediation.md` for the tracked execution plan.
