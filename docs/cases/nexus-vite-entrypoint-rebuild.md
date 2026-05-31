---
status: canonical
last_reviewed: 2026-05-30
scope: woosoo-nexus
---

# CASE: nexus-vite-entrypoint-rebuild

## Run State
- task_slug: nexus-vite-entrypoint-rebuild
- tier: 3
- branch: dev
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-30

## Handoff
- Phase in progress:
- Done so far:
- Exact next action:
- Working-tree state (list edited files explicitly; cross-check with `git status`):
- Risks / do-not-redo:

## Tier
3

## Branch
dev

## Problem
PR comment on `woosoo-nexus/docker/docker-entrypoint.sh`: the current entrypoint skips `npm run build` when `public/build` is already present unless `WOOSOO_FORCE_VITE_BUILD=true`. Normal deploy paths can update bind-mounted source files while leaving an old Vite manifest in place.

## Contrarian Review

### Tier
3

### Assumptions Challenged
- The PR comment is only partially current at the platform root: `scripts/deployment/deploy.sh` now performs a forced one-off frontend build before `up -d`.
- The comment is still correct for the nested Nexus deploy paths: `woosoo-nexus/scripts/deployment/update-client.sh`, `rollback-client.sh`, and `apply-woosoo-config.sh` rebuild/start services without setting `WOOSOO_FORCE_VITE_BUILD`.
- A fix that only changes deploy scripts would miss direct `docker compose up -d --build` and manual restarts after source updates.

### Risks
- Production deployment risk: stale `public/build/manifest.json` can serve old JS/CSS after PHP, Blade, or frontend source changes.
- Reverting to unconditional builds on every `php-fpm` start would fix freshness but make crash/OOM/reboot recovery slow again.
- Build failures are currently warning-only in the entrypoint; if stale assets exist and a rebuild fails, the container can still start with old assets.

### Hidden Failure Boundaries
- Bind mounts mean the host `public/build` wins over image contents.
- `public/build` being non-empty is not proof that it matches the checked-out source tree.
- Vite source/config freshness must include `resources/views` because Blade can introduce or change `@vite` entry references.

### Assigned Specialist
- infra

### Affected App
- woosoo-nexus

### Candidate Skills
- agent-sequence
- docker-deployment-debug
- test-verification
- dead-code-cleanup

### Branch
dev

### Recommendation
Proceed: patch the entrypoint to rebuild when the manifest is missing or older than Vite-relevant source/config files, preserving fast restarts when assets are current.

## Investigation
- Verified the PR comment against current source before patching.
- `woosoo-nexus/docker/docker-entrypoint.sh` skipped Vite builds whenever `public/build` was non-empty unless `WOOSOO_FORCE_VITE_BUILD=true`.
- `woosoo-nexus/compose.yaml` bind-mounts the repo into `/var/www/html`, so host `public/build` wins over image contents.
- Nested Nexus deploy paths still restart/rebuild without the force flag:
  - `woosoo-nexus/scripts/deployment/update-client.sh`
  - `woosoo-nexus/scripts/deployment/rollback-client.sh`
  - `woosoo-nexus/scripts/deployment/apply-woosoo-config.sh`
- Platform-root `scripts/deployment/deploy.sh` already performs a forced one-off Vite build, so that part of the comment is stale for the platform-root deploy path.
- Pre-existing unrelated dirty files in `woosoo-nexus` before this task:
  - `handoff/step-1/AppSidebarHeader.vue`
  - `handoff/step-2/AppSidebarHeader.vue`
  - `resources/views/manual/user.blade.php`
  - `handoff/IMPLEMENTATION_HANDOVER.md`

## Root Cause
The entrypoint treated a non-empty `public/build` directory as current. In bind-mounted deployments, that only proves an old build exists; it does not prove `public/build/manifest.json` matches the current checked-out frontend/Blade/config sources.

## Proposed Fix
Keep fast restarts, but rebuild when assets are stale:
- Continue rebuilding when `WOOSOO_FORCE_VITE_BUILD=true`.
- Rebuild when `public/build` is missing or empty.
- Rebuild when `public/build/manifest.json` is missing.
- Rebuild when Vite-relevant source/config paths are newer than the manifest:
  - `package.json`
  - `package-lock.json`
  - `vite.config.*`
  - `tailwind.config.*`
  - `postcss.config.*`
  - `tsconfig.json`
  - `resources/js`
  - `resources/css`
  - `resources/views`

## Files Changed
- `woosoo-nexus/docker/docker-entrypoint.sh`
- `docs/cases/nexus-vite-entrypoint-rebuild.md`

## Verification
## Verification Report

### Commands Run
- `C:\Program Files\Git\usr\bin\sh.exe -n docker/docker-entrypoint.sh`
- `npm.cmd run build`
- `C:\Program Files\Git\usr\bin\sh.exe -c '<freshness predicate>'`
- `.\scripts\pre-merge-check.ps1 -App woosoo-nexus`
- `php artisan test --compact`

### Results
- Shell syntax check: passed with exit code 0.
- Vite build: `✓ built in 5.25s`
- Freshness predicate after build: `current`
- Pre-merge script: `pre-merge-check OK (woosoo-nexus)`
- Full unfiltered test suite:

```txt
Tests:    432 passed (1512 assertions)
Duration: 140.80s
```

### Warnings / Suspicious Output
- Existing PHPUnit deprecation warnings remain: `Metadata found in doc-comment ... is deprecated and will no longer be supported in PHPUnit 12. Update your test code to use attributes instead.`
- Initial `php artisan test --compact --without-tty` retry failed because `--without-tty` is not a Laravel test option; reran without it successfully.
- `bash -n docker/docker-entrypoint.sh` through WSL failed because `/bin/bash` was unavailable; reran with Git Bash `sh.exe` successfully.

### Functional Proof
- The changed predicate reports `current` immediately after a successful Vite build, preserving the fast restart path.
- The entrypoint will now rebuild on php-fpm start if the manifest is absent or older than Vite-relevant source/config files, covering bind-mounted deploys that update source while leaving a non-empty old `public/build`.

### Verdict
PASS

## Executioner Verdict
Verdict: APPROVED

### Reason
The PR comment was verified against current deploy paths before patching. The fix is scoped to the Nexus Docker entrypoint plus the required case file, preserves fast restarts when assets are current, and closes the stale-manifest path for bind-mounted deploys. Required validation passed.

### Required Next Action
Stage only `woosoo-nexus/docker/docker-entrypoint.sh` and `docs/cases/nexus-vite-entrypoint-rebuild.md`; do not include the pre-existing dirty Nexus handoff/manual files or root untracked document/cert files.

### Follow-Ups
- Separate cleanup: migrate PHPUnit doc-comment metadata to attributes before PHPUnit 12.

## Remaining Risks
- `npm run build` failure remains warning-only in the entrypoint, matching the existing behavior. If production policy should fail closed when stale assets cannot be rebuilt, handle that as a separate deploy policy decision.
- The workspace still contains unrelated pre-existing dirty/untracked files; they were not modified for this task and must not be staged with this fix.

## Agent Chain
- Tier: 3
- Branch: dev
- Contrarian: APPROVED proceed after verifying the PR comment; assigned infra; one app only.
- Specialist: Patched `woosoo-nexus/docker/docker-entrypoint.sh` to rebuild when manifest/assets are stale instead of only missing.
- Verifier: PASS; syntax/build/freshness/full tests/pre-merge all passed with warnings noted.
- Executioner: APPROVED
