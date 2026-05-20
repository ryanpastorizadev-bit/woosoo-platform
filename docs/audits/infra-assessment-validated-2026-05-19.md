---
status: canonical
last_reviewed: 2026-05-19
scope: platform-infra
---

# Infrastructure Assessment — Validated 2026-05-19

Validation method: two Explore agents read `compose.yaml`, both `.dockerignore` files, all
four Dockerfiles, and `scripts/deployment/README.md` and returned line-level evidence for every
claim. Runtime state confirmed by `docker compose ps/images` and `/build-info.json` header.

---

## Confirmed Accurate

- **3-repo sibling model** — platform orchestration (governance-only), `woosoo-nexus` (Laravel),
  `tablet-ordering-pwa` (Nuxt PWA). Compose stack runs 8 services: `nginx`, `app`, `queue`,
  `scheduler`, `reverb`, `mysql`, `redis`, `tablet-pwa`.
- **Hot-deploy / bind-mount risk** — `./woosoo-nexus:/var/www/html` is bind-mounted in **four**
  Laravel services (`app` line 86, `queue` line 118, `scheduler` line 143, `reverb` line 166).
  compose.yaml lines 26–28 explicitly note: remove for fully immutable production.
- **Image traceability** — no image names are declared in compose.yaml; all five built services
  use `pull_policy: build` and receive auto-generated tags in `{project}_{service}:latest` form
  (e.g. `woosoo-nexus_app`, `woosoo-nexus_queue`). No semantic versioning or digest pinning.
- **Health checks** — present for `app` (lines 94–99), `mysql` (lines 300–305), and `redis`
  (lines 318–322). **Absent for `queue`, `scheduler`, `reverb`, and `tablet-pwa`** — four
  services without process-specific health checks (see correction below).
- **Resource limits** — `app`, `queue`, `scheduler`, `mysql`, `redis` all have `mem_limit` +
  `mem_reservation`. `nginx`, `reverb`, and `tablet-pwa` have no limits.
- **No compose logging driver** — no `logging:` block at service or top level. Ops relies on
  `docker compose logs` and Laravel log channels.
- **Secrets** — plain `.env` based, resolved from root-owned `/etc/woosoo/woosoo.env`. Not
  Docker secrets or vault. Secrets are not committed; `.dockerignore` and `.gitignore` exclude
  all `.env*` files.
- **Redis persistence** — runs with `--appendonly yes` on a named volume. No
  backup/restore story in `woosoo-backup.sh` (explicitly marked NOT migrated).
- **Seven NOT-migrated deployment scripts** — `scripts/deployment/README.md` lines 14–20:
  `deploy-tablet.sh`, `verify-tablet-deploy-context.sh`, `update-client.sh`,
  `rollback-client.sh`, `verify-client.sh`, `woosoo-backup.sh`, `woosoo-health.sh`.
- **Docker network** — live name is `woosoo-nexus_woosoo` (compose project `woosoo-nexus` +
  network key `woosoo`), not `woosoo-network`.

---

## Partly Correct

- **Laravel image duplication** — four Laravel service images (`app`, `queue`, `scheduler`,
  `reverb`) all build from the same `woosoo-nexus/` context and resolve to the same base layers.
  Docker can share layers so "4x disk size" is overstated, but the naming/tag sprawl is real and
  the lack of a shared pre-built base image means four separate build contexts on cold Pi builds.
- **Pi memory pressure** — resource limits are set for the five most expensive services; nginx,
  reverb, and tablet-pwa are unconstrained. On a Raspberry Pi this is a plausible OOM risk,
  particularly for reverb under websocket load.

---

## Incorrect / Stale (prior assessment errors)

- **`.dockerignore` missing** — FALSE. Both `woosoo-nexus/.dockerignore` and
  `tablet-ordering-pwa/.dockerignore` exist and comprehensively exclude `.git`, dependencies,
  `.env*`, test outputs, and logs.
- **`npm ci` runs on every compose up with no cache** — OVERSTATED. All Dockerfiles copy
  manifest files (`package*.json`, `composer.json`/`composer.lock`, `requirements.txt`) before
  the dependency-install step, enabling Docker to cache the dependency layer independently of
  source changes. Cold Pi builds are still expensive; warm rebuilds are not.

---

## Correction Applied vs. Prior Assessment

One material error was present in the earlier "Accurate" section:

> "Health checks exist for `app`, `mysql`, `redis`, and `tablet-pwa`"

`tablet-pwa` has **no `healthcheck:` block** (compose.yaml lines 178–227). The guardrail gap
covers four services, not three: `queue`, `scheduler`, `reverb`, and `tablet-pwa`.

---

## Open Action Items

| # | Item | Priority |
|---|------|----------|
| 1 | Add `tablet-pwa` health check (e.g. `curl -f http://localhost:3000/build-info.json`) | Medium |
| 2 | Add health/process check for `reverb` | Low |
| 3 | Migrate 7 NOT-migrated deployment scripts | High |
| 4 | Add `mem_limit` to `nginx`, `reverb`, `tablet-pwa` | Low |
| 5 | Pin image tags (digest or semver) for traceability | Medium |
| 6 | Establish `woosoo-backup.sh` migrate path for Redis AOF backup | High |
| 7 | Remove bind-mounts from all 4 Laravel services for production image | High |
