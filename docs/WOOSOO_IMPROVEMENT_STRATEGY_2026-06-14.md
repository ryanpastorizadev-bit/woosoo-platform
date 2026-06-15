---
status: canonical
last_reviewed: 2026-06-14
scope: ecosystem
---

# Woosoo Improvement Strategy 2026-06-14

> **This is a strategy + backlog document, not an implementation.** Every buildable item is a queued case routed through the normal sequence (Contrarian → Specialist → Verifier → scribe → Executioner), assigned to the right Bucket in `state/QUEUE.md` and specialist. Nothing here relaxes Tier-3 governance or the 6 `contracts/`.

## Origin

This strategy grew from the question: "How do we maximize the Cursor tools we installed (Datadog, Obsidian, Laravel Boost, Context7, Superpowers)?" It expanded through operator follow-ups into five connected threads (A–E). See the program case file: [[cases/plt-case-tooling-improvement-program]].

## Guiding principle

> The five tools are **context and evidence providers** for the Specialist and Verifier phases; the five threads are **improvements routed as cases**. Tools surface and feed the case files; new docs/tests extend the evidence base; Google Docs and Obsidian are *read surfaces* over markdown that stays canonical. Nothing forks the single source of truth.

## Key findings from codebase exploration

1. **Docs are already mature.** Both repos have canonical BRDs (per-app), `API_MAP.md` + `openapi.json` + per-controller API docs, `END_TO_END_WORKFLOW.md`, operator/handover manuals (incl. generated `.docx`), and a process/product/user SDLC split under `woosoo-nexus/docs/software-development/`. Thread C is **gap-filling + a stakeholder-facing mirror**, not authoring from scratch.

2. **The frontend has zero UI tests.** `woosoo-nexus/resources/js/` has ~396 Vue components, strong Vite/TypeScript/ESLint/Tailwind-v4 infra and CI lint/typecheck/build — but no Vitest/component tests, no Playwright/Cypress E2E, no visual regression, no a11y tooling, and no global runtime error handler. Thread D is **net-new test scaffolding on a solid base**, highest-leverage at the visual-regression + runtime-error layer.

3. **`.mcp.json` was already correctly configured** (`--env=local` + correct `cwd`) before this strategy was written. No action needed.

---

## Thread A — Cursor tooling strategy

**One-line goal:** Slot the five installed tools (Datadog, Obsidian, Laravel Boost, Context7, Superpowers) into the existing 4-agent chain so they improve evidence quality and reduce token waste, without bypassing governance.

| Tool | Phase it serves | Wired via | Main axis |
|---|---|---|---|
| **Context7** | Specialist pre-edit research | `docs-researcher` subagent; `execute`/`pre-edit-gate` hooks | Token mitigation + correctness |
| **Laravel Boost** | Specialist + Verifier (nexus) | `.mcp.json` (already fixed); session start; `laravel-api-change`/`sanctum-auth-debug` skills | QA + token mitigation |
| **Superpowers** | Verifier / Executioner gate | `test-verification` skill; `verify` hook | QA (evidence before COMPLETE) |
| **Obsidian** | Operator orchestration (human) | case files, `state/`, `OPERATOR_HOME.md`, Bases | Orchestration/workflow |
| **Datadog** | Verifier (post-deploy) + intake — **deferred** | `verify`/`intake` hooks once instrumented | QA + orchestration (later) |

### Key moves by axis

**Token / context:**
- Delegate library/log research to subagents (`docs-researcher`, Boost `search-docs`); only conclusions return into `## Investigation`.
- Scope MCP per app (Boost for nexus; `/ddtoolsets` logs+alerting for Datadog once live).
- Right-tool-first avoids wrong-version correction loops.

**QA:**
- Map Superpowers onto the **existing** Verifier — one proof command per task, raw output into `## Verification`; full `verification-before-completion` before merge. Do not double-run Superpowers + Verifier.
- Use Boost `database-schema`/`ApplicationInfo` for version/schema-correct nexus work.

**Orchestration:**
- Obsidian as UI over the agent layer — section embeds in `OPERATOR_HOME.md`, a `docs/meta/cases.base` active-cases dashboard.
- Proposed: mirror `run_status`/`next_agent`/`tier`/`app` from `## Run State` into case frontmatter so Bases/Dataview can answer "what's active?" without parsing bodies. `## Run State` stays authoritative for agents.

