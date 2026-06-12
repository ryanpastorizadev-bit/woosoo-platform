---
status: canonical
last_reviewed: 2026-06-10
scope: woosoo-nexus
---

# Admin Shell + Operator Pages — Design Document

**Date:** 2026-06-10  
**Case:** [[nex-case-025-admin-shell-migration]]  
**App:** woosoo-nexus (Tier 2)  
**Branch:** `agent/nex-case-025-admin-shell-migration`  
**Deferred:** All other `IMPLEMENTATION_HANDOVER.md` pages → future [[nex-case-026-admin-page-alignment]]

---

## Goal

Close [[nex-case-025-admin-shell-migration]] by:

1. Verifying the custom admin shell against its acceptance checklist
2. Importing useful assets from the `Woosoo Admin (3).zip` handoff bundle (docs only)
3. **Visual-aligning four operator-critical pages** the user specified: Orders, Devices, Packages (Dining Tiers), Tablet Categories

Visual-only on pages — no routing, API, Echo/WebSocket logic, or data-model changes.

---

## Context

The zip handoff (`handoff/step-1` … `step-4`, `IMPLEMENTATION_HANDOVER.md`) targets the old shadcn-sidebar architecture. The branch already implements a replacement shell:

| Concern | Implementation |
|---------|----------------|
| 224px dark sidebar | `AdminSidebar.vue` + `AdminSidebarContent.vue` |
| 52px topbar + right cluster | `AdminTopbar.vue` |
| Nav sections + crumbs | `admin-shell.ts` |
| Live badges | `AdminShellBadgeService` + `navBadges` in `HandleInertiaRequests` |
| Theme persistence | `useNexusTheme.ts` + `app.blade.php` boot script |
| Flat content layout | `AppContentLayout.vue` (glass wrapper removed) |
| Configuration hub cards | `Configuration.vue` |

Step 3 component theming is already applied in `resources/js/components/ui/`. Step 4 top pages are largely aligned. **Applying zip Steps 1–2 would regress the shell.**

---

## Approaches considered

| Approach | Summary | Verdict |
|----------|---------|---------|
| **A — Big-bang unified** | Shell + all handover pages in one branch | Rejected — too large |
| **B — Shell + operator page wave** | Shell gate, zip docs, four named pages on same branch | **Selected** |
| **C — Shell-only** | Defer all pages to nex-case-026 | Rejected — user named required pages |

---

## In scope

### 1. Shell acceptance verification

Manual + automated checks against the case acceptance criteria:

- [ ] Sidebar 224px (`w-56`), always dark, WOOSOO/NEXUS branding
- [ ] Nav groups: Main / Analytics / Configuration footer
- [ ] Live `orders` and `devices` badges (not hardcoded; change with DB state)
- [ ] Branches nav item visually dimmed (`dim: true`)
- [ ] Active nav: amber text + 2px left rail at `left: -10px`
- [ ] Topbar 52px; title + crumb trail when depth > 1
- [ ] Right cluster order: HQ → Search → theme → refresh → bell → avatar
- [ ] `nexus-theme` persists across reload (light / dark / system if supported)
- [ ] Accessibility, Event Logs, KDS, Media, Legacy Packages reachable via Configuration hub only (not in sidebar)
- [ ] Mobile: hamburger opens Sheet drawer; desktop fixed sidebar
- [ ] `php artisan test` passes (including `AdminShellBadgeServiceTest`)
- [ ] `npm run typecheck && npm run lint && npm run build` passes

Browser QA URL: `https://192.168.100.7` — both light and dark themes.

### 2. Zip handoff doc import (no `resources/` code copies)

Copy from `Woosoo Admin (3).zip` into `woosoo-nexus/handoff/`:

| Asset | Action |
|-------|--------|
| `START_HERE.md` | Add with superseded Steps 1–2 callout at top |
| `specs/*.html` + `series.css` | Add under `handoff/specs/` for design QA |
| `IMPLEMENTATION_HANDOVER.md` | Diff against repo copy; merge newer page notes |

Update `woosoo-nexus/handoff/README.md`:

> [!warning] Steps 1–2 superseded
> Do **not** run the quick-apply script for Steps 1–2. Shell is implemented by [[nex-case-025-admin-shell-migration]] (`AdminShell` / `AdminSidebar` / `AdminTopbar`). Steps 3–4 and `IMPLEMENTATION_HANDOVER.md` remain valid references for page work in [[nex-case-026-admin-page-alignment]].

### 3. Operator page wave (user-specified)

Apply handover patterns on the **flat** `AppContentLayout` (hero card + table/card wrappers + `woosoo-*` tokens). Do **not** copy zip Step 2 glass wrapper.

