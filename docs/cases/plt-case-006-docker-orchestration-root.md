---
status: under-review
last_reviewed: 2026-05-18
scope: ecosystem
---

# CASE: plt-case-006-docker-orchestration-root

Lift Docker orchestration to the platform repo root, fix tablet UI iteration &
installed-PWA auto-update, and consolidate the platform branches into a single
`staging` branch.

## Run State
- task_slug: plt-case-006-docker-orchestration-root
- tier: 3
- branch: staging
- status: IN_PROGRESS
- last_completed_agent: specialist:infra
- next_agent: verifier
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-18

## Handoff
- Phase in progress: verification before closure ("verify before closing")
- Done so far: platform-root compose + docker/ + scripts; BI removal (nexus);
  tablet PWA auto-update; branch consolidation onto `staging`.
- Exact next action: run the Verification checklist below; if green set
  `status: COMPLETE`.
- Working-tree state: case file added on `staging`; unrelated OS churn
  (docs/cases/prn-case-001, tab-case-001, inbox/*, state/*, prn-case-002,
  tab-case-002) intentionally left UNCOMMITTED — different workstream.
- Risks / do-not-redo: do not commit the OS churn here; do not push
  woosoo-nexus / tablet-ordering-pwa (platform-only scope).

## Tier
3 — production deployment topology + cross-repo architecture.

## Branch
`staging` (platform repo `ryanpastorizadev-bit/woosoo-platform`). Replaces the
former `staging/orchestration-hooks` (renamed → flat `staging`, then
fast-forwarded `9a4e220` → `baed1c2`).

## Problem
`woosoo-nexus/compose.yaml` was the orchestration authority and reached into a
sibling app via `context: ../tablet-ordering-pwa`, which only resolved when
compose ran from `woosoo-nexus/` — ambiguous "where do I run docker compose".
Tablet UI changes were hard to reflect (no dev bind-mount; installed kiosk
PWAs never auto-updated). Platform branch sprawl made state hard to follow.

## Contrarian Review
- Discovered it is NOT a monorepo: 3 independent git repos (platform =
  governance/orchestration only; woosoo-nexus; tablet-ordering-pwa). Original
  monorepo-merge plan was invalidated; corrected to compose-only-in-platform +
  per-repo-pull deploy scripts.
- Flagged volume-deletion blast radius before the from-scratch rebuild;
  preserved Pi volume identity via pinned `name: woosoo-nexus`.
- Separated tablet PWA staleness (app code, separate repo) from infra.
- Branch consolidation: verified zero divergence before any destructive step;
  surfaced the `staging` vs `staging/orchestration-hooks` git D/F constraint.

## Investigation
See plan `C:\Users\Pc1\.claude\plans\review-docker-setup-check-immutable-rose.md`.
Branch audit: all platform branches were one linear chain; `agent/infra` tip
`baed1c2` contained everything; `claude/determined-galileo` byte-identical;
`claude/exciting-elbakyan` a strict ancestor; both were clean git worktrees.

## Root Cause
Orchestration authority physically located inside one app repo with a
CWD-dependent sibling build context; PWA service worker precache-bound the app
shell with manual-only skip-waiting; build-version backstop endpoint absent
from the static build.

## Proposed Fix
Platform repo (committed `6924512`, `a3222b5`, `baed1c2` + `baed1c2`+doc):
root `compose.yaml` (contexts `./woosoo-nexus`, `./tablet-ordering-pwa`,
`name: woosoo-nexus` pinned, mysql not host-published, no override files),
shared `docker/`, 9 deploy scripts (deploy.sh + apply-woosoo-config.sh
rewritten for platform-root + per-repo pull), profile-gated `tablet-pwa-dev`,
removed tablet-pwa `env_file` secret leak, canonical
`docs/deployment/production-docker.md`.
woosoo-nexus (`chore/nexus/remove-bi-stack` `eca0897`): unused BI/ETL stack
removed. tablet-ordering-pwa (`fix/tablet/pwa-auto-update` `dc2ccfd`):
network-first navigation, order-safe auto-apply, prerendered `/build-info.json`
backstop, `no-store` cache rule.
Consolidation: platform branches → single flat `staging`.

## Files Changed
Platform `staging` over `9a4e220`: `compose.yaml`, `docker/**`,
`docs/README.md`, `docs/deployment/**`, `scripts/deployment/**` (19 files,
+2237/-1) + this case file. (woosoo-nexus / tablet changes are in their own
repos/branches — not pushed; platform-only scope.)

## Verification
Done: `docker compose config` equivalent to pre-move baseline; from-scratch
`--no-cache` build PASS; clean `up -d` PASS (single project, all services
healthy, 443/4443/80 → 200); tablet `npm run generate` + typecheck + eslint +
vitest 352/352 PASS.
Pending (this case closure): `git log -1 origin/staging` == `baed1c2`;
`git branch -a` shows single `staging`, no `staging/orchestration-hooks`
local/remote, `claude/*`+`agent/infra` gone, only main worktree;
`git diff --stat 9a4e220..origin/staging` = the 19 audited files + case file;
`docker compose --env-file ./woosoo-nexus/.env -f compose.yaml config` valid.

## Executioner Verdict
Pending verification (see above). Do not mark COMPLETE until all Pending
checks pass.

## Remaining Risks
Deferred (Pi access required): full Pi deploy-cycle verification; rework of the
7 non-core deploy scripts; Group-B physical removal of legacy nexus
orchestration files + nexus-internal doc rewrite (retained as Pi rollback
path); on-device tablet PWA propagation timing; untouched uncommitted
`woosoo-nexus/compose.yaml` mysql-publish WIP (discard at user discretion).
