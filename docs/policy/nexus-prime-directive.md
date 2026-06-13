---
status: canonical
received: 2026-06-13
scope: ecosystem
governance_integration: AGENTS.md + .claude/agents/contrarian.md + .agents/skills/dead-code-cleanup/SKILL.md
---

# Nexus Prime Directive

Strategic governance document submitted 2026-06-13. The 8-point Mission, GOAL CHECK, and
Anti-Orphan Checklist have been incorporated into the active governance system. See the
**Integration Status** column for each section.

---

## NEXUS MISSION

> Build a restaurant operating system that:

1. Increases order accuracy.
2. Reduces staff workload.
3. Reduces training requirements.
4. Operates reliably on unstable local networks.
5. Continues operating during partial service failures.
6. Produces accurate business reporting.
7. Is maintainable by a small engineering team.
8. Prioritizes operational reliability over technical elegance.

> Everything else is secondary. Every review begins by validating against this.

**Integration status:** ✅ Added to `AGENTS.md § NEXUS MISSION` and `AGENTS.md § Audit Checklist`.

---

## Common Issues — Codebase Validation (2026-06-13)

### 1. Solution-First Thinking

**Verdict: ⚠️ PARTIALLY ADDRESSED**

Contrarian agent already gates every task (challenges, validates problem, classifies tier).
AGENTS.md Prime Directive enforces "Correctness > speed."

Gap: No explicit 8-point mission checklist existed before this document. Now added to Contrarian
as a GOAL CHECK pre-step and to the Audit Checklist in AGENTS.md.

---

### 2. Over-Engineering Risk

**Verdict: ⚠️ ACKNOWLEDGED, NOT FORMALLY AUDITED**

Stack: Laravel 12, Nuxt 3, Pinia, Reverb, Redis, Flutter, Raspberry Pi, PWA/SSL/GHA.
`docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` explicitly acknowledges complexity.

Justified: 3 independent runtime targets (tablet kiosk, POS backend, print relay) with different
languages and deployment environments. Stack is appropriate for the problem.

Open item: Supabase and Vercel appear in stack documentation but their production usage is
unverified. Classify and remove or document.

---

### 3. State Synchronization Risk

**Verdict: ✅ WELL ADDRESSED**

`contracts/order-state.contract.md` (reviewed 2026-05-31): 9-state formal machine with explicit
transition matrix enforced via `OrderStatus::canTransitionTo()`. Terminal states protected.

Three sync patterns:
- (A) Reverb real-time <100ms
- (B) POS outbox consumer every 5s (`pos:consume-order-detail-events`, idempotent)
- (C) Device heartbeat every 30s

TAB-CASE-010 (APPROVED 2026-06-02) canonicalized all consumers to key on POS `order_id`.

Residual gap: 5 legacy dispatch sites in `woosoo-nexus` not yet migrated to `OrderBroadcaster.php`
(target architecture from NEX-CASE-013, migration pending). Until complete, "single broadcast
boundary" is target, not enforced.

---

### 4. Broadcast Dependency

**Verdict: ✅ ADDRESSED with tracked open items**

TAB-CASE-009 (APPROVED 2026-06-01): 30s/180s zombie-socket watchdog in `useBroadcasts.ts`.
NEX-CASE-006 (APPROVED 2026-05-20): `/api/health` broadcasts integrity check.
POS outbox polling (5s) provides a redundant sync path independent of Reverb.

Tracked open items (do not fix silently — tracked under NEX-CASE-011):
- `order.printed` name collision: `OrderPrinted` + `PrintOrder` + `PrintRefill` all broadcast
  `order.printed` on `admin.orders` → duplicate-print risk.
- Dead consumer: `Admin/Orders/Index.vue` subscribes `admin.print` — no producer exists there.
- Dead producers (no consumer anywhere): `payment.completed`, `menu.updated`, `package.updated`,
  `table-service`.

---

### 5. Missing Formal State Machines

**Verdict: ✅ FULLY ADDRESSED**

`contracts/order-state.contract.md` defines exactly 9 states. Transitions enforced by
`OrderStatus::canTransitionTo()`. Terminal states have zero outgoing transitions.
`ARCHIVED` is admin-only, unreachable from the live session lifecycle.

Confirmed: `IN_PROGRESS` cannot become `PENDING`. `COMPLETED` cannot transition at all.
`CANCELLED` cannot become `SERVED`. `PREPARING` does not exist — it is `IN_PROGRESS`.

Print Bridge has a separate `PrintJobStatus` enum (pending → reserved → printing →
printedAwaitingAck → success/failed/cancelled) tracked as its own contract surface.

---

### 6. Raspberry Pi Single Point of Failure

**Verdict: ⚠️ PARTIALLY ADDRESSED**

