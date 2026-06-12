# Admin Shell Migration — Design Document
**Date:** 2026-06-10  
**Case:** [[nex-case-025-admin-shell-migration]]  
**App:** woosoo-nexus (Tier 2)  
**Branch:** `agent/nex-case-025-admin-shell-migration`

---

## Goal

Replace the partial shadcn-sidebar STEP 1 shell with a spec-faithful admin shell:
- 224px always-dark sidebar
- 52px topbar with crumbs + right cluster
- Design tokens (`--bg0`…`--accfg`) + JetBrains Mono font
- `data-theme` / `nexus-theme` localStorage persistence
- Live nav badges (orders, devices) from backend
- Non-spec routes hidden from sidebar but reachable via Configuration hub

---

## Why not customize the shadcn sidebar?

`resources/js/components/ui/sidebar/utils.ts` hardcodes `SIDEBAR_WIDTH = '16rem'` (256px). The spec requires 224px. Building dedicated shell components avoids wrestling with the shadcn internals.

---

## Architecture

### New files

| Path | Purpose |
|------|---------|
| `resources/css/nexus-shell.css` | Shell-scoped CSS tokens (`--bg0`, `--accfg`, etc.) |
| `resources/js/composables/useNexusTheme.ts` | `data-theme` + `nexus-theme` localStorage + `.dark` sync |
| `resources/js/config/admin-shell.ts` | `NAV_SECTIONS`, `ROUTE_CRUMBS`, active-route matcher |
| `resources/js/components/shell/NexusNavIcon.vue` | Literal SVG paths for all nav icons |
| `resources/js/components/shell/AdminShell.vue` | Flex-row container: fixed sidebar + main column |
| `resources/js/components/shell/AdminSidebar.vue` | 224px desktop; shadcn Sheet mobile; nav + footer |
| `resources/js/components/shell/AdminTopbar.vue` | 52px topbar: title/crumb + right cluster |

### Modified files

| Path | Change |
|------|--------|
| `resources/css/app.css` | `@import './nexus-shell.css'` |
| `resources/views/app.blade.php` | Boot script: read `nexus-theme` first; add JetBrains Mono font |
| `resources/js/layouts/app/AppSidebarLayout.vue` | Replace AppShell/AppSidebar/AppSidebarHeader with AdminShell + AdminTopbar |
| `resources/js/layouts/AppContentLayout.vue` | Remove glass card; flat `--bg0` surface |
| `resources/js/pages/Configuration.vue` | Add 5 new hub cards |
| `app/Http/Middleware/HandleInertiaRequests.php` | Add `navBadges` shared prop |

### New PHP files

| Path | Purpose |
|------|---------|
| `app/Services/Admin/AdminShellBadgeService.php` | Live badge counts |
| `tests/Feature/Admin/AdminShellBadgeServiceTest.php` | Badge service test |

### Deprecated (deleted after QA)

- `resources/js/components/AppSidebar.vue`
- `resources/js/components/AppSidebarHeader.vue`
- `resources/js/components/NavMain.vue`

---

## Design tokens

```css
/* Sidebar — always dark regardless of page theme */
--shell-bg:      hsl(20 5% 10%);    /* #1a1816 */
--shell-border:  rgba(255,255,255,0.07);
--shell-fg:      hsl(0 0% 82%);
--shell-dim:     hsl(0 0% 44%);     /* dimmed items (Branches) */
--shell-active:  hsl(30 80% 66%);   /* amber #f6b56d */
--shell-hover:   rgba(255,255,255,0.06);

/* Topbar — follows page theme */
--topbar-h:      52px;
--topbar-bg:     var(--background);
--topbar-border: var(--border);
```

---

## Nav sections (spec)

### Main
Dashboard · Orders · POS · Menus · Packages · Tablet Categories · Devices · User Management · Service Requests

### Analytics
Reports (single entry → sub-reports on the Reports page)

### Configuration (footer)
Branches (dim) · Access Control · Configuration (hub link)

---

## Badge semantics

| Badge | Query | Note |
|-------|-------|------|
| `orders` | `DeviceOrder` WHERE `status IN ('pending','confirmed','in_progress')` | Matches `DashboardController::apiStats()` |
| `devices` | `Device` WHERE `last_seen_at IS NULL OR last_seen_at < now() - 5min` | Named constant `OFFLINE_THRESHOLD_MINUTES = 5` |

---

## Theme bridge

`useNexusTheme.ts`:
1. Reads `localStorage('nexus-theme')` → `'light' | 'dark' | 'system'`
2. Falls back to `localStorage('appearance')` for backwards compatibility
3. Applies `document.documentElement.setAttribute('data-theme', resolved)`
4. Syncs `.dark` class for Tailwind `@custom-variant dark (&:is(.dark *))`

`app.blade.php` inline boot script updated to call same logic server-side (blade cookie read).

---

## Configuration hub — new cards

| Card | Route name | Icon |
|------|-----------|------|
| Accessibility | `accessibility.index` | ShieldCheck |
| Event Logs | `event-logs.index` | FileText |
| Kitchen Display | `kds.display` | Monitor |
| Media Library | `media.index` | Image |
| Legacy Packages | `packages.index` | Package |

---

## Mobile behavior

`< md` breakpoint: `AdminSidebar` content renders inside a shadcn `Sheet` (slide-in drawer). Hamburger menu button lives in `AdminTopbar`.  
`>= md`: fixed 224px sidebar, no drawer.

---

## Acceptance criteria

- [ ] Sidebar is 224px, always dark, shows WOOSOO/NEXUS branding
- [ ] Nav group order matches spec
- [ ] Live badges are not hardcoded (change on real DB state)
- [ ] Branches item is visually dimmed
- [ ] Active item shows amber color + 2px left rail at `left: -10px`
- [ ] Topbar is 52px with title, crumb trail, and right cluster
- [ ] Right cluster order: HQ → Search → theme toggle → refresh → bell → avatar
- [ ] `nexus-theme` persists across page reloads
- [ ] Non-spec routes (Accessibility, Event Logs, KDS, Media, Legacy Packages) reachable via Configuration hub
- [ ] `php artisan test` passes
- [ ] `npm run typecheck && npm run lint && npm run build` passes
