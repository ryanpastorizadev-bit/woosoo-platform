---
status: canonical
last_reviewed: 2026-05-27
scope: platform
---

# Woosoo Platform — Business Requirements Document Supplement

## Overview

This document supplements the Woosoo Nexus Business Requirements Document (tech-artificer/woosoo-nexus PR #138). The Nexus BRD covers three functional repositories (Nexus API, Tablet PWA, Print Bridge) and their direct capabilities. This supplement documents the **woosoo-platform** repository as the fourth system component — the governance, orchestration, and contract authority layer that holds the entire system together.

**woosoo-platform is not a user-facing application.** It is the deployment and governance framework that enables the three app repositories to function as a unified system.

---

## 1. Executive Summary

The woosoo-platform repository provides three essential layers:

1. **Deployment Orchestration** — Docker Compose stack that coordinates six services (Nginx, Laravel app, queue worker, scheduler, Reverb WebSocket, MySQL, Redis) across three on-premises deployment targets (development, staging, production Pi).

2. **Cross-App Contracts & API Governance** — Five canonical contract files that define the enforced integration boundaries between Nexus, Tablet PWA, and Print Bridge. These contracts are the source of truth for any code change affecting inter-app surfaces.

3. **AI Agent Operating System** — A vendor-neutral, 4-agent workflow (Contrarian → Specialist → Verifier → Executioner) that serves as the governance engine for all changes across all three apps. Consumed by Claude Code (this platform's default AI agent), OpenAI Codex CLI, and GitHub Copilot.

4. **Documentation Authority & Developer Governance** — The canonical documentation index, per-task case file system for cross-runner resume/handoff, and automated pre-merge validation gates that ensure all code changes maintain system safety and contract compliance.

---

## 2. System Architecture Overview

Woosoo is a **3-repository sibling model**, NOT a monorepo. Each app is independently versioned and deployed.

| Component | Repository | Role | Owner |
|-----------|-----------|------|-------|
| **woosoo-nexus** | `tech-artificer/woosoo-nexus` | Laravel 12 backend: admin UI, API, POS integration, Reverb broadcasting, print event orchestration | ranpo-backend specialist |
| **Tablet Ordering PWA** | `tech-artificer/tablet-ordering-pwa` | Nuxt 3 SPA/PWA: customer-facing ordering, session recovery, Echo/Reverb client | chuya-frontend specialist |
| **Print Bridge** | `woosoo-print-bridge/` | Flutter Android relay: WebSocket/polling intake, Bluetooth printer dispatch, ACK lifecycle | relay-ops specialist |
| **woosoo-platform** | `ryanpastorizadev-bit/woosoo-platform` | Docker orchestration, cross-app contracts, AI agent OS, documentation authority, pre-merge gates | infra specialist / dazai-docs specialist |

### Deployment Topology

All Docker operations run from the platform repository root. The orchestration authority is **platform-root-only**:

```
woosoo-platform/          ← Platform root (governance + orchestration)
├── compose.yaml          ← Single source of truth for all services
├── docker/
│   ├── nginx/            ← Nginx reverse proxy config (port 80, 443, 4443)
│   ├── certs/            ← TLS certificate material (gitignored)
│   └── php/              ← PHP runtime config
├── scripts/deployment/   ← Deploy scripts for Pi and staging
├── contracts/            ← 5 cross-app contract files
├── hooks/                ← 9 workflow hooks (work, status, intake, triage, etc.)
├── .claude/agents/       ← Agent definitions (Contrarian, Specialist roles, Verifier, Executioner)
├── .claude/skills/       ← Task playbooks (test-verification, laravel-api-change, etc.)
├── state/                ← Machine-readable orchestration state
├── docs/
│   ├── AI_CONTEXT.md           ← Business and architecture context
│   ├── README.md               ← Canonical documentation index
│   ├── deployment/             ← Deployment strategy docs
│   ├── cases/                  ← Per-task case files (durable resume state)
│   └── audits/                 ← System audit trail
└── woosoo-nexus/, tablet-ordering-pwa/  ← Sibling app repos (pulled in place by deploy.sh)
```

### Service Orchestration (compose.yaml)

The Docker Compose stack runs 8 services on all platforms (dev, staging, production):

| Service | Image | Port | Role | Notes |
|---------|-------|------|------|-------|
| **nginx** | nginx:1.25-alpine | 80, 443, 4443 | Reverse proxy + TLS termination | Routes admin (443), tablet PWA (4443), static assets (/images, /storage, /build) |
| **app** | Laravel (PHP-FPM 8.2) | 9000 | API + admin UI | Healthcheck every 15s; mem limit 768MB |
| **queue** | Laravel (PHP CLI) | internal | Queue worker | `queue:work redis`; processes jobs from Redis queue |
| **scheduler** | Laravel (PHP CLI) | internal | Task scheduler | `schedule:work`; runs scheduled jobs (e.g., POS polling, session cleanup) |
| **reverb** | Laravel (PHP CLI) | 8080 | WebSocket server | `reverb:start`; tablet + bridge connect via TLS at port 443 (Nginx proxy) |
| **tablet-pwa** | Nuxt 3 (Node) | 3000 | Static PWA server | Built from sibling `tablet-ordering-pwa` repo; served over port 4443 |
| **mysql** | MySQL 8.0 | internal | Relational database | NOT published to host; internal network only |
| **redis** | Redis 7 | internal | Cache + queue broker | NOT published to host; internal network only |

**Network:** All services communicate over the internal `woosoo` Docker network. MySQL and Redis are not exposed to the host.

**Healthchecks:** app and mysql have service-level healthchecks; subsequent services depend on their health before starting.

**Deployment model:** Currently HOT-DEPLOY (bind-mount active). The compose file includes inline documentation for switching to IMMUTABLE-IMAGE (recommended for locked production releases).

---

## 3. Business Capabilities of the Platform

### 3.1 Deployment Orchestration

**What it does:**
- Manages a unified Docker Compose stack that orchestrates Nexus, Tablet PWA, Reverb, MySQL, Redis, and queue/scheduler workers.
- Runs from the platform-root only: `docker compose --env-file ./woosoo-nexus/.env up -d --build`.
- Provides port-based routing:
  - Port **80** — HTTP redirect to HTTPS
  - Port **443** — Woosoo admin panel, Reverb WebSocket, API (`/app/*` routes to Reverb)
  - Port **4443** — Tablet PWA (serves `/images`, `/storage`, `/build` static assets from Laravel public directory)

**Where it lives:**
- `compose.yaml` — canonical service definitions
- `docker/nginx/default.conf` — Nginx multi-port routing configuration
- `docker/php/local.ini` — PHP runtime settings
- `docker/certs/` — TLS certificates (gitignored; host-provided)
- `scripts/deployment/deploy.sh` — production deployment script (pulls app repos, builds, starts)
- `docs/deployment/production-docker.md` — canonical Docker reference

**Why it matters:**
In a distributed 3-repo setup, a single orchestration point ensures consistent configuration across dev, staging, and production. All three apps share the same MySQL, Redis, and Reverb instances; a misconfigured compose stack risks silent failures (e.g., queue workers unable to reach Redis, tablet unable to connect to Reverb).

---

### 3.2 Cross-App Contracts & Integration Governance

**What it does:**
Defines and enforces five canonical contract files that specify the legal integration boundaries between Nexus, Tablet PWA, and Print Bridge. Every code change that touches an inter-app surface must verify compliance against the relevant contract before merge.

**The five contracts:**

| Contract | Surface | Enforced in | Canonical Truth |
|----------|---------|-------------|-----------------|
| **order-state.contract.md** | Order lifecycle state machine | Code review (all three apps) | States: `confirmed → completed \| voided \| cancelled`. No additional states. |
| **tablet-api.contract.md** | Tablet intent payload (POST /api/devices/create-order) | Nexus API, Tablet PWA form submission | Tablet sends **intent only**: `{ guest_count, package_id, items: [{ menu_id, quantity }] }`. Nexus computes pricing, modifiers, POS mapping. |
| **printer-relay.contract.md** | Print event idempotency (reserve/ack/failed) | Print Bridge intake, Nexus broadcast | Print jobs must be idempotent at reserve/ack lifecycle. Bridge ACKs only once per job. |
| **pos-db.contract.md** | POS database access safety | Nexus routes, POS sync command | Only designated endpoints write to POS DB (via Krypton driver). Static LAN IP: 192.168.1.32. |
| **auth-session.contract.md** | Device auth + session boundaries | Nexus controllers, Tablet client, Sanctum middleware | Device token lifecycle, session duration, reset triggers. Tablet cannot initiate session; must register and receive token first. |

**Where they live:**
- `contracts/*.md` — five contract files in the platform root

**Why they matter:**
The three app repos are independently versioned and deployed. A contract violation (e.g., tablet sending pricing data, or Print Bridge ACKing twice) can silently corrupt the system state without runtime errors. Contracts are the only mechanism to catch such violations before production.

---

### 3.3 AI Agent Operating System

**What it does:**
Provides a vendor-neutral 4-agent workflow that governs all code changes across all three apps and the platform itself. The workflow is designed to survive interruption (rate limits, context limits, runner crash) and resume from a durable checkpoint (per-task case file).

**The 4-agent sequence:**

```
1. Contrarian   ← Challenges the request, classifies risk/tier, decides path
2. Specialist   ← Implements (ranpo-backend | chuya-frontend | relay-ops | dazai-docs | infra)
3. Verifier     ← Runs tests, lint, build, and validates contract compliance
4. Executioner  ← Final verdict gate (APPROVED | REJECTED | SPLIT_REQUIRED)
```

**Agent roles by specialist domain:**

| Domain | Specialist | Allowed Scope | Model |
|--------|----------|---|-------|
| Backend/API/Auth/POS | ranpo-backend | `woosoo-nexus/**` | sonnet |
| Frontend/Nuxt/UI | chuya-frontend | `tablet-ordering-pwa/**` | sonnet |
| Printer relay/hardware | relay-ops | `woosoo-print-bridge/**` | sonnet |
| Docs/specs/governance | dazai-docs | `docs/**`, `*.md` | haiku |
| Docker/Nginx/deployment | infra | `docker/**`, `nginx/**`, `scripts/**`, `compose.yaml` | sonnet |

**Triage tiers:**

| Tier | Examples | Sequence | Notes |
|------|----------|----------|-------|
| **1 — Trivial** | Typo, single-line config, README link | Specialist → Executioner | No Verifier if no code path changed |
| **2 — Standard** | Bug fix in one app, new endpoint, UI component, doc rewrite | Contrarian → Specialist → Verifier → Executioner | Default |
| **3 — High-risk** | Auth, POS DB writes, order state machine, payment lifecycle, race conditions, queue/retry, production deploy | Contrarian (deep, written risk analysis) → Specialist → Verifier → Executioner | Executioner uses opus |

**Runners (vendors):**
- **Claude Code** (default for this platform) — executes via `.claude/agents/*` (agent definitions) and `.claude/skills/*` (task playbooks)
- **OpenAI Codex CLI** — reads `AGENTS.md` natively and follows the same sequence in a single chatbox
- **GitHub Copilot** — continues to follow `.github/copilot-instructions.md`

**Where it lives:**
- `AGENTS.md` — immutable operating rules and hook system (source of truth)
- `.claude/agents/*.md` — agent role definitions
- `.claude/skills/*/SKILL.md` — task playbooks (9 skills: agent-sequence, test-verification, laravel-api-change, sanctum-auth-debug, etc.)
- `hooks/*.md` — 9 installed workflow hooks

**Why it matters:**
In a 3-repo distributed system, a single workflow ensures that:
- No change to one app breaks contracts with another app
- Risky changes (auth, POS, order state) get deep scrutiny before merge
- Work interrupted by rate limits can resume from the exact same point (durable case files)
- The same process works for any AI vendor or human implementing the change

---

### 3.4 Documentation Authority & Developer Governance

**What it does:**
- Acts as the canonical documentation index for all three apps
- Maintains per-task case files (durable resume state for cross-runner handoff)
- Implements pre-merge validation gates that must pass before any code change is merged
- Tracks orchestration state in machine-readable files

**Where it lives:**

| File/Directory | Purpose |
|---|---|
| `docs/README.md` | Canonical documentation index (all three apps + platform) |
| `docs/AI_CONTEXT.md` | Business context, architecture overview, contracts table, error handling rules |
| `docs/AGENT_DEFAULT_INSTRUCTIONS.md` | Agent behavior standards, evidence requirements, test measurement, report-rejection protocol |
| `docs/RESUME_PROTOCOL.md` | Cross-runner resume & handoff protocol (case file is durable state) |
| `docs/HANDOVER_PROTOCOL.md` | Required handover before APPROVED verdict |
| `docs/cases/<task-slug>.md` | Per-task case file (durable run state, agent output, checkpoints) |
| `docs/cases/_TEMPLATE.md` | Template for creating new case files |
| `docs/deployment/production-docker.md` | Canonical Docker topology and deployment strategy |
| `docs/audits/DOCS_AUDIT_2026-05-14.md` | Full inventory of all markdown files (audit trail) |
| `docs/archive/` | Historical/superseded docs (marked `status: archived`) |
| `state/WORK.md` | Convenience cache of active case's Run State (not authoritative) |
| `state/QUEUE.md` | Priority task queue |
| `state/DEPS.md` | Cross-app dependency ledger |
| `state/DONE.md` | Append-only verified-completion log |

**Pre-merge validation gates:**
- `scripts/pre-merge-check.sh --app <app-name>` (Bash, cross-platform)
- `scripts/pre-merge-check.ps1 -App <app-name>` (PowerShell, Windows)

**Per-app validation commands:**

| App | Commands |
|-----|----------|
| woosoo-nexus | `composer test`, `php artisan route:list`, `php artisan config:clear` |
| tablet-ordering-pwa | `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build`, `npm run generate` |
| woosoo-print-bridge | `flutter analyze`, `flutter test` |

No change is approved for merge without passing its corresponding pre-merge check.

**Documentation frontmatter convention:**
Every canonical doc begins with:
```yaml
---
status: canonical | archived | under-review
last_reviewed: YYYY-MM-DD
scope: ecosystem | app-name | platform
---
```

Only docs with `status: canonical` are source of truth.

**Why it matters:**
- A distributed 3-repo system needs a single canonical reference (this platform) to avoid conflicting docs in each app repo
- Cross-runner resume capability (case files) allows work interrupted by rate limits to continue without re-triage or context loss
- Pre-merge gates prevent silent contract violations, missing tests, and configuration errors from reaching production

---

## 4. Customer Experience Workflow

**Not applicable.** The platform layer is developer-facing only. Customer experience is owned by Nexus (admin UI) and Tablet PWA. See the Nexus BRD Section 4 for customer workflows.

---

## 5. Operational Workflows

### 5.1 Development Workflow

**Local development loop:**
1. Clone woosoo-platform (this repo)
2. Clone sibling repos: `woosoo-nexus/`, `tablet-ordering-pwa/`
3. From platform root, run:
   ```bash
   docker compose --env-file ./woosoo-nexus/.env -f compose.yaml up -d --build
   ```
4. Access:
   - Admin UI: `https://woosoo.local:443`
   - Tablet PWA: `https://woosoo.local:4443`
5. For hot-reload of app code: `git pull` in `woosoo-nexus/` or `tablet-ordering-pwa/` (bind-mount active)

### 5.2 Pre-Merge Review

Every code change follows the Lite 4-agent workflow:

1. **Contrarian** — classify tier, identify risk, decide path
2. **Specialist** — implement and validate contracts
3. **Verifier** — run pre-merge checks (`scripts/pre-merge-check.sh --app <name>`)
4. **Executioner** — approve, reject, or request split

No change merges without passing `Executioner` verdict: `APPROVED`.

### 5.3 Staging & Production Deployment

**Staging** (development box):
- Re-run `docker compose up -d --build` to rebuild images from latest app code

**Production** (Pi 5):
1. From platform root, run `scripts/deployment/deploy.sh`
2. Script pulls app repos at designated branches (`WOOSOO_NEXUS_BRANCH`, `WOOSOO_TABLET_BRANCH`)
3. Runs `scripts/deployment/apply-woosoo-config.sh` to populate `.env` from `/etc/woosoo/woosoo.env`
4. Builds images, starts services, warms caches
5. Smoke test: place 3 orders, verify printing and admin dashboard

### 5.4 Case File Resume & Cross-Runner Handoff

If work is interrupted (rate limit, context limit, manual handoff to another runner):

1. **Checkpoint:** The current agent writes its output + a refreshed `## Run State` block to `docs/cases/<task-slug>.md`
2. **Resume:** The resuming runner checks `docs/cases/<task-slug>.md`, reads the `## Run State`, and adopts the `next_agent` role
3. **Trust the case file:** The case file is the source of truth; chat history is secondary

See `docs/RESUME_PROTOCOL.md` for full protocol.

---

## 6. System Integrations

The platform repo itself does not integrate with external systems. It orchestrates the three app repos, which in turn integrate with:

- **POS (Krypton driver)** — Nexus integration
- **Reverb WebSocket** — Nexus + Tablet PWA + Print Bridge integration
- **Bluetooth printer** — Print Bridge integration

See the Nexus BRD Section 6 for full integration details.

---

## 7. Technical Infrastructure & Deployment

### 7.1 Docker Orchestration

**Production target:** Raspberry Pi 5 (on-premises, static IP 192.168.1.31 or 192.168.100.42)

**Services:** 8 containerized services managed by Docker Compose

**Host filesystem:**
- `./woosoo-nexus/` — Laravel source (bind-mounted in dev/staging; copied in immutable production)
- `./tablet-ordering-pwa/` — Nuxt PWA source (bind-mounted in dev/staging)
- `docker/certs/` — TLS certificates (gitignored; populated by `docker/certs/generate-dev-certs.sh` or host provisioning)
- `docker/nginx/default.conf` — Nginx configuration (human-edited)
- `docker/php/local.ini` — PHP settings (human-edited)

**Docker network:** `woosoo` (internal only; MySQL and Redis not published to host)

**Volumes:**
- `storage_data` — persistent Laravel storage (`/var/www/html/storage`)
- `mysql_data` — persistent database
- `redis_data` — persistent cache

### 7.2 Nginx Reverse Proxy

**Three listening ports:**

| Port | Purpose | Upstream |
|------|---------|----------|
| 80 | HTTP → HTTPS redirect | (redirect logic) |
| 443 | Admin UI, API, Reverb WebSocket | app:9000 (PHP-FPM), reverb:8080 (WebSocket proxy) |
| 4443 | Tablet PWA (static) + asset serving | tablet-pwa:3000 (static), storage_data (images, storage) |

**TLS:**
- Certificate: `/etc/nginx/certs/fullchain.pem`
- Key: `/etc/nginx/certs/privkey.key`
- Protocols: TLSv1.2, TLSv1.3
- CA certificate available for download: `GET /woosoo-ca.crt` (both HTTP and HTTPS)

**Security headers:**
- X-Frame-Options: SAMEORIGIN
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- HSTS: max-age=31536000

### 7.3 Configuration Management

**Source of truth:** `/etc/woosoo/woosoo.env` (host root-owned, mode 0600)

**Template:** `docs/deployment/examples/woosoo.env.example`

**Key variables:**
- `WOOSOO_PLATFORM_PATH` — path to platform repo (default: parent of `WOOSOO_NEXUS_PATH`)
- `WOOSOO_NEXUS_BRANCH` — branch to deploy for Nexus app
- `WOOSOO_TABLET_BRANCH` — branch to deploy for Tablet PWA
- `PUBLIC_HOST` — hostname or IP (e.g., `woosoo.local`, `192.168.1.31`)
- `REVERB_APP_KEY`, `REVERB_APP_ID` — WebSocket authentication
- `APP_KEY`, `DB_PASSWORD` — Laravel secrets (never committed)

The deploy script reads `/etc/woosoo/woosoo.env` and uses `docker compose --env-file` to interpolate variables into the stack.

### 7.4 Pre-Merge Validation Scripts

**Bash (cross-platform):**
```bash
bash scripts/pre-merge-check.sh --app woosoo-nexus
bash scripts/pre-merge-check.sh --app tablet-ordering-pwa
bash scripts/pre-merge-check.sh --app woosoo-print-bridge
```

**PowerShell (Windows):**
```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
```

These scripts wrap per-app validation commands and fail the merge gate if any test/lint/build step fails.

---

## 8. Delivered Scope — Platform Capabilities (as of 2026-05-27)

### Delivered ✅

- **Docker Compose orchestration** — 8 services (Nginx, app, queue, scheduler, Reverb, MySQL, Redis, Tablet PWA), multi-port routing (80/443/4443)
- **Nginx reverse proxy** — TLS termination, multi-host routing, CA certificate bootstrap endpoint, security headers
- **Cross-app contract governance** — 5 canonical contract files (order-state, tablet-api, printer-relay, pos-db, auth-session), enforced in code review
- **Lite 4-agent AI operating system** — Contrarian → Specialist → Verifier → Executioner; vendor-neutral (Claude Code, Codex CLI, Copilot); 5 specialist roles (ranpo-backend, chuya-frontend, relay-ops, dazai-docs, infra)
- **9 workflow hooks** — work, status, intake, triage, execute, verify, review, unlock, handover
- **Pre-merge validation gates** — `scripts/pre-merge-check.sh --app <name>` wraps per-app test/lint/build; blocks merge if any step fails
- **Per-task case file system** — durable resume state (`docs/cases/<task-slug>.md`); survives cross-runner interruption
- **Canonical documentation index** — `docs/README.md` with status frontmatter (canonical/archived/under-review); 4 audit docs (2026-05-14); per-app per-app `.agents.md`
- **Machine-readable orchestration state** — `state/WORK.md` (active case), `state/QUEUE.md` (task queue), `state/DEPS.md` (dependencies), `state/DONE.md` (completion log)
- **Deployment scripts** — `deploy.sh` (pulls app repos, builds, starts); `apply-woosoo-config.sh` (env template population); migration status documented in `scripts/deployment/README.md`
- **TLS certificate generation** — `docker/certs/generate-dev-certs.sh` (local mkcert setup)

### Operational (not yet migrated or pending verification) ⚠️

- **Production Pi deployment** — `deploy.sh` and `apply-woosoo-config.sh` migrated and syntax-checked; **Pi runtime verification PENDING** (requires Pi hardware access and network validation)
- **Hot-deploy vs. immutable image toggle** — compose file includes inline documentation; switch not yet tested in production
- **Print Bridge Docker integration** — intentionally out of scope; remains Flutter Android relay
- **Session state migration scripts** — documented but not yet required (existing Pi sessions migrated manually)

### Known Gaps (below delivered scope, future work)

- Automated production smoke tests (manual verification currently required)
- Kubernetes orchestration alternative (on-premises Pi only; no K8s target documented)
- Multi-datacenter failover (single-site deployment)
- Secrets rotation (static `.env` on Pi; no Vault/Secrets Manager)

---

## Appendix: Cross-Reference to Nexus BRD

The Woosoo Nexus Business Requirements Document (tech-artificer/woosoo-nexus PR #138) covers:
- **Section 1** — Executive Summary (Nexus as the backend system)
- **Section 2** — System Architecture (Nexus API, Admin Dashboard, Grillpad Tablet PWA, Print Bridge, Reverb, MySQL, Redis)
- **Sections 3–8** — Capabilities, workflows, integrations, infrastructure, delivered scope

**This supplement (woosoo-platform BRD):**
- Adds woosoo-platform as the **4th architectural component** (governance + orchestration)
- Defines the **Docker Compose stack** that runs all 8 services (Nexus doc focuses on the app, this doc focuses on the deployment)
- Documents the **cross-app contracts** that enforce API boundaries
- Specifies the **AI agent operating system** (Lite 4-agent, vendor-neutral)
- Describes the **pre-merge validation gates** that gate all changes across the system

Together, the Nexus BRD + this supplement provide the complete technical scope of Woosoo.

---

**Document version:** 1.0  
**Last updated:** 2026-05-27  
**Reviewed by:** dazai-docs specialist (Haiku 4.5)
