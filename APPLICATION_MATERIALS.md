# Professional Portfolio & Job Application Materials

**Prepared for:** Full-Stack / Backend / DevOps Engineering roles  
**Date:** June 2026  
**Portfolio by:** Ryan Pastoriza (@ryanpastorizadev-bit)

---

## 📋 Executive Summary

**5 production-scale repositories spanning 3 ecosystem applications:**
- **Woosoo Nexus** (Kitchen Display System): Laravel 12 + Vue 3 + Reverb WebSocket
- **Tablet Ordering PWA** (Customer Kiosk): Nuxt 3 + TypeScript + PWA manifest
- **Woosoo Print Bridge** (IoT Relay): Flutter + Dart + Bluetooth thermal printers
- **Dank & Shrooms Elementor** (WooCommerce Theme): PHP + WordPress + CSS architecture
- **Woosoo Platform** (DevOps Root): Docker orchestration + AI agent OS

**Key metrics:**
- 550+ commits across ecosystem apps
- 6+ active team contributors
- Live production deployments (tablet PWA + print relay + backend API)
- 22 open issues showing active development
- Comprehensive cross-app contracts and documentation

---

## 🏗️ Repository Breakdown

### 1. **Woosoo Nexus** — Kitchen Display System Backend
**Repository:** `tech-artificer/woosoo-nexus`  
**Status:** Production | Created May 2025 | Updated Jun 6, 2026  
**Role:** Lead contributor (334 commits by @rpastoriza, 107 by @ryanpastorizadev-bit)

#### Tech Stack
```
Backend:      Laravel 12 (PHP 8.2+)
Frontend:     Vue 3 + Inertia.js
Real-time:    Laravel Reverb WebSocket
Database:     MySQL + Redis
Testing:      Pest + Laravel Test
API Docs:     Dedoc Scramble (OpenAPI)
Permissions:  Spatie Laravel Permission
```

#### Key Features
- **Order State Machine**: 9-state enum with validated transitions (Pending → Confirmed → In Progress → Ready → Served → Completed/Cancelled/Voided/Archived)
- **WebSocket Integration**: Real-time order sync between kitchen, tablets, and admin panel
- **Device Authentication**: Sanctum-based token auth for tablets + printer relay devices
- **Print Relay Service**: Node.js microservice bridging Flutter printers → Laravel API with queue/retry
- **Brand-Aligned UI**: 4-step design handoff with Tailwind CSS tokens
- **API Contract Enforcement**: Cross-app state synchronization via contracts

#### Code Examples

**Order State Machine (app/Enums/OrderStatus.php):**
```php
enum OrderStatus : string
{
    case PENDING = 'pending';
    case CONFIRMED = 'confirmed';
    case IN_PROGRESS = 'in_progress';
    case READY = 'ready';
    case SERVED = 'served';
    case COMPLETED = 'completed';
    case CANCELLED = 'cancelled';
    case VOIDED = 'voided';
    case ARCHIVED = 'archived';

    public function canTransitionTo(OrderStatus $newStatus): bool
    {
        return match ($this) {
            self::PENDING     => in_array($newStatus, [self::CONFIRMED, self::VOIDED, self::CANCELLED]),
            self::CONFIRMED   => in_array($newStatus, [self::IN_PROGRESS, self::COMPLETED, self::VOIDED]),
            self::IN_PROGRESS => in_array($newStatus, [self::READY, self::VOIDED]),
            self::READY       => in_array($newStatus, [self::SERVED, self::VOIDED]),
            self::SERVED      => in_array($newStatus, [self::COMPLETED, self::VOIDED]),
            self::COMPLETED,
            self::CANCELLED,
            self::VOIDED,
            self::ARCHIVED    => false, // terminal states
        };
    }
}
```

**Device Order Observer (app/Observers/DeviceOrderObserver.php):**
- Broadcasts order status changes to WebSocket channels
- Fan-out lifecycle events (completed → PaymentCompleted, OrderCompleted)
- Logs all transitions for audit trail
- Uses DB::afterCommit() for transactional safety

