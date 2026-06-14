---
status: canonical
last_reviewed: 2026-06-14
scope: ecosystem
---

# Woosoo Improvement Strategy — Tooling, MCP, Docs, UI

**Prepared:** 2026-06-14 · **Program case:** [`cases/plt-case-tooling-improvement-program.md`](cases/plt-case-tooling-improvement-program.md) · **Dashboard:** [`business/WOOSOO_DELIVERY_DASHBOARD.md`](business/WOOSOO_DELIVERY_DASHBOARD.md)

This document maps the Cursor tools installed locally (Datadog, Obsidian, Laravel Boost,
Context7, Superpowers) and four delivery improvements onto the existing agent orchestration
layer. It is a **strategy + backlog**: every buildable item is a sub-case routed through the
normal sequence (`Contrarian → Specialist → Verifier → scribe → Executioner`) in its own app
scope. Thread E (the delivery/progress dashboard) lives in its own document.

## Guiding principle

> The five tools are **context and evidence providers for the Specialist and Verifier phases**.
> They make the agent better-informed and better-proven; they do **not** make decisions, relax
> Tier-3 governance, or replace the 6 `contracts/`. The single source of truth stays the case
> files — tools surface and feed them, never fork them. Obsidian and Google Docs/Sheets are
> read/mirror surfaces over markdown that stays canonical.

## Thread A — Cursor tooling, by phase and axis

| Tool | Phase it serves | Wired via | Main axis |
|---|---|---|---|
| **Context7** | Specialist pre-edit research | `docs-researcher` subagent; `execute`/`pre-edit-gate` hooks | Token mitigation + correctness |
| **Laravel Boost** | Specialist + Verifier (nexus) | `.mcp.json` (`cwd`+`--env=local`); session start; `laravel-api-change`/`sanctum-auth-debug` skills | QA + token mitigation |
| **Superpowers** | Verifier / Executioner gate | `test-verification` skill; `verify` hook | QA (evidence before COMPLETE) |
| **Obsidian** | Operator orchestration (human) | case files, `state/`, `OPERATOR_HOME.md`, Bases | Orchestration/workflow |
| **Datadog** | Verifier (post-deploy) + intake — **deferred** | `verify`/`intake` hooks once instrumented | QA + orchestration (later) |

**By axis:**

- **Token/context mitigation.** Delegate library/log research to subagents (`docs-researcher`,
  Boost `search-docs`); only conclusions return into a case's `## Investigation`. Scope MCP per
  app (`/ddtoolsets` to logs+alerting; Boost Tinker off). Right-tool-first avoids wrong-version
  correction loops. Feed checkpoints, never dump raw output into case files. Respect per-tier
  file budgets (≤5 / ≤12 / ≤25).
- **QA / verification.** Map Superpowers onto the **existing** Verifier — one proof command per
  task, raw output into `## Verification`; full `verification-before-completion` before
  merge/handoff, lighter scoped proof for Tier 1. Use Boost `database-schema`/`ApplicationInfo`
  for version- and schema-correct nexus work when the dev DB is reachable.
- **Orchestration / workflow.** Obsidian as UI over the agent layer: section embeds in
  `OPERATOR_HOME.md`, a `docs/meta/cases.base` "active cases" dashboard, and (proposed) mirroring
  `run_status`/`next_agent`/`tier`/`app` from `## Run State` into case frontmatter so Bases/
  Dataview can answer "what's active?" without parsing bodies. `## Run State` stays authoritative.
- **Automation.** Session-start hook auto-runs Boost `ApplicationInfo` for nexus; `pre-edit-gate`/
  `post-edit-review` hooks ask "did you search-docs/Context7 the API?" and require proof output;
  CI stays the merge gate.

## Thread B — MCP topology: WSL staging mirror

MCP servers run **client-side where Cursor runs** (WSL/local), not "on the Pi."

- **Boost never runs on the Pi** — it is `require-dev` and self-disables at `APP_ENV=production`.
- **Datadog & Context7 are cloud-query** — location-agnostic; run from WSL/Cursor, OAuth.
- **Stand up a WSL staging mirror** (Laravel Sail or local MySQL seeded via migrations +
  `pos:setup-payment-trigger`, **sanitized — no real customer data**) so Boost
  `database-schema`/`database-query` work. Do **not** point Boost at the live Pi production DB
  (risky, often unreachable; already observed returning empty schema from the Windows shell).
- The same WSL box hosts the full Pest suite, Vitest, and Playwright (Thread D) off-prod.
- Fix `woosoo-nexus/.mcp.json`: `cwd` → `woosoo-nexus/`, add `--env=local` so Boost boots.
- Guardrails: separate staging `.env`; secrets out of chat/Git; honor `pos-db.contract.md`
  (no destructive POS writes, no schema assumptions).

## Thread C — Documentation: gap-fill + Google Docs mirror

Existing docs are mature (per-app BRDs, `API_MAP.md`+`openapi.json`+per-controller docs,
`END_TO_END_WORKFLOW.md`, operator/handover manuals, process/product/user SDLC split). Fill the
strategic gaps (each a `scribe` sub-case):

1. **Unified versioning + CHANGELOG policy** (only nexus has a CHANGELOG) — semver, cadence,
   cross-repo sync, per-repo CHANGELOGs.
