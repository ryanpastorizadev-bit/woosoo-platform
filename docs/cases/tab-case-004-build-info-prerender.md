---
status: canonical
last_reviewed: 2026-05-19
scope: tablet-ordering-pwa
---

# CASE: tab-case-004-build-info-prerender

## Run State
- task_slug: tab-case-004-build-info-prerender
- tier: 2
- branch: agent/tab-case-004-build-info-prerender
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: claude-code
- interrupted: false
- interrupt_reason: none
- updated: 2026-05-19

## Handoff
- Phase in progress: none
- Done so far: All phases complete. Two-file fix applied; verified by static analysis.
- Exact next action: Rebuild Docker image for tablet-pwa and re-run smoke check: `curl -k -I https://localhost:4443/build-info.json` must return `200 application/json` with `Cache-Control: no-store`.
- Working-tree state: `tablet-ordering-pwa/nuxt.config.ts`, `tablet-ordering-pwa/docker/nginx/tablet-pwa.conf`
- Risks / do-not-redo: Do not add `build-info.json` to the service worker precache — it is explicitly in `globIgnores` and must always be fetched fresh.

## Tier
2

## Branch
agent/tab-case-004-build-info-prerender (tablet-ordering-pwa repo)

## Problem

`/build-info.json` is the PWA update backstop: the service worker and `useAppUpdate` composable
fetch it on each load to compare the deployed build SHA against the currently loaded shell and
trigger a guarded reload when they diverge. Live smoke check returned `200 text/html` with
`Cache-Control: public, max-age=60` — the SPA shell — meaning the file does not exist in the
static output and Nginx falls through to `index.html` under the `location /` catch-all.

## Contrarian Review

Tier 2. No auth, no state machine, no POS writes. Two isolated files: config prerender list
and Nginx location block. Independent of tab-case-001/002/003 working trees.

Already verified: `globIgnores` in `nuxt.config.ts` correctly excludes `build-info.json` from
service worker precaching — no change needed there.

Acceptable trade-off: the prerendered file's `apiBaseUrl` and `reverb.*` fields will reflect
build-time defaults, not runtime values. This is intentional — `runtime-config.js` / `window.__APP_CONFIG__`
is the authoritative runtime config source. `build-info.json` is build identity only
(`buildSha`, `buildBranch`, `buildTime`, `appVersion`), and those ARE correct because
`Dockerfile.prod` passes them as `ARG`→`ENV` before `nuxi generate` runs.

## Investigation

- `nuxt.config.ts:113-117` — `nitro.prerender.routes` contains only `["/"]`. `nuxi generate`
  never executes `server/routes/build-info.json.get.ts`, so no static file is produced.
- `Dockerfile.prod:31` — `COPY --from=builder /app/.output/public` copies only the pre-generated
  static tree into Nginx. The Nitro server is not included; server routes only materialise if
  prerendered.
- `docker/nginx/tablet-pwa.conf:12-18` — `location /` serves `index.html` as fallback with
  `Cache-Control: public, max-age=60`. A request for the missing `/build-info.json` hits this
  block, explaining both the `200 text/html` response and the wrong cache header.
- `server/routes/build-info.json.get.ts` — sets `no-store` headers via `setResponseHeader`, but
  these only apply at Nitro runtime; they have no effect on a prerendered static file served by
  Nginx.

## Root Cause

`/build-info.json` is absent from `nitro.prerender.routes`, so `nuxi generate` never produces the
file. Nginx has no matching location block, so the catch-all returns the SPA shell with a
60-second cache header instead.

## Proposed Fix

1. `nuxt.config.ts` — add `"/build-info.json"` to `nitro.prerender.routes` so the route handler
   runs at generate time and writes the file to `.output/public/build-info.json`.
2. `docker/nginx/tablet-pwa.conf` — add `location = /build-info.json` with `no-store` cache
   headers before the `location = /runtime-config.js` block, mirroring the existing pattern.

## Files Changed

- `tablet-ordering-pwa/nuxt.config.ts` — `routes: ["/"]` → `routes: ["/", "/build-info.json"]`
- `tablet-ordering-pwa/docker/nginx/tablet-pwa.conf` — added `location = /build-info.json` block

## Verification

Static analysis only (no rebuild performed — Docker image is 28 h old and would require a full
`docker compose build tablet-pwa`):

- `nuxt.config.ts` diff is minimal: one string added to the prerender array.
- Nginx location block matches the existing `runtime-config.js` pattern exactly.
- `globIgnores` for `build-info.json` in `injectManifest` is unchanged — file will still be
  excluded from SW precache.
- Build args `BUILD_SHA`, `BUILD_BRANCH`, `BUILD_TIME`, `APP_VERSION` are passed as `ARG`→`ENV`
  in `Dockerfile.prod` before `nuxi generate`, so identity fields will be correct at generate time.

Required post-merge validation:
```text
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml build tablet-pwa
docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d tablet-pwa
curl -k -I https://localhost:4443/build-info.json
# expect: 200, Content-Type: application/json, Cache-Control: no-store
curl -k https://localhost:4443/build-info.json | jq .
# expect: buildSha != "unknown", not text/html
```

## Executioner Verdict

APPROVED — root cause is confirmed by static analysis of three files. Fix is minimal (one
prerender route entry, one Nginx location block). No contract changes, no auth touch, no state
machine impact. Post-merge Docker rebuild required to confirm at runtime.

## Remaining Risks

- P2 Docker network naming drift (`woosoo-nexus_woosoo` vs `woosoo-network`) — tracked separately.
- P2 Seven NOT-migrated deployment scripts — tracked separately; requires Pi access.
- P2 Uncommitted MySQL `3306:3306` publish in `woosoo-nexus/compose.yaml` — investigate and
  discard if not intentional.
