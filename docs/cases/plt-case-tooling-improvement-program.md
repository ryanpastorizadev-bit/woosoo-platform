---
status: canonical
last_reviewed: 2026-06-14
scope: ecosystem
---

# CASE: plt-case-tooling-improvement-program

Umbrella / program case capturing the Cursor-tooling + delivery-improvement strategy
(5 threads). This case is the **planning + handoff record**; each buildable item below is a
**sub-case** triaged through the normal sequence in its own app scope. Authored on the platform
side, to be **implemented locally in Cursor**.

## Run State
- task_slug: plt-case-tooling-improvement-program
- tier: 2
- branch: claude/kind-pascal-Or6Tw
- status: BLOCKED
- last_completed_agent: contrarian
- next_agent: specialist:<per sub-case>
- active_runner: cursor
- interrupted: true
- interrupt_reason: manual-handoff
- updated: 2026-06-14 04:50

## Handoff
- **Phase in progress:** planning complete; implementation moved to local Cursor as spawned sub-cases.
- **Done so far:** 4 codebase scans (orchestration layer, nexus app, docs inventory, UI/test inventory) + delivery-data extraction; full strategy across 5 threads; populated delivery-dashboard figures.
- **Exact next action:** triage the sub-cases in the table under "Proposed Fix" into `state/QUEUE.md` (Bucket B/C as noted) and run each through `Contrarian → Specialist → Verifier → scribe → Executioner`. Start with the Tier-1 quick wins.
- **Working-tree state:** this case file + one `state/QUEUE.md` row. No app code touched.
- **Risks / do-not-redo:**
  - Fix `woosoo-nexus/.mcp.json` (`cwd: woosoo-nexus/` + `--env=local`) — Boost self-disables at `APP_ENV=production`; this is the one known wiring bug.
  - Stand up the **WSL staging mirror** (Sail/local MySQL, **sanitized — no real customer data**) before relying on Boost DB tools. MCP runs client-side; **never** point Boost at the live Pi prod DB; Boost stays off the Pi.
  - Docs are **mature** → Thread C is **gap-fill, not rebuild**. Markdown stays canonical; GDocs/Sheet are one-way mirrors stamped "do not edit here."
  - Frontend has **zero UI tests** → build order: runtime error-handler → Vitest → Playwright+visual → a11y; CI jobs non-blocking first, then gating.
  - **Datadog stays deferred** until the Pi stack ships telemetry — do not wire it into hooks yet.
  - Reconcile **Superpowers vs Verifier** — one runs the proof command per task; don't double-run the suite.
  - Dashboard: forward cost/effort numbers are **estimates — confirm before sharing**; delivered ₱ figures (₱375k billed / ₱875k fair value / ~₱500k absorbed) are authoritative from `WOOSOO_SPEC_DELTA.md`.
  - Pre-go-live criticals to reconfirm (SPEC_DELTA §4): broadcast-channel auth hardening, Print-Bridge ACK-backlog TTL, polling watermark loss.

## Tier
2 (program/coordination + docs). Individual sub-cases carry their own tier — several are Tier 3
(auth hardening, print pipeline, immutable-image) and must use the full deep-Contrarian chain.

## Branch
claude/kind-pascal-Or6Tw (planning artifact). Sub-cases branch per their own app/scope.

## Problem
Five Cursor tools were installed (Datadog, Obsidian, Laravel Boost, Context7, Superpowers) and
the operator asked how to maximize productivity across orchestration, workflow, automation, QA,
and token/context mitigation — then expanded scope to: MCP topology (Pi vs WSL), a stakeholder/
SDLC documentation program, an automated UI-accuracy checker, and a delivery/progress dashboard
(per-repo %, feature list, time/resource + cost).

## Contrarian Review
This is an **epic, not a single task** → `SPLIT_REQUIRED` into per-app, per-tier sub-cases; no app
code is changed under this umbrella case. The five tools are **context/evidence providers for the
Specialist and Verifier phases** — they do not relax Tier-3 governance or the 6 `contracts/`, and
nothing forks the single source of truth (case files). Decisions locked with the operator:
Datadog **deferred** (not instrumented); docs **markdown-canonical + Google Docs/Sheet mirror**;
docs depth **gap-fill** (existing docs are mature); MCP topology **WSL staging mirror**.

## Success Criterion
Done when every sub-case below is an entry in `state/QUEUE.md` with a Bucket, tier, and specialist,
and the two strategy artifacts (improvement strategy doc + delivery dashboard) are published — each
buildable item then proceeds through its own Executioner gate.

## Investigation
Four read-only scans (this session):
- **Orchestration layer:** 4-agent sequence, hooks, case files, `state/`, 6 contracts, Obsidian vault, deploy scripts — mature and resume-safe.
- **woosoo-nexus:** Laravel 12, Boost MCP via `artisan boost:mcp`, 87 test files (447/447 green), Tier-3 domains (order state, Sanctum, print pipeline, Reverb), CI (tests/lint/build).
- **Docs inventory:** already mature — per-app BRDs, `API_MAP.md`+`openapi.json`+per-controller docs, `END_TO_END_WORKFLOW.md`, operator/handover manuals (+`.docx`), process/product/user SDLC split. Gaps: unified versioning/CHANGELOG, visual diagrams, troubleshooting trees, in-app guides, API-versioning policy, 1-page quickstart, ecosystem BRD roll-up.
- **UI/test inventory:** strong Vite/TS/ESLint/Tailwind-v4 infra; **zero** UI tests (no Vitest/Playwright/visual/a11y), no global runtime error handler. Tablet PWA is a sibling repo, not cloned here.

