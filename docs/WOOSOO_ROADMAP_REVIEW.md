---
status: canonical
last_reviewed: 2026-05-14
verified_by: cross-reference against four 2026-05-14 audit docs (Ecosystem, Nexus, Tablet PWA, Print Bridge)
scope: ecosystem
---

# Woosoo Roadmap Review

## Objective
Document the pasted "Master Improvement Roadmap" and capture a practical review before any implementation starts.

## Extracted roadmap
The roadmap covers 15 initiatives across three phases:

1. **Phase 1 - Stabilize the Core**
   - System health dashboard — *Audit reference:* Ecosystem §4 Medium #10 (observability fragmented), Nexus §2.4 Health & monitoring (Pulse + custom dashboard exist; gap is cross-app view)
   - Centralized logs and correlation IDs — *Audit reference:* Ecosystem §4 Medium #10. **Re-scope note:** gap is cross-app correlation, not centralization within Nexus (Pulse already installed)
   - Print job recovery system — *Audit reference:* Print Bridge §4 Critical #1 (ACK backlog), Critical #2 (polling watermark), Ecosystem §4 Critical #2 (two print architectures), Ecosystem §4 Critical #3 (ACK stranding)
   - Session state machine hardening — *Audit reference:* Ecosystem §4 High #4 (session identity inconsistency), Tablet §4 Critical #3 (bootstrap tolerance), Nexus §2.4 Session bootstrap (alias proliferation). **Re-scope note:** real problem is alias proliferation + bootstrap-tolerance contract, not the machine itself
   - Deployment doctor script — *Audit reference:* Nexus §4 High #8 (Reverb Windows/NSSM vs Docker mismatch), Ecosystem §2.2 Deployment (no compatibility matrix)
2. **Phase 2 - Operational Control**
   - Tablet device management — *Audit reference:* Nexus §4 Critical #1–2 (branch scoping weak), Ecosystem §3 Device identity (high drift risk)
   - Offline / poor network handling — *Audit reference:* Tablet §4 Critical #1 (offline ordering contradiction), Ecosystem §4 Critical #1. **Promote:** this is currently the PWA's biggest correctness risk; treat as a Phase 1 contract decision, not a Phase 2 feature
   - Admin audit trail — *Audit reference:* no direct audit finding; keep at Phase 2 priority
   - Real-time staff notifications — *Audit reference:* Nexus §4 Critical #4 (broadcast auth too permissive). **Sequencing note:** must follow Reverb auth hardening or you are scaling open channels
   - Version and update control — *Audit reference:* Tablet §2.5 Recovery and update (solid in PWA), Nexus §2.4 Deployment (no Laravel + PWA + APK compatibility matrix)
3. **Phase 3 - Handover + Long-Term Maintenance**
   - Backup and restore — *Audit reference:* Nexus §4 Medium #19 (entrypoint auto-migrate, no explicit rollback story)
   - Better tablet error UX — *Audit reference:* AGENTS.md Immutable Rules (no technical errors to customers); Tablet audit confirms recovery surfaces exist but UX hardening is not yet a slice
   - Test suite — *Audit reference:* Print Bridge §4 Critical #3 (suite currently red), Tablet §6 Verification (consolidated submit needed), Nexus §3 (tests are closer to truth than docs). **Promote:** Bridge red tests are a prerequisite for verifying Phase 1 print-determinism work
   - Client handover mode — *Audit reference:* no direct audit finding; keep at Phase 3
   - Analytics dashboard — *Audit reference:* **no audit-backed urgency.** Candidate for deferral to a post-handover follow-on; not in the re-weighted execution order below

Supporting sections define:

- cross-app request and response contracts
- security and race-condition checklists
- commit grouping by app
- documentation to create
- reference diagrams
- a five-sprint build sequence
- definition of done

## Strengths
The roadmap is strong at the strategy level:

1. It targets the real failure modes first: observability, printing, session consistency, and deployment health.
2. It recognizes that Woosoo is a multi-app system and includes shared contracts instead of treating each app in isolation.
3. It explicitly calls out idempotency, race conditions, security boundaries, and operator tooling.
4. It includes tests and concrete deliverables for most major workstreams.

## Gaps and risks
The plan is not yet implementation-ready in its current form.