**Automation:**
- Session-start hook auto-runs Boost `ApplicationInfo` for nexus.
- `pre-edit-gate` hook requires `search-docs`/Context7 proof before Specialist edits.
- CI stays the merge gate; nothing in this thread weakens it.

**Queued cases (Bucket B-follow, Tier 1–2):** see [[cases/plt-case-tooling-improvement-program]] sub-case table.

---

## Thread B — MCP topology: WSL staging mirror

**One-line goal:** Clarify where MCP servers actually run and stand up a reachable staging DB so Boost DB tools work reliably.

**The reality:** MCP servers run **client-side where Cursor runs** (the WSL/Windows box), not "on the Pi."

- **Boost never runs on the Pi** — it's `require-dev` and self-disables at `APP_ENV=production`. Correct as-is.
- **Datadog & Context7 are cloud-query** — location-agnostic; auth via OAuth.
- **Stand up a WSL staging mirror** (Laravel Sail or local MySQL seeded via migrations + `pos:setup-payment-trigger`, **sanitized — no real customer data**) so Boost `database-schema`/`database-query` actually work. Never point Boost at the live Pi prod DB.
- The same WSL staging box is the home for running the full Pest suite, Vitest, and Playwright (Thread D) without touching prod.

**Guardrails:** separate staging `.env`; secrets stay out of chat/Git; honor `pos-db.contract.md` (no destructive POS writes, no schema assumptions).

**Queued case:** [[cases/infra-case-011-wsl-staging-mirror]] — Bucket B, Tier 2, specialist: infra.

---

## Thread C — Documentation program: gap-fill + stakeholder mirror

**One-line goal:** Fill the strategic documentation gaps without rebuilding what already exists; add a one-way markdown→GDocs mirror for stakeholders.

Existing docs are mature — do not rebuild them. Fill these **strategic gaps** (each a `scribe` case, Tier 1–2):

1. **Unified versioning + CHANGELOG policy** — only nexus has a `CHANGELOG.md`; add ecosystem versioning policy (semver, release cadence, cross-repo sync) + per-repo CHANGELOGs.
2. **Visual diagrams** — order **state-machine diagram** (from `order-state.contract.md`) and **sequence diagrams** for the E2E transaction (tablet → nexus → POS → print-bridge → printer); today only topology PNGs exist.
3. **API versioning/deprecation strategy** — `API_MAP.md` + `openapi.json` exist but no v1↔v2 migration/deprecation doc; optionally serve `openapi.json` via Redoc/Swagger UI.
4. **Troubleshooting decision trees** — "print failed → check X → Y", "419 on login → …" — bridging the gap between the handover manual and the case system.
5. **1-page operator quickstart** + populate the pending in-app guides (`resources/docs/guides/{admin,tablet,relay}/`).
6. **Ecosystem-level BRD roll-up + handover checklist** — synthesize the per-app BRDs into one cross-repo BRD; add a sign-off checklist alongside the existing handover manual.
7. **Timeline/roadmap** — fold into [[WOOSOO_ROADMAP_REVIEW]] rather than a new artifact.

**Google Docs mirror layer:** markdown in `docs/` stays canonical and Git-versioned; a thin export mirrors the *stakeholder-facing* subset to Google Docs for non-technical readers (BRD roll-up, user/operator manual, restaurant-ops handover manual, ecosystem overview, timeline). Mirror is **one-way (md → GDocs)** and clearly stamped "generated from `docs/...` — do not edit here" to prevent the state-fork failure mode.

**Recommended depth:** Phase 1 = define the gap list + scaffold stubs/templates and wire the GDocs mirror for 2–3 highest-value stakeholder docs. Phase 2 = author the diagrams, versioning policy, and troubleshooting trees. Don't author what already exists.

---

## Thread D — UI accuracy / automated checker

**One-line goal:** Add UI test scaffolding to the zero-test frontend, starting with the highest-leverage, lowest-effort layers.

Strong build infra, zero UI tests. Phased sequence — each step is its own `chuya-frontend` case:

