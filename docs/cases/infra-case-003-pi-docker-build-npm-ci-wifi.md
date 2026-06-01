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
- status: IN_PROGRESS
- last_completed_agent: none
- next_agent: contrarian
- active_runner: none
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-30

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
<!-- pending -->

## Investigation
<!-- pending -->

## Root Cause
<!-- pending -->

## Proposed Fix
<!-- pending — candidates: npm config set fetch-retries/fetch-retry-maxtimeout; build off-Pi +
     ship image; or local npm cache/registry mirror on the Pi. -->

## Files Changed
<!-- pending -->

## Verification
<!-- pending — clean `docker compose up -d --build` on the Pi completes without ECONNRESET. -->

## Executioner Verdict
<!-- pending -->

## Remaining Risks
<!-- pending -->