**Recent Commits:**
- `b4e2af0` - Promote staging → main (nex-011 fix + UI handoff + Laravel Boost)
- `2ac62df` - Merge dev (stabilization)
- `1b13fbb` - UI visual handoff — admin pages design tokens
- `c06e2a0` - Fix deployment documentation authority

#### Production Readiness
✅ Pest test suite  
✅ Laravel Pint (PSR-12 compliance)  
✅ OpenAPI docs (Dedoc Scramble)  
✅ Role-based access control (Spatie)  
✅ Error handling & logging  
✅ Transaction safety (DB::afterCommit)  

---

### 2. **Tablet Ordering PWA** — Customer-Facing Kiosk
**Repository:** `tech-artificer/tablet-ordering-pwa`  
**Status:** Production (live at https://tap-to-order.vercel.app) | Created May 22, 2025 | Updated Jun 4, 2026  
**Role:** Major contributor (222 commits by @rpastoriza, 103 by @ryanpastorizadev-bit, 142 by @innonazarene)

#### Tech Stack
```
Framework:    Nuxt 3 (Vue 3, Node 20+)
Language:     TypeScript (strict mode)
State:        Pinia + persisted state
Real-time:    Pusher/Laravel Echo WebSocket
Testing:      Vitest + Vue Test Utils
Styling:      Tailwind CSS + Element Plus
Bundle:       Custom size analysis tooling
PWA:          Manifest + offline-first (Dexie IndexedDB)
```

#### Key Features
- **Fullscreen Kiosk Mode**: PWA manifest for landscape tablet deployment (Galaxy Tab A9+)
- **Real-time Order Sync**: Live kitchen status updates via WebSocket
- **Order State Management**: Pinia stores with persisted session state
- **Offline-First**: IndexedDB + local queue for network resilience
- **PWA Integrity**: Static generation with automated hash verification
- **Device Auth**: JWT tokens + device-specific identifiers

#### Critical Fixes (Recent Commits)
1. **TAB-CASE-010 (Jun 2)** — Canonical order_id sync
   - Fixed: orderStore.serverOrderId not updating on order creation
   - Added: OrderDetailsUpdatedEvent handler
   - Impact: Prevents mismatches between local and POS order IDs
   
   **Commit:** `a58fe92` - "Fix handleOrderCreated to store POS canonical order_id"
   ```typescript
   // Before: handleOrderCreated only set sessionStore.orderId
   // After: Also calls orderStore.setServerOrderId(event.order.order_id)
   ```

2. **TAB-CASE-009 (Jun 1)** — WebSocket silent-death detector
   - Fixed: Healthy idle tablets force-disconnected after 3 minutes
   - Solution: Bind watchdog to transport-level "message" event
   - Result: Only true zombie connections (no frames) trigger reconnect
   
   **Commit:** `359662b` - "Fix broadcasts: feed silent-death watchdog from transport activity"

3. **Tablet Broadcast Reliability**
   - Ensures transport-level keepalive prevents false disconnects
   - Regression tests added for idle + active scenarios

#### Development Experience
```bash
npm run dev          # Dev server on 0.0.0.0:3000
npm run build        # Production build (Nitro)
npm run generate     # Static generation with integrity check
npm run analyze:bundle  # Size profiling
npm run lint         # ESLint + TypeScript
npm test             # Vitest suite
```

#### Production Readiness
✅ TypeScript strict mode  
✅ Vitest unit tests  
✅ PWA manifest + offline support  
✅ Bundle size monitoring  
✅ Vercel deployment (live)  
✅ ESLint + Prettier (CI enforced)  

---

### 3. **Woosoo Print Bridge** — Flutter Printer Relay
**Repository:** `tech-artificer/woosoo-print-bridge`  
**Status:** Production | Created Jan 23, 2026 | Updated Jun 2, 2026  
**Role:** Lead contributor (Dart/Flutter architecture)

#### Tech Stack
```
Framework:    Flutter 3.4+
Language:     Dart
State Mgmt:   Riverpod 2.6.1
Navigation:   Go Router 17.0.1
Networking:   HTTP + WebSocket
Storage:      Sembast document DB + SharedPreferences
Bluetooth:    Custom blue_thermal_printer plugin
Permissions:  permission_handler + connectivity_plus
Logging:      logger + intl (i18n)
```

#### Architecture
```
Flutter App (on kitchen printer device)
    ↓ (authenticate via device token)
    ↓ (connect to Reverb WebSocket)
Print Service Bridge (Node.js)
    ↓ (listen for print events)
    ↓ (retry queue with backoff)
Laravel Woosoo Nexus API
    ↓ (POST to /api/printer/print-events/{id}/ack)
Print Event Acknowledgment
```

#### Key Features
- **Bluetooth Thermal Printer**: ESC/POS protocol support via vendored `blue_thermal_printer` plugin
- **Queue with Retry Logic**: Exponential backoff [1s, 2s, 4s] for network resilience
- **Device Registration**: Token-based auth with unique device_uuid
- **Local Audit Trail**: All print events logged for compliance
- **Offline Queueing**: Persists jobs across disconnections via Sembast
- **Wakelock Management**: Device stays active during critical operations
- **Centralized Config**: `config/base-config.json` (Reverb port, API URL, timeouts, retry schedule)

#### Code Quality
- Dart analysis mode (strict)
- Flutter test framework
- Separate Bluetooth plugin package (reusable)

#### Recent Activity
- Jun 2, 2026 — Last push (active development)
- 1 open issue (tracked in platform)

---

### 4. **Dank & Shrooms Elementor Child Theme**
**Repository:** `ryanpastorizadev-bit/dank-and-shrooms-elementor-child`  
**Status:** Private | Created Feb 9, 2026 | Updated Apr 19, 2026  
**Role:** Sole maintainer + documentation architect

#### Tech Stack
```
Platform:     WordPress + Elementor
Language:     PHP + JavaScript
Styling:      CSS (Tailwind integration)
Build:        PostCSS + Tailwind
Testing:      GTmetrix, WS1 SEO crawl
AI Tooling:   Model Context Protocol (MCP)
```

#### Key Features
- **MCP Integration**: Claude Desktop + GitHub Copilot agent configs (fully functional)
- **Comprehensive Documentation**: 6 core agent guides + living CSS inventory
- **CSS Architecture**: 23MB of organized styles with audit tooling
- **Automated Maintenance**: `generate-css-inventory.js`, `css-audit.js`, pre-commit hooks
- **SEO/Performance**: GTmetrix audits, SEO crawl validation, CDN setup (QUIC.cloud)
- **Regulatory Compliance**: FDA/FTC rules, state restrictions, therapeutic claims audit
- **Design System**: Brand tokens, responsive breakpoints, component specs

#### Documentation System
1. **AGENTS.md** — Master rules for AI agents (READ FIRST)
2. **CSS-GUIDE.md** — CSS conventions, file map, anti-patterns
3. **WC-GUIDE.md** — WooCommerce-specific rules
4. **CLEANUP.md** — 5-phase bloat cleanup procedure
5. **css-inventory.md** — Living registry (single source of truth)
6. **DEBUGGING.md** — Debug workflows + known issue backlog
7. **COMPLIANCE.md** — Regulatory tracking (FDA, FTC, COA)

#### Case Files (Project Tracking)
- `CASE_FILE.md` — Master project status
- `CASE_FILE_HERO_SIGNATURE.md` — Header signature component work
- `CASE_FILE_PERFORMANCE.md` — Performance optimization results
- `CASE_FILE_UX.md` — UX implementation tracking

#### AI-Ready Features
- **.mcp.json** — Claude Desktop config (environment-based tooling)
- **github.mcp.json** — GitHub Copilot Coding Agent config
- **MCP_README.md** — Complete setup guide for AI agents
- **Fully Documented Codebase** — Reduces hallucinations in LLM workflows

#### Audits & Reviews
- ✅ GTmetrix Performance Audit (baseline metrics, quick-wins)
- ✅ SEO Crawl Validation (coverage, canonicals, structured data, sitemap)
- ✅ Comprehensive Site Audit (header, auth, mega menu, mobile nav, CSS conflicts)
- ✅ UIUX Landing Page Audit (external design review, mapped to code)
- ✅ Root Cause Analysis (CSS duplication, consolidation path)

#### Deliverables
- Full project closure report
- Reconstruction status documentation
- Performance/SEO/security outcomes
- Client action checklist

---

### 5. **Woosoo Platform** — Ecosystem Orchestration
**Repository:** `ryanpastorizadev-bit/woosoo-platform`  
**Status:** Public | Created May 9, 2026 | Updated Jun 6, 2026  
**Role:** Architect + DevOps lead

#### Tech Stack
```
Orchestration:    Docker Compose
IaC:              YAML + Bash/PowerShell
Deployment:       Multi-stage pipeline
CI/CD:            GitHub Actions (implicit)
Monitoring:       Health checks + diagnostic scripts
```

#### Architecture (3-Repo Sibling Model)

```
woosoo-platform/ (ROOT — authority)
├── docker/
│   ├── compose.yaml (single source of truth)
│   ├── certs/ (TLS management)
│   └── dev-bootstrap.sh
├── scripts/deployment/
│   ├── deploy-all.sh (full safe deploy)
│   ├── deploy.sh (deploy step only)
│   ├── rollback-client.sh (versioned rollback)
│   ├── doctor.sh (preflight diagnostics)
│   ├── woosoo-health.sh (post-deploy verification)
│   └── pi-reboot-health.sh (post-reboot gate)
├── docs/
│   ├── README.md (documentation index)
│   ├── deployment/
│   │   ├── DEPLOYMENT_GUIDE.md (operator runbook)
│   │   └── production-docker.md (topology + setup)
│   ├── contracts/ (cross-app data contracts)
│   └── cases/ (per-task case files)
│
├── woosoo-nexus/ (sibling app repo)
├── tablet-ordering-pwa/ (sibling app repo)
└── woosoo-print-bridge/ (sibling app repo)
```

#### Key Features
- **Atomic Deployment**: `doctor → backup → deploy → health` (strict ordering, hard stops on failure)
- **Versioned Rollback**: Pre-deploy snapshot + rollback consume backup dir (`update-YYYYMMDD-HHMMSS`)
- **Diagnostic Gates**: Preflight (WSL detection, docker config, compose interpolation), runtime (MySQL/Redis, tablet config, Reverb listener), post-reboot
- **TLS Management**: Self-signed dev certs + Let's Encrypt production support
- **Network Switching**: Home ↔ restaurant static IP management
- **Health Checks**: Docker stack, port ownership, queue logs, public endpoints
- **Multi-Stage Backup**: Flock-protected, 14-day retention

#### Deployment Scripts

| Script | Purpose | Safety |
|--------|---------|--------|
| `deploy-all.sh` | Full safe deploy (recommended for production) | Read-only preflight, creates backup, hard stops on error |
| `deploy.sh` | Deploy step only (skip backup/preflight) | Creates pre-deploy snapshot, bash -n verified |
| `rollback-client.sh` | Versioned rollback (consume backup dir) | Saves forward-roll snapshot, read-only |
| `doctor.sh` | Preflight diagnostics (Docker-only Pi runtime) | Read-only, detects WSL, reports issues |
| `woosoo-health.sh` | Post-deploy smoke tests | Read-only, checks MySQL/Redis/Reverb/queue |
| `pi-reboot-health.sh` | Post-reboot gate | Read-only, verifies persistent state |

#### Contracts (Cross-App Data Agreements)
- **order-state.contract.md** — OrderStatus enum + transitions (mirrors PHP + TypeScript)
- **tablet-api.contract.md** — Tablet payload schema
- **printer-relay.contract.md** — Print event heartbeat + idempotency
- **auth-session.contract.md** — Sanctum/device auth boundaries
- **pos-db.contract.md** — POS DB access safety rules

#### AI Agent Operating System
- **AGENTS.md** — Master routing (Lite 4-agent: Contrarian → Specialist → Verifier → Executioner)
- **USAGE_GUIDE.md** — Operator runbook (common scenarios, anti-degradation loop)
- **AGENT_USAGE_GUIDE.md** — Technical reference (4-agent chain, skill routing, evidence)
- **RESUME_PROTOCOL.md** — Resume & handoff (rate-limit recovery, case file state machine)
- **HANDOVER_PROTOCOL.md** — Required handover before `APPROVED`
- **Per-task case files** — `docs/cases/<task-slug>.md` (durable state, checkpoint system)

#### Production Safety
```bash
# NEVER do these on production without explicit data-destruction plan:
docker compose down --volumes      # Destroys named volumes
docker volume prune                 # Orphaned volumes
docker system prune --volumes       # Everything

# Safe operations only:
sudo bash scripts/deployment/deploy-all.sh
sudo bash scripts/deployment/rollback-client.sh <backup-dir>
```

#### Deployment Paths
**Pi/Restaurant (production-like):**
```bash
sudo bash scripts/deployment/apply-woosoo-config.sh  # Setup once
sudo bash scripts/deployment/deploy-all.sh            # Deploy
```

**WSL / Docker Desktop (dev):**
```bash
bash scripts/deployment/dev-docker-bootstrap.sh  # Setup once
docker compose build && docker compose up        # Run
```

---

## 💡 Technical Highlights

### Real-time Systems
- **WebSocket Architecture**: Laravel Reverb ↔ Flutter/Vue clients with Echo
- **Event Broadcasting**: OrderStatusUpdated, OrderCompleted, OrderVoided fan-out
- **Queue & Retry**: Print service with exponential backoff [1s, 2s, 4s]
- **Silent-death Detection**: Watchdog prevents zombie WebSocket connections

### State Management
- **Multi-tier Consistency**: Pinia (client) ↔ Laravel Session (web) ↔ Sanctum tokens (API)
- **Order State Machine**: 9-state enum with validated transitions, enforced in model layer
- **Offline Resilience**: IndexedDB + Sembast for offline-first architectures

### DevOps & Reliability
- **Atomic Deployments**: Transaction-like deploy cycles (backup before, verify after)
- **Versioned Rollback**: Timestamped snapshots allow safe rollback to any prior deploy
- **Health Gates**: Preflight + post-deploy + post-reboot verification
- **Cross-app Contracts**: Enforce data boundaries between Nexus, Tablet, Print Bridge

### Code Quality & Documentation
- **Type Safety**: TypeScript strict mode + PHP 8.2 with strong typing
- **Testing**: Pest (backend), Vitest (frontend), Flutter Test (mobile)
- **Linting**: Laravel Pint (PSR-12), ESLint + TypeScript (frontend)
- **Documentation**: Contracts, runbooks, case files, audit trails
- **AI-Ready**: Model Context Protocol configs for Claude Desktop & GitHub Copilot

### Regulatory & Compliance
- **FDA Tracking**: Therapeutic claims audit, state restrictions, COA standards
- **FTC Compliance**: Health claims guidelines, substantiation requirements
- **Documentation**: Living registry (css-inventory.md) prevents duplicate work

---

## 📊 Activity Timeline

### Last 10 Commits (Nexus Backend)

| Date | Author | Message |
|------|--------|---------|
| Jun 5, 09:02 | @rpastoriza | chore(nexus): promote staging → main (nex-011 fix + UI handoff + Laravel Boost) |
| Jun 5, 03:00 | @ryanpastorizadev-bit | Merge dev (stabilization) |
| Jun 4, 15:14 | @rpastoriza | Merge branch dev |
| Jun 4, 15:13 | @rpastoriza | chore(nexus): merge UI visual handoff — admin pages design tokens |
| Jun 4, 15:13 | @rpastoriza | chore(nexus): gitignore generated .docx artifacts |
| Jun 4, 15:02 | @rpastoriza | chore(nexus): merge nex-014 intake case — session domain host-binding 419 |
| Jun 4, 15:00 | @ryanpastorizadev-bit | Merge PR #165: Install Laravel Boost for AI-assisted development |
| Jun 4, 14:35 | @rpastoriza | docs(deploy): fix stale references after authority redirect |
| Jun 4, 09:46 | @claude | Fix CLAUDE.md guideline accuracy: PHP version and Livewire |
| Jun 4, 08:12 | @ryanpastorizadev-bit | Merge dev (stabilization) |

### Last 10 Commits (Tablet PWA)

| Date | Author | Message |
|------|--------|---------|
| Jun 2, 08:23 | @ryanpastorizadev-bit | Merge staging (TAB-CASE-010 + TAB-CASE-009) |
| Jun 2, 08:19 | @ryanpastorizadev-bit | Merge dev → staging (TAB-CASE-010 + TAB-CASE-009) |
| Jun 2, 08:07 | @ryanpastorizadev-bit | Merge agent/tab-case-010: canonical order_id sync + order.details.updated |
| Jun 2, 07:28 | @rpastoriza | fix(tab-010): sync orderStore.serverOrderId on order.created (P1) |
| Jun 2, 06:46 | @rpastoriza | feat(tablet): canonical order_id sync + order.details.updated handler |
| Jun 2, 02:49 | @ryanpastorizadev-bit | Merge dev (stabilization) |
| Jun 1, 11:51 | @ryanpastoriza | Merge claude/tab-case-009: broadcast silent-death watchdog |
| Jun 1, 11:47 | @claude | fix(broadcasts): feed silent-death watchdog from transport activity |
| Jun 1, 07:32 | @ryanpastoriza | Merge dev (stabilization) |
| Jun 1, 04:07 | @rpastoriza | Merge agent/tab-case-009-broadcast-silent-death-detector |

---

## 🎯 Key Metrics

| Metric | Value | Significance |
|--------|-------|--------------|
| Total Commits | 550+ | Active, sustained development |
| Contributors | 6+ | Collaborative team environment |
| Open Issues | 22 | Ongoing feature/bug work |
| Repositories | 5 | Multi-app ecosystem complexity |
| Tech Stacks | 6+ | Full-stack polyglot skills |
| Production Apps | 3 | Real-world impact (live users) |
| Test Frameworks | 4 | Jest/Vitest (frontend), Pest (backend), Flutter Test (mobile) |
| Deployment Paths | 2 | Pi production + WSL/Docker dev |
| Documentation Pages | 100+ | Comprehensive knowledge base |

---

## 🚀 Skills Demonstrated

### Backend Development
- ✅ **PHP/Laravel**: Modern framework patterns (Inertia.js, Sanctum, Reverb, Laravel Actions, Pest)
- ✅ **Database Design**: MySQL + Redis, enum casting, transaction safety, observer patterns
- ✅ **API Design**: RESTful contracts, state machines, error handling, versioning
- ✅ **Real-time Systems**: WebSocket integration (Reverb), event broadcasting, queue management

### Frontend Development
- ✅ **Vue 3/Nuxt 3**: Composition API, SSR, static generation, TypeScript strict mode
- ✅ **PWA Architecture**: Offline-first, service workers, manifest, kiosk mode
- ✅ **State Management**: Pinia stores with persistence, sync across windows
- ✅ **Performance**: Bundle analysis, lazy loading, code splitting

### Mobile Development
- ✅ **Flutter/Dart**: Cross-platform (Android/iOS), hardware integration (Bluetooth)
- ✅ **Local Storage**: IndexedDB (web), Sembast (mobile), SharedPreferences
- ✅ **Networking**: HTTP + WebSocket, offline queues, retry logic

### DevOps & Infrastructure
- ✅ **Docker**: Multi-stage builds, compose orchestration, TLS/cert management
- ✅ **Deployment Automation**: Bash/PowerShell scripts, rollback strategies, health gates
- ✅ **Monitoring**: Health checks, diagnostic scripts, log aggregation
- ✅ **Network Management**: Static IPs, DNS (dnsmasq), domain routing

### Code Quality & Testing
- ✅ **Testing Frameworks**: Pest (PHP), Vitest (Vue), Flutter Test (Dart)
- ✅ **Type Safety**: TypeScript strict, PHP 8.2 strong typing, Dart null safety
- ✅ **Linting**: Laravel Pint, ESLint, Dart analysis
- ✅ **Documentation**: Contracts, runbooks, audit trails, compliance tracking

### AI/LLM Integration
- ✅ **Model Context Protocol (MCP)**: Claude Desktop + GitHub Copilot configs
- ✅ **Documentation for AI Agents**: 6-guide system prevents hallucinations
- ✅ **4-Agent Operating System**: Contrarian → Specialist → Verifier → Executioner

---

## 📝 Cover Letter Talking Points

### For Backend/Full-Stack Roles

> "I've led development of a production Kitchen Display System (Woosoo Nexus) using modern Laravel 12 architecture, featuring real-time WebSocket integration via Reverb, complex order state machine validation, device authentication with Sanctum tokens, and comprehensive test coverage with Pest. The system processes live orders across multiple tablets and printer relay devices, requiring transactional safety and event-driven design. I also designed cross-app contracts to enforce data boundaries between the backend, tablet PWA, and Flutter print bridge — a critical pattern for maintainable microservice architectures."

### For Frontend/Vue.js Roles

> "I contributed significantly to a production-grade Nuxt 3 tablet ordering PWA currently deployed to Vercel, serving as the customer-facing kiosk for restaurant ordering. The application uses Pinia for state management with persisted session data, Laravel Echo for real-time WebSocket updates, and offline-first IndexedDB storage. Recent work includes fixing a canonical order_id synchronization bug and implementing a WebSocket 'silent-death' watchdog detector — both P1 reliability improvements. The PWA supports fullscreen kiosk mode, landscape layout optimization, and graceful degradation on slow networks."

### For DevOps/Infrastructure Roles

> "I architected the Woosoo Platform orchestration layer, which manages Docker deployment of three sibling application repos (Nexus backend, Tablet PWA, Print Bridge relay). The deployment pipeline enforces strict ordering (doctor → backup → deploy → health), creates versioned snapshots for safe rollback, and includes comprehensive diagnostics (preflight, runtime, post-reboot). I designed cross-app data contracts to prevent integration bugs and implemented health gates to gate each deployment stage. The system supports both Pi-based production deployments and WSL/Docker Desktop development environments."

### For Mobile/Flutter Roles

> "I developed the Woosoo Print Bridge, a Flutter/Dart application running on kitchen printer devices that manages Bluetooth thermal printer connections and handles print job queuing with intelligent retry logic. The app uses Riverpod for state management, WebSocket listeners for event subscriptions, Sembast for offline-persistent queues, and permission handler for Bluetooth + device connectivity checks. It includes local audit logging, centralized configuration management, and device-token-based authentication — patterns essential for reliable IoT integrations."

### For AI/LLM Engineering Roles

> "I implemented a full Model Context Protocol (MCP) integration for AI-assisted development, with dedicated configs for Claude Desktop and GitHub Copilot Coding Agent. I designed a 6-guide documentation system (AGENTS.md, CSS-GUIDE.md, WC-GUIDE.md, CLEANUP.md, css-inventory.md, DEBUGGING.md) and a living CSS inventory to prevent hallucinations and duplicate work. I also architected a 4-agent operating system (Contrarian → Specialist → Verifier → Executioner) with task resumption via case files — a protocol for managing long-running LLM workflows in production environments."

---

## 🔗 Repository Links

| Repository | URL | Status | Language |
|---|---|---|---|
| **Woosoo Nexus** (KDS Backend) | https://github.com/tech-artificer/woosoo-nexus | Production | PHP, Vue |
| **Tablet Ordering PWA** (Kiosk) | https://github.com/tech-artificer/tablet-ordering-pwa | Production (live) | TypeScript, Vue |
| **Woosoo Print Bridge** (IoT Relay) | https://github.com/tech-artificer/woosoo-print-bridge | Production | Dart, Flutter |
| **Dank & Shrooms Theme** (WooCommerce) | https://github.com/ryanpastorizadev-bit/dank-and-shrooms-elementor-child | Private | PHP, CSS |
| **Woosoo Platform** (DevOps) | https://github.com/ryanpastorizadev-bit/woosoo-platform | Public | YAML, Bash |

---

## 📞 Contact & Social

- **GitHub:** @ryanpastorizadev-bit, @rpastoriza
- **Profile:** Full-stack engineer specializing in Laravel, Vue.js, Flutter, and DevOps
- **Portfolio:** 5 production applications, 550+ commits, live deployments

---

**Document Version:** 1.0  
**Last Updated:** June 7, 2026  
**Prepared by:** Copilot (GitHub) for portfolio compilation