1. **Runtime error capture (Tier 1 — do first, done this session):** `window.onerror` + `unhandledrejection` handlers in `resources/js/app.ts`, readable via Boost `browser-logs`. Near-zero effort, immediate QA value for the Verifier phase.

2. **Component/interaction tests (Tier 2):** Introduce **Vitest + @testing-library/vue** targeting high-risk components first — order forms (Vee-Validate + Zod), TanStack data tables, anything touching the `tablet-api.contract` intent-only rule. Add a CI job alongside the existing lint/typecheck.

3. **Visual regression (Tier 2 — the "UI accuracy checker"):** Playwright + `toHaveScreenshot` at tablet viewport; diff against baselines. Add CI visual job non-blocking first, then gating. Design tokens live in `resources/css/app.css`, so a visual baseline is the practical accuracy oracle.

4. **Accessibility (Tier 2):** `eslint-plugin-vuejs-accessibility` + `axe-playwright` for contrast/ARIA/keyboard-nav.

5. **Contract-linked UI check (Tier 2):** Automated assertion that the tablet UI sends intent-only payloads (pairs with the `pinia-state-audit` and `nuxt-pwa-flow` skills).

6. **Datadog RUM — deferred:** Once the Pi stack ships telemetry, Datadog RUM gives real-user UI error/perf monitoring in prod.

**Tablet PWA work** lands in its sibling repo when in scope; `pwa-ci.yml` is already prepared.

---

## Cross-cutting guardrails

- Tools/tests are evidence, **not** governance — Tier-3 (auth, order state, printing, Reverb) still needs Claude Code specialists + `contracts/*.md`.
- One source of truth: markdown `docs/` + case files. Obsidian frontmatter **mirrors** Run State; GDocs **mirror** markdown — neither becomes authoritative.
- Least privilege: Boost Tinker off, never Boost in prod, Datadog read+scoped, MCP via OAuth, staging DB sanitized, secrets never in chat/Git.
- Every improvement item enters `state/QUEUE.md` as a case with Bucket + tier + specialist; none bypass the sequence.
- Don't duplicate mature docs; don't double-run Superpowers + Verifier; clean duplicate Context7 MCP entries; keep Obsidian Git `autoPush: false`.
- **Datadog stays deferred** until the Pi stack actually ships telemetry. Don't wire it into hooks yet.
- Reconfirm the critical open items before go-live: broadcast-channel auth hardening (`admin.print`/`service-requests` return `true` to all), Print-Bridge ACK-backlog TTL, polling watermark loss (SPEC_DELTA §4).

---

## Consolidated prioritized roadmap

**Quick wins (Tier 1, days):**
- ~~Fix `.mcp.json`~~ — already done.
- Add global UI runtime error handler (done this session — see `resources/js/app.ts`).
- Adopt Context7 `docs-researcher` + Boost `search-docs` as standard Tier-2 pre-edit step.
- Publish the delivery dashboard (`docs/business/WOOSOO_DELIVERY_DASHBOARD.md`).

**Medium (Tier 2, weeks):**
- WSL staging mirror (Sail + sanitized schema) — [[cases/infra-case-011-wsl-staging-mirror]].
- Vitest component tests on high-risk components + CI job.
- Run State → case-frontmatter mirror; reconcile Superpowers vs Verifier in `USAGE_GUIDE.md`.
- Doc gap-fill batch 1: versioning/CHANGELOG policy, state-machine + sequence diagrams; GDocs mirror for BRD roll-up + user manual + handover.

**Larger / deferred:**
- Playwright + visual-regression UI checker + a11y in CI.
- Doc gap-fill batch 2: API versioning/deprecation + served OpenAPI, troubleshooting trees, in-app guides, ecosystem BRD roll-up.
- Datadog: instrument Pi stack → then wire into `verify`/`intake` hooks, `/ddtoolsets` scoping, RUM for UI.

---

## Vault links

- Program case: [[cases/plt-case-tooling-improvement-program]]
- WSL staging case: [[cases/infra-case-011-wsl-staging-mirror]]
- Delivery dashboard: [[business/WOOSOO_DELIVERY_DASHBOARD]]
- Roadmap: [[WOOSOO_ROADMAP_REVIEW]]
- Spec delta (cost source): [[business/WOOSOO_SPEC_DELTA]]
- Docs hub: [[DOCS_HUB]]