| User label | File | Route | Current state | Planned work |
|------------|------|-------|---------------|--------------|
| **Orders** | [`pages/Orders/Index.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/Orders/Index.vue) | `orders.index` | Step 4 status pills + badges done | Add hero card (match Devices); `space-y-5`; fix `print-highlight` scoped CSS (`rgb(34,197,94)` → brand green); browser QA Echo pill + tabs (no script changes) |
| **Devices** | [`pages/Devices/Index.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/Devices/Index.vue) | `devices.index` | Hero + fleet pills aligned | Verify against zip `step-4/Devices_Index.vue` + handover; fix any remaining raw hex (`#f6b56d`) → `woosoo-accent` tokens |
| **Packages** | [`pages/package-configs/IndexPackageConfigs.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/package-configs/IndexPackageConfigs.vue) | `package-configs.index` | Hero + tier cards aligned | Replace scattered `#f6b56d` / `#F6B56D` with `woosoo-accent`; price display `font-bold` → `font-semibold` (brand type scale) |
| **Tablet configs** | [`pages/tablet-categories/IndexTabletCategories.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/tablet-categories/IndexTabletCategories.vue) | `tablet-categories.index` | Hero + two-pane layout aligned | Replace selection/highlight raw hex (`#2a1e0c`, `#F6B56D`, `#f6b56d`) with shell token classes or `woosoo-accent` equivalents |

> **Not in wave:** [`pages/Packages/Index.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/Packages/Index.vue) (Legacy / Krypton Modifiers via Configuration hub) — handover §13 targets this file separately; link from Dining Tiers page remains unchanged.

**Page acceptance (each of the four):**

- [ ] Hero section: `rounded-[26px] border border-black/8 bg-card/92 …` with section label + `font-header` title
- [ ] Wrapper: `space-y-5` (no redundant `p-6` / `max-w-[1600px]` outer wrap)
- [ ] No raw Tailwind status colors (`emerald-*`, `yellow-*`, `blue-600`, `rose-*`)
- [ ] No raw `#f6b56d` hex where `woosoo-accent` / `woosoo-primary-dark` tokens exist
- [ ] Light + dark mode: borders visible, amber tints correct
- [ ] Behaviour unchanged (row click, dialogs, drag-reorder, Echo events on Orders)

### 4. Case close-out

- Mark shell + page acceptance checklists in [[nex-case-025-admin-shell-migration]]
- Set `status: COMPLETE` after Verifier PASS + Executioner APPROVED
- Cross-link [[nex-case-012-admin-ui-prototype-impl]] as OBE for shell scope
- Queue [[nex-case-026-admin-page-alignment]] for remaining handover pages (reports, POS, Users, etc.)

---

## Out of scope

- Copying zip `step-1/` or `step-2/` files into `resources/` (regresses shell)
- Blind copy of zip `step-4/` wholesale — use as **diff reference** only; merge class changes manually
- [`pages/Packages/Index.vue`](e:/Projects/woosoo-platform/woosoo-nexus/resources/js/pages/Packages/Index.vue) (legacy modifiers)
- All other `IMPLEMENTATION_HANDOVER.md` pages
- Restoring `AppSidebar.vue`, `NavMain.vue`, or `AppSidebarHeader.vue`
- Re-adding glass content wrapper to `AppContentLayout.vue`
- Order-state, auth, API, or contract changes
- KDS `Display.vue` (guard rail G3)

---

## Guard rails (unchanged from case)

- **G1:** Do not modify `layouts/AppLayout.vue` (flash + Toaster)
- **G2:** Shell wiring lives in `AppSidebarLayout.vue` → `AdminShell`
- **G3:** Do not touch KDS `Display.vue`
- **G4:** Mobile drawer uses shadcn `Sheet`

---

## Testing strategy

| Layer | Command / action |
|-------|------------------|
| PHP | `php artisan test` from `woosoo-nexus/` |
| Frontend | `npm run typecheck && npm run lint && npm run build` |
| Badge service | `AdminShellBadgeServiceTest` (6 tests) |
| Manual — shell | Sidebar nav, badges, theme toggle, Configuration hub links, mobile drawer |
| Manual — pages | Orders, Devices, Packages, Tablet Categories in light + dark |
| Regression | Orders Echo/WebSocket live; device row + security dialog; tablet category drag-reorder |

Canonical gate: `scripts/pre-merge-check.ps1 -App woosoo-nexus` from platform root.

---

## Rollback

Restore branch to pre-close-out commit; shell components remain — doc import is additive and low risk. If shell QA finds defects, fix forward on same branch before marking COMPLETE.

---

## Follow-on (nex-case-026 sketch)

Remaining `IMPLEMENTATION_HANDOVER.md` pages not in the operator wave:

1. Reports hub + sub-pages
2. Service Requests, Menus, POS
3. Users, Monitoring, legacy Packages, branches, roles