1. **Too broad per sprint.** Each sprint still contains several large epics rather than thin, releasable slices.
2. **Ordering needs tightening.** Audit logs and dashboards are useful, but business-critical determinism for order submission and printing should land as early as possible.
3. **Dependencies are implied, not explicit.** Cross-app compatibility windows, rollout order, and temporary backward-compatible states are not defined.
4. **Acceptance criteria are uneven.** Many sections list tests, but operational thresholds are missing, such as heartbeat staleness limits, retry budgets, retention windows, and what counts as degraded vs critical.
5. **Migration and rollout safety are underspecified.** There is no explicit cutover plan for live deployments, data backfills, or rollback behavior per feature.
6. **Documentation scope is oversized upfront.** The docs list is useful, but writing all of it early would likely slow delivery and drift from reality.
7. **Commit guidance is too rigid as written.** Separate commits per app is good, but some features require coordinated backward-compatible releases across apps, not isolated delivery.

## Recommended execution order
Use a narrower, dependency-driven sequence:

1. **Observability foundation**
   - request IDs
   - structured logs
   - shared error/success envelope
   - contract version field
2. **Order and print determinism**
   - order submit idempotency
   - print job state machine
   - bridge callback contract
   - retry and resend rules
3. **Tablet session determinism**
   - bootstrap endpoint
   - explicit session phases
   - route guards
   - stale session reset rules
4. **Operational visibility**
   - health checks
   - health dashboard UI
   - device management
   - notifications where they close operational gaps
5. **Operations and handover**
   - doctor scripts
   - backup / restore
   - support bundle
   - client docs
   - broader test suite expansion

## Review verdict
This is a **good strategic roadmap** with the right instincts and the right problem areas.

It still needs one more pass to become an execution plan:

1. break each initiative into releasable slices
2. add explicit dependencies and rollout order across the three apps
3. define measurable acceptance criteria for health, retries, and stale-state handling
4. defer non-essential docs until the corresponding slice is implemented

## Audit reconciliation (2026-05-14)

This section reconciles the strategic roadmap above against the four canonical audit documents finalized on 2026-05-14. The roadmap's framing remains valid — the audits sharpen it.

### Cross-references

- [Ecosystem Engineering Review](WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md)
- [Nexus Stabilization & Hardening Audit](../woosoo-nexus/docs/WOOSOO_NEXUS_STABILIZATION_AND_HARDENING_AUDIT_2026-05-14.md)
- [Tablet PWA Production Stability Audit](../tablet-ordering-pwa/docs/TABLET_ORDERING_PWA_PRODUCTION_STABILITY_AUDIT_2026-05-14.md)
- [Print Bridge Production Reliability Audit](../woosoo-print-bridge/docs/WOOSOO_PRINT_BRIDGE_PRODUCTION_RELIABILITY_AUDIT_2026-05-14.md)

### What the audits confirm

The roadmap correctly targets observability, printing reliability, session consistency, and deployment health. Its multi-app framing, idempotency/race/security/operator-tooling call-outs, and self-critique all hold up against the audits' concrete findings. The 5-group recommended execution order is directionally right; it needs re-weighting (below) rather than rewriting.

### What the audits change

**Items the roadmap places later that the audits show are Critical now:**