`docs/deployment/DEPLOYMENT_GUIDE.md` (2026-05-27): Pi vs. dev paths, setup, deploy.
`docs/deployment/RELEASE_RUNBOOK_order-id-pos-sync.md`: Bucket B Pi rollout steps.

Confirmed gap: no formal Pi SPOF recovery runbook for restaurant staff. Scenarios uncovered:
SD card corruption, power loss mid-order, disk full, memory exhaustion. Recovery today requires
developer intervention. Restaurant staff cannot self-recover.

New case filed: `docs/cases/plt-case-011-pi-spof-recovery-runbook.md`

---

### 7. Reporting Trustworthiness

**Verdict: ❌ NOT ADDRESSED**

`woosoo-pportal` (owner analytics portal) exists in stack documentation but has not been audited.
Observability is fragmented: Pulse (Nexus) + Bridge logs + PWA recovery UX = no cross-app trace.
No single end-to-end view answers "tablet healthy, backend healthy, print worker healthy, pipeline
healthy."

`docs/WOOSOO_ECOSYSTEM_ENGINEERING_REVIEW_2026-05-14.md` §2.5 explicitly notes this gap.

New case filed: `docs/cases/plt-case-012-reporting-observability-audit.md`

---

### 8. Duplicate Logic Across Repositories

**Verdict: ⚠️ PARTIALLY ADDRESSED**

6 canonical contracts define cross-app boundaries and prevent the most dangerous duplications.

Confirmed unresolved duplication:
- 3 competing idempotency helpers in tablet PWA: `useOrderSubmit.ts`, `useOrderSubmission.ts`,
  `useSubmissionIdempotency.ts`
- `OrderStatus`-like strings duplicated in tablet and bridge (shared `events.ts`/`events.dart`
  planned in NEX-CASE-013 but not yet shipped)
- `config/api.ts` in tablet: stale `/api/device/login` vs. live `/api/devices/login` — high
  drift risk per ecosystem review
- `BroadcastEvent.php` enum exists as the target for broadcast name deduplication but legacy
  dispatch sites not migrated

All tracked in plt-case-010 (orphan remediation).

---

### 9. Orphaned Features

**Verdict: ⚠️ DOCUMENTED, NOT REMEDIATED**

`dead-code-cleanup` skill exists; ecosystem review (2026-05-14) inventories confirmed orphans.
Full Anti-Orphan Checklist now incorporated into that skill.

New case filed: `docs/cases/plt-case-010-orphan-remediation.md`

---

### 10. Documentation Drift

**Verdict: ✅ MOSTLY ADDRESSED with one active drift**

Canonical contracts have `status: canonical` + `last_reviewed` dates. Case files track
implementation vs. intent. Evidence hierarchy in AGENTS.md.

Confirmed drift:
- Broadcast architecture described as "single boundary" in contract but 5 dispatch sites still not
  migrated (contract accurately labels this "IN PROGRESS" — good practice).
- CLAUDE.local.md lists TAB-CASE-009 as "queued" but it was APPROVED 2026-06-01.
- `config/api.ts` stale endpoint constant: `/api/device/login` vs live `/api/devices/login`.

---

## Anti-Hallucination Protocol

**Integration status:** ✅ Already in `AGENTS.md` and `docs/AGENT_DEFAULT_INSTRUCTIONS.md`

Evidence hierarchy (existing, unchanged):
1. Running code
2. Database schema
3. Tests
4. Documentation
5. User statement

Anything below #3 is suspect. Never assume. If evidence is unavailable, state: NOT VERIFIED.

---

## Anti-Drift Protocol (GOAL CHECK)

**Integration status:** ✅ Added to `AGENTS.md § Audit Checklist` and `.claude/agents/contrarian.md`

Every review begins with GOAL CHECK against the 8 NEXUS MISSION criteria.

---

## Anti-Orphan Audit Checklist

**Integration status:** ✅ Added to `.agents/skills/dead-code-cleanup/SKILL.md`

Full 27-item checklist with confirmed known orphans added to the dead-code-cleanup skill.

---

## SHERLOCK / MORIARTY Framework

**Integration status:** ✅ Mapped to existing agents — no new agents created

| Prime Directive | Existing equivalent |
|---|---|
| SHERLOCK (problem validator) | `contrarian` agent |
| MORIARTY (risk assessor) | `executioner` agent |
| Anti-Hallucination Protocol | `AGENTS.md` evidence hierarchy |
| Anti-Drift GOAL CHECK | `contrarian.md` pre-check + `AGENTS.md` Audit Checklist |
| Anti-Orphan Checklist | `dead-code-cleanup` skill |

SHERLOCK and MORIARTY were not created as new agents. The existing 4-agent chain already covers
this. Creating duplicate agents would fragment the Contrarian → Specialist → Verifier →
Executioner chain.