## Root Cause
N/A (opportunity/gap analysis, not a defect). The system is strong; the gaps are: dev-DB-aware
tooling (staging mirror), UI test coverage, a handful of stakeholder docs, and a single visible
progress/cost view.

## Proposed Fix
Five threads (full detail in the session strategy / plan). Sub-case breakdown to triage:

| Sub-case (suggested slug) | Thread | App / scope | Tier | Bucket | Note |
|---|---|---|---|---|---|
| `infra-case-mcp-boost-env-fix` | B | woosoo-nexus | 1 | B | `.mcp.json` `cwd` + `--env=local` |
| `infra-case-wsl-staging-mirror` | B | woosoo-platform/infra | 2 | B | Sail/local MySQL, sanitized schema |
| `nex-case-ui-runtime-error-capture` | D | woosoo-nexus UI | 2 | B | `window.onerror`/`unhandledrejection` → Boost `browser-logs` |
| `nex-case-ui-component-tests` | D | woosoo-nexus UI | 2 | B | Vitest + @testing-library/vue, high-risk components |
| `nex-case-ui-visual-regression` | D | woosoo-nexus UI | 2 | C | Playwright + screenshot baselines (tablet viewport) + a11y |
| `plt-case-tooling-integration` | A | woosoo-platform | 2 | C | `docs-researcher`/Boost search-docs as Tier-2 pre-edit step; session-start hook; cases.base; Run State→frontmatter mirror; reconcile Superpowers vs Verifier |
| `scribe-case-docs-gapfill-b1` | C | docs | 2 | C | versioning/CHANGELOG policy, state-machine + sequence diagrams |
| `scribe-case-docs-gapfill-b2` | C | docs | 2 | C | API-versioning/deprecation + served OpenAPI, troubleshooting trees, in-app guides, ecosystem BRD roll-up |
| `scribe-case-gdocs-mirror` | C | docs | 1 | C | one-way md→Google Docs mirror for stakeholder subset |
| `plt-case-delivery-dashboard` | E | woosoo-platform | 1 | C | publish dashboard + Google Sheet mirror |
| `nex-case-broadcast-auth-hardening` | (crit) | woosoo-nexus | 3 | A/B | SPEC_DELTA §4 critical — re-triage independently |
| (deferred) Datadog wiring | A/D | ecosystem | — | C | only after Pi stack is instrumented |

**Delivery dashboard (Thread E) starting figures** — to publish in `docs/business/WOOSOO_DELIVERY_DASHBOARD.md` (markdown canonical) + Google Sheet mirror:
- **vs original spec:** ≈80% (10/13 delivered incl. KDS→Print-Bridge substitution; 2 partial; 2 not delivered: offline queue+sync, QR access).
- **vs roadmap:** Bucket A 100% cleared; Bucket B = code-done/Pi-ops-pending; Bucket C deferred by design; 40+ APPROVED cases in DONE/QUEUE.
- **production readiness:** ≈40–50% (gated on Pi hardware ops + 3-table smoke).
- **verified/tested:** backend high (nexus 447, tablet 408, bridge 104–108) / UI ~0% — show as split bar.
- **cost (delivered, authoritative):** ₱350k contract + ₱25k Pi = **₱375k billed**; **₱875k** fair value; **~₱500k** absorbed. **Remaining (estimate — confirm):** CO-001 KDS re-add ₱100k + spec-gap closures + criticals + this improvement program.

## Files Changed
- `docs/cases/plt-case-tooling-improvement-program.md` — new (this file).
- `state/QUEUE.md` — one Bucket C program row.
- `docs/WOOSOO_IMPROVEMENT_STRATEGY_2026-06-07.md` — new (threads A–D strategy).
- `docs/business/WOOSOO_DELIVERY_DASHBOARD.md` — new (thread E populated dashboard).

## Verification
- Per `documentation-truth-audit`: every path/hook/skill/script/command referenced exists; dashboard %/₱ trace to named sources (`WOOSOO_SPEC_DELTA.md`, `QUEUE.md`/`DONE.md`, deploy gates); forward numbers labeled *estimate*.
- No Tier-3 governance relaxed; no contract contradicted; all buildable items expressed as queued sub-cases.
- Reading test: an operator can find, per thread, the next action + Bucket/case + axis in under a minute.

## Documentation Sync
This case file is the documentation artifact. The strategy doc
(`docs/WOOSOO_IMPROVEMENT_STRATEGY_2026-06-07.md`, threads A–D) and the populated dashboard
(`docs/business/WOOSOO_DELIVERY_DASHBOARD.md`, thread E) were authored alongside this case
(2026-06-14). The Google Sheet mirror and the remaining gap-fill docs are deferred to their
sub-cases (`plt-case-delivery-dashboard`, `scribe-case-*`).

## Executioner Verdict
N/A — planning/handoff case. Verdicts are rendered per sub-case as they complete locally.

## Remaining Risks
- Sub-case sprawl: keep each within its app scope; `SPLIT_REQUIRED` if any single case touches >1 app.
- Estimate accuracy: forward cost/effort needs an explicit sizing pass before any stakeholder sharing.
- Tooling drift: MCP reconnect instability observed this session — verify `.mcp.json` boots Boost locally before depending on it.
