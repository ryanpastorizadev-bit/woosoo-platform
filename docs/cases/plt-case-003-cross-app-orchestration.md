---
status: canonical
last_reviewed: 2026-05-25
scope: woosoo-platform
---

# CASE: plt-case-003-cross-app-orchestration

Cross-app orchestration and observability work to be executed after single-app fixes are complete and contracts are frozen.

## Run State
- task_slug: plt-case-003-cross-app-orchestration
- tier: 3
- branch: agent/plt-case-003-cross-app-orchestration
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-25

## Handoff
- Phase in progress: none — no agents have run
- Done so far: case scaffolded; Contrarian not yet started; `DEP-001`, `DEP-002`, and `DEP-003` are all confirmed in `state/DEPS.md`.
- Exact next action: Contrarian may start when this case is selected. NOTE: **not dependency-blocked** — DEP-001/002/003 are all `confirmed`. It is **deferred by priority** (QUEUE Bucket C, post-stabilization), not waiting on any provider.
- Working-tree state: clean
- Risks / do-not-redo: keep Tier 3 cross-app scope; re-check `state/DEPS.md` before implementation in case a dependency has changed.

## Tier
3

## Branch
agent/plt-case-003-cross-app-orchestration

## Problem

Cross-app observability and operational visibility cannot be implemented until single-app contracts are frozen and security fixes are complete. This case orchestrates the platform-level work.

## Contrarian Review

This is Tier 3 work because it touches cross-app contracts and requires coordination across all three apps. Must wait for:
- `nex-case-001-security-auth-hardening` (COMPLETE)
- `tab-case-001-order-session-determinism` (COMPLETE) 
- `prn-case-001-print-determinism` (COMPLETE)

**Risk assessment:**
- **High risk** of breaking cross-app compatibility
- **High risk** of coordination failures during deployment
- **Medium risk** of performance impact from observability overhead

**Dependencies:**
- All single-app cases must be complete
- Contracts must be frozen and versioned
- Requires coordinated deployment across all apps

## Investigation

Cross-app work identified in roadmap:
1. **Observability foundation** - Request IDs, structured logs, correlation
2. **Print architecture selection** - Choose single print path
3. **Health dashboard** - Cross-app health monitoring
4. **Version compatibility matrix** - Cross-app version tracking

## Proposed Fix

### Phase 1: Contract Freeze & Versioning
**Prerequisites:** All single-app cases complete
**Acceptance:** All API contracts documented and versioned
**Rollback:** Keep previous contract versions available

### Phase 2: Observability Implementation
**Scope:** Request IDs, structured logs, cross-app correlation
**Acceptance:** End-to-end request tracing across all apps
**Rollback:** Disable observability features if performance impact > 10%

### Phase 3: Operational Tooling
**Scope:** Health dashboard, version compatibility, deployment docs
**Acceptance:** Single dashboard for system health and compatibility
**Rollback:** Use existing individual health endpoints

## Files Changed

*To be populated during implementation*

## Verification

### Acceptance Criteria
- [x] All prerequisite single-app dependency records confirmed in `state/DEPS.md` (`DEP-001`, `DEP-002`, `DEP-003`)
- [ ] All single-app case evidence re-checked by Contrarian at task start
- [ ] API contracts frozen and versioned
- [ ] Cross-app request correlation functional
- [ ] Health dashboard shows all three apps
- [ ] Version compatibility matrix enforced
- [ ] Deployment documentation complete

## Contract References

- `../contracts/` - All contract files must be frozen
- Root `AGENTS.md` - Cross-app coordination rules