2. **Visual diagrams** — order **state-machine diagram** (from `order-state.contract.md`) and
   **sequence diagrams** for the E2E transaction (tablet → nexus → POS → print-bridge → printer).
3. **API versioning/deprecation strategy** + optionally serve `openapi.json` via Redoc/Swagger
   UI as the live API mapper.
4. **Troubleshooting decision trees** ("print failed → check X → Y"; "419 on login → …").
5. **1-page operator quickstart** + populate the pending in-app guides
   (`resources/docs/guides/{admin,tablet,relay}/`).
6. **Ecosystem-level BRD roll-up + handover checklist** (synthesize the per-app BRDs).
7. **Timeline/roadmap** — fold into `WOOSOO_ROADMAP_REVIEW.md`.

**Google Docs mirror:** markdown in `docs/` stays canonical and Git-versioned; a one-way export
mirrors the stakeholder-facing subset (BRD roll-up, user/operator manual, restaurant-ops handover,
ecosystem overview, timeline) to Google Docs, stamped "generated from `docs/…` — do not edit
here." Extends the existing `software-development/build_docx.py` md→docx idea.

## Thread D — UI accuracy / automated checker

Strong build/lint/type infra; **zero** UI tests today. Phased (each a UI sub-case):

1. **Quick win — runtime error capture.** Global `window.onerror` + `unhandledrejection` in
   `resources/js/bootstrap.js`/`app.ts`, surfaced to toasts and readable via Boost `browser-logs`.
2. **Component/interaction tests.** Vitest + @testing-library/vue on high-risk components first
   (order forms with Vee-Validate+Zod, TanStack tables, intent-only payload paths). CI job.
3. **Automated UI checker — Playwright + visual regression.** Screenshot snapshots at **tablet
   viewport**, diffed against baselines (`toHaveScreenshot`, or Percy/Chromatic for hosted
   review). Design tokens live in `resources/css/app.css`, so a visual baseline is the practical
   accuracy oracle. CI visual job (non-blocking first, then gating).
4. **Accessibility.** `eslint-plugin-vuejs-accessibility` + `axe-playwright`.
5. **Contract-linked UI check.** Assert the tablet UI sends **intent-only** payloads (pairs with
   `pinia-state-audit` / `nuxt-pwa-flow` skills).
6. **Deferred (Datadog).** RUM for real-user UI error/perf monitoring once instrumented.

The tablet PWA work lands in its sibling repo when in scope; `pwa-ci.yml` is already prepared.

## Cross-cutting guardrails

- Tools/tests are evidence, **not** governance — Tier-3 (auth, order state, printing, Reverb)
  still needs the full chain + `contracts/*.md`.
- One source of truth: markdown `docs/` + case files. Obsidian frontmatter **mirrors** Run State;
  GDocs/Sheets **mirror** markdown — neither becomes authoritative.
- Least privilege: Boost Tinker off, never Boost in prod, Datadog read+scoped, MCP via OAuth,
  staging DB sanitized, secrets never in chat/Git.
- Every improvement item enters `state/QUEUE.md` as a sub-case with Bucket + tier + specialist.
- Don't duplicate mature docs; don't double-run Superpowers + Verifier; clean duplicate Context7
  MCP entries; keep Obsidian Git `autoPush: false`.

## Prioritized roadmap

**Quick wins (Tier 1):** `.mcp.json` `cwd`+`--env=local`; global UI runtime error handler →
Boost `browser-logs`; adopt `docs-researcher`/Boost `search-docs` as the standard Tier-2
pre-edit step + clean duplicate Context7 entries; `docs/meta/cases.base`; publish the delivery
dashboard.

**Medium (Tier 2):** WSL staging mirror; Vitest component tests + CI; Run State→frontmatter
mirror + reconcile Superpowers vs Verifier; doc gap-fill batch 1 (versioning, diagrams) + GDocs
mirror for BRD roll-up/user manual/handover.

**Larger / deferred:** Playwright + visual-regression + a11y in CI; doc gap-fill batch 2 (API
versioning, troubleshooting trees, in-app guides, ecosystem BRD roll-up); Datadog — instrument
the Pi stack, then wire into `verify`/`intake`, `/ddtoolsets` scoping, observability line in
`deploy-checklist`, RUM for UI.

## Sub-case map

See the program case [`cases/plt-case-tooling-improvement-program.md`](cases/plt-case-tooling-improvement-program.md)
for the full sub-case breakdown (suggested slugs, app scope, tier, Bucket). Datadog work is
deferred until the Pi stack ships telemetry.

## References

- [`AGENTS.md`](../AGENTS.md) · [`PROTOCOL.md`](../PROTOCOL.md) · [`docs/USAGE_GUIDE.md`](USAGE_GUIDE.md)
- [`contracts/`](../contracts/) — the 6 immutable cross-app contracts
- [`docs/CONTEXT7_GUIDE.md`](CONTEXT7_GUIDE.md) · [`docs/WOOSOO_ROADMAP_REVIEW.md`](WOOSOO_ROADMAP_REVIEW.md)
- [`docs/business/WOOSOO_SPEC_DELTA.md`](business/WOOSOO_SPEC_DELTA.md) — cost & spec-delta source
