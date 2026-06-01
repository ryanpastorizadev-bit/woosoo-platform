---
status: canonical
last_reviewed: 2026-05-30
scope: woosoo-platform
---

# CASE: infra-case-003-pi-docker-build-npm-ci-wifi

`docker compose up -d --build` from `/opt/woosoo/woosoo-platform/` fails consistently on the
Raspberry Pi production unit because `npm ci` inside the Docker build containers loses the WiFi
connection mid-download (ECONNRESET / ETIMEDOUT). Blocks restaurant deploy.
(GitHub Issue: tech-artificer/woosoo-nexus #136 — bug, deployment, docker.)

## Run State
- task_slug: infra-case-003-pi-docker-build-npm-ci-wifi
- tier: 2
- branch: agent/infra-case-003-pi-docker-build-npm-ci-wifi
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: none
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-01

## Handoff
- Phase in progress: triage only — registered from GH #136 during Phase 0 reconciliation
- Done so far: case stub created; classified infra/deploy-gate (not a code-merge gate)
- Exact next action: Contrarian/infra — decide approach: (a) make `npm ci` resilient (retry +
  longer network-timeout / fetch-retries in Docker build) or (b) build images off-Pi and ship
  the prebuilt image to the Pi (ties to NEX-CASE-010 immutable-image direction).
  ⚠️ **Coordinate with NEX-CASE-010 before choosing (b)** — off-Pi prebuilt images overlap that
  case's immutable-image migration; (b) without coordination risks two divergent solutions.
  Approach (a) is independent and can ship without NEX-010.
- Working-tree state: none yet
- Risks / do-not-redo: eth0 is restricted restaurant LAN with no outbound internet; only wlan0
  (PLDT WiFi) has egress — do not assume eth0 connectivity during build.

## Tier
2

## Branch
agent/infra-case-003-pi-docker-build-npm-ci-wifi

## Problem
Pi build of `woosoo-nexus` (Laravel/PHP) and `tablet-ordering-pwa` (Nuxt 3) fails: `npm ci`
drops the wlan0 WiFi connection mid-download. Two separate attempts both failed. This is a
DEPLOY-gate for the restaurant rollout, not a code-merge gate for dev→staging→main.

## Contrarian Review
Tier 2 confirmed. Approach (a) selected — `.npmrc` retry/timeout hardening; independent of
NEX-CASE-010. Approach (b) remains blocked on NEX-CASE-010 coordination per the handoff note.
Cross-repo flag: changes span `woosoo-nexus` and `tablet-ordering-pwa` sibling repos; treated
as a single symmetric infra fix (no logic, no contracts); Executioner retains SPLIT_REQUIRED right.
Risks: trivially low (additive config; no code path changed; neither .dockerignore excludes .npmrc).

## Investigation
All four Dockerfiles run bare `npm ci` with npm defaults: fetch-retries=3, fetch-timeout=120s.
No `.npmrc` exists anywhere in either app repo. No retry logic in deploy.sh for the build step.
Neither `.dockerignore` excludes `.npmrc`. `woosoo-nexus/Dockerfile` uses `COPY . .` before
`npm ci` — .npmrc is picked up automatically. The three tablet Dockerfiles use `COPY package*.json ./`
before `npm ci` — they require an explicit `.npmrc` in that COPY line.

## Root Cause
npm's default network settings (3 retries, 120s timeout) are insufficient for a Raspberry Pi
on WiFi (wlan0) where ECONNRESET/ETIMEDOUT occurs mid-download due to transient connection drops.
No resilience layer exists at the Dockerfile or deploy-script level.

## Proposed Fix
Approach (a): `.npmrc` in each app root with retry/timeout values tuned for ARM WiFi:
```
fetch-retries=5
fetch-retry-mintimeout=15000   # 15s — gives WiFi time to reconnect after a drop
fetch-retry-maxtimeout=120000  # 120s per retry
fetch-timeout=600000           # 10min total — handles slow ARM64 downloads
```
Tablet Dockerfiles updated to include `.npmrc` in the pre-`npm ci` COPY layer.
Nexus Dockerfile unchanged — `.npmrc` is already included via `COPY . .`.

## Files Changed
- `tablet-ordering-pwa/.npmrc` — new (fetch-retries=5, timeouts hardened)
- `tablet-ordering-pwa/Dockerfile` — COPY line adds `.npmrc`
- `tablet-ordering-pwa/Dockerfile.dev` — COPY line adds `.npmrc`
- `tablet-ordering-pwa/Dockerfile.prod` — COPY line adds `.npmrc`
- `woosoo-nexus/.npmrc` — new (same config; no Dockerfile change needed)
Commits: tablet-ordering-pwa `3fbba11`; woosoo-nexus `27fa499`
Branch: `agent/infra-case-003-pi-docker-build-npm-ci-wifi` in both sibling repos

## Verification
Local (dev box, Docker 29.4.3):
- `docker build -f Dockerfile.dev -t woosoo-infra-003-verify .` → exit 0 (64s, npm ci clean)
- `docker run --rm woosoo-infra-003-verify sh -c "cat /app/.npmrc && npm config get fetch-retries && npm config get fetch-timeout"`
  Output: fetch-retries=5, fetch-timeout=600000 ✅

Pi (pending — required for final proof):
- `docker compose up -d --build` must complete without ECONNRESET on wlan0.
- This is the production gate; local verification confirms no regression on stable network.

## Executioner Verdict
APPROVED — 2026-06-01. Tier 2 chain complete, artifacts verified, cross-repo symmetric infra
touch accepted (no logic/contract blast radius). Pi wlan0 hardware test is deploy-gate (Bucket B),
not merge-gate.

Follow-ups (non-blocking):
- If ECONNRESET persists on Pi despite retries, escalate to approach (b) coordinated with NEX-CASE-010.
- Mirror .npmrc pattern to woosoo-print-bridge if it ever gains npm install steps.

## Remaining Risks
<!-- pending -->