1. **Offline ordering contradiction** (Tablet §4 Critical #1). The PWA simultaneously ships a service-worker offline outbox and an `OrderingStep3ReviewSubmit.vue` block on offline submit. This is the single biggest correctness risk in the PWA. Roadmap had this in Phase 2; promote to Phase 1 as a contract decision (live-only vs true-offline).
2. **Bridge ACK backlog** (Print Bridge §4 Critical #1). Jobs can park in `printedAwaitingAck` indefinitely with no TTL/age ceiling. Sharpen the roadmap's "Print job recovery system" to require explicit age + attempt ceilings and a deterministic terminal path.
3. **Polling watermark loss** (Print Bridge §4 Critical #2). `_since = now - 10 minutes` after long downtime silently loses old unprinted events. Add as a Phase 1 slice.
4. **Bridge tests currently red** (Print Bridge §4 Critical #3). Cannot verify Phase 1 print-determinism work until the baseline is green. Promote ahead of "Test suite" Phase 3 placement.
5. **Branch / tenant scoping** (Nexus §4 Critical #1–2). Cross-branch data visibility in `Admin\Device\DeviceController` and `Api\V1\DeviceApiController`. Security issue, not a feature gap. Add as a Phase 1 security slice.
6. **Broadcast channel auth** (Nexus §4 Critical #4). `admin.print` and `service-requests.{deviceId}` return `true`. Add as a Phase 1 security slice.
7. **GET credential endpoint `/api/token/create`** (Nexus §4 Critical #5). OWASP-grade; credentials in query strings/logs/proxies. Add as a Phase 1 security slice.
8. **`SessionApiController@reset()` device guard** (Nexus §4 Critical #3). Broken because of `get_class()` string comparison. One-line fix; add as an immediate item.

**Items missing from the roadmap that the audits demand:**

9. **Pick the single canonical print architecture** (Ecosystem §4 Critical #2). Two print stories ship at once because `print_events.enabled` only gates HTTP, not the service layer.
10. **Consolidate Tablet submit / idempotency abstractions** (Tablet §4 Critical #2). `useOrderSubmit`, `useOrderSubmission`, `useSubmissionIdempotency`, `useOfflineOrderQueue` overlap.
11. **Single persistence owner for PWA session/order cleanup** (Tablet §4 High #6–7). Manual `localStorage` writes fight Pinia persistence; hydration restores stale transactional state.
12. **Stale-refill reconciliation in Nexus** (Nexus §4 High #10). `RefillSubmission::isLockExpired()` exists with no consumer.
13. **Retention policy for Bridge queue / history / metrics** (Print Bridge §4 High #10). Production devices accumulate forever otherwise.
14. **Contract-first verification at CI grade** (Nexus §5 Action #9, Ecosystem §5 Action #1). The cure for `API_MAP.md`-style drift is auto-derived or test-pinned contracts, not more hand-written docs.

**Items the audits show should be deferred or downgraded:**

15. **Analytics dashboard** (roadmap Phase 3) — no audit-backed urgency. Defer to a post-handover follow-on.
16. **Real-time staff notifications** (roadmap Phase 2) — sequence *after* Reverb auth hardening (item 6 above).
17. **"Documentation to create" list** — most of what the roadmap was going to write is now in the four canonical audit docs. Trim to: (a) cross-app contracts derived from controllers/tests, (b) per-app operational runbooks, (c) Laravel + PWA + Bridge APK version compatibility matrix.

### Re-weighted execution order

Replaces the 5-group order above with a 6-group, dependency-aware sequence. Group 1 is the audit-driven security and correctness bump; the remaining groups follow the original strategy.

1. **Security & correctness Critical bumps** (must precede public exposure of any new feature work)
   - Branch scoping fix on Nexus admin/device endpoints
   - Broadcast channel auth hardening
   - Retire or convert GET credential endpoint
   - Fix `SessionApiController@reset()` device guard
   - Resolve PWA offline contradiction (pick a model)
   - Pick the single canonical print architecture

2. **Observability foundation**
   - Request IDs + structured logs across all three apps
   - Shared error/success envelope
   - Contract version field
   - Cross-app correlation (the actual gap, not centralization within Nexus)

3. **Order & print determinism**
   - Order submit idempotency consolidation (Tablet)
   - Stale-refill reconciliation (Nexus)
   - Bridge ACK backlog terminal policy (age + attempt ceilings)
   - Polling resume cursor (replace 10-minute synthetic window)
   - Print job state machine documented as one source of truth
   - Get the Bridge test suite green so this group can be verified

4. **Session determinism**
   - One canonical session contract; deprecate aliases
   - PWA bootstrap failure policy (no silent proceed)
   - PWA single persistence owner + hydration validity guard
   - Route guards consolidated; remove duplicated page-level recovery

5. **Operational visibility**
   - Health checks (already real in Nexus; extend cross-app)
   - Health dashboard UI
   - Device management
   - Notifications (after Group 1's auth hardening)

6. **Operations & handover**
   - Doctor scripts (Nexus runtime control alignment)
   - Bridge retention / cleanup jobs
   - Backup / restore
   - Support bundle
   - Version compatibility matrix across Laravel + PWA + Bridge APK
   - Test suite expansion beyond the per-app minimums
   - Client handover mode
   - (Analytics dashboard: deferred)

### Summary

The roadmap is **strategically right and tactically incomplete**. The audits replace its "implied dependencies" with concrete file paths and severity weights. After this reconciliation section, the doc is canonical: keep it as the strategic anchor and use the four 2026-05-14 audits for slice-level execution.

## Suggested next planning artifact
Before implementation, convert the roadmap into a tracked backlog with one epic per workstream and one thin slice per releaseable change.
