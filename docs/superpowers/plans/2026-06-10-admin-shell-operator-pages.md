# Admin Shell + Operator Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close [[nex-case-025-admin-shell-migration]] by verifying the custom admin shell, importing zip handoff docs, and visually aligning Orders, Devices, Packages (Dining Tiers), and Tablet Categories to brand tokens on the flat `AppContentLayout`.

**Architecture:** Shell is already implemented (`AdminShell` / `AdminSidebar` / `AdminTopbar`). Page work applies `IMPLEMENTATION_HANDOVER.md` patterns inside page templates only — no zip Steps 1–2, no glass layout wrapper. Step 4 handoff files are diff references, not blind copies.

**Tech Stack:** Laravel 12, Vue 3 + Inertia, Tailwind, shadcn/ui, woosoo-nexus on branch `agent/nex-case-025-admin-shell-migration`

**Spec:** [`docs/superpowers/specs/2026-06-10-admin-shell-closeout-design.md`](../specs/2026-06-10-admin-shell-closeout-design.md)

---

## File map

| Action | Path | Responsibility |
|--------|------|----------------|
| Verify | `resources/js/components/shell/*.vue` | Shell layout |
| Verify | `resources/js/config/admin-shell.ts` | Nav + crumbs |
| Verify | `app/Services/Admin/AdminShellBadgeService.php` | Live badges |
| Modify | `resources/js/pages/Orders/Index.vue` | Hero + CSS tokens |
| Modify | `resources/js/pages/Devices/Index.vue` | Token cleanup |
| Modify | `resources/js/pages/package-configs/IndexPackageConfigs.vue` | Token + type scale |
| Modify | `resources/js/pages/tablet-categories/IndexTabletCategories.vue` | Selection tokens |
| Import | `woosoo-nexus/handoff/START_HERE.md`, `handoff/specs/*` | Design QA docs |
| Modify | `woosoo-nexus/handoff/README.md` | Steps 1–2 superseded warning |
| Checkpoint | `docs/cases/nex-case-025-admin-shell-migration.md` | Case run state |

---

### Task 1: Import zip handoff docs

**Files:**
- Create: `woosoo-nexus/handoff/START_HERE.md`
- Create: `woosoo-nexus/handoff/specs/` (5 HTML + `series.css`)
- Modify: `woosoo-nexus/handoff/README.md`
- Modify: `woosoo-nexus/handoff/IMPLEMENTATION_HANDOVER.md` (merge zip diff if newer)

- [ ] **Step 1: Copy assets from zip**

Source: `C:\Users\Pc1\Downloads\Woosoo Admin (3).zip` → extract `handoff/START_HERE.md` and `handoff/specs/` into `woosoo-nexus/handoff/`.

- [ ] **Step 2: Add superseded callout to README.md**

Prepend after the title block:

```markdown
> [!warning] Steps 1–2 superseded (2026-06-10)
> Do **not** run the quick-apply script for Steps 1–2. The admin shell is implemented by [[nex-case-025-admin-shell-migration]] (`AdminShell`, `AdminSidebar`, `AdminTopbar`). Steps 3–4 and `IMPLEMENTATION_HANDOVER.md` remain valid for page alignment.
```

- [ ] **Step 3: Diff and merge IMPLEMENTATION_HANDOVER.md**

Compare zip vs repo copy; keep repo version unless zip has newer page notes.

---

### Task 2: Shell acceptance verification

**Files:** Read-only QA on shell components (fix only if checklist fails)

- [ ] **Step 1: Run automated gates**

From `woosoo-nexus/`:

```bash
php artisan test
npm run typecheck && npm run lint && npm run build
```

Expected: all pass (490+ PHPUnit tests; frontend clean).

- [ ] **Step 2: Browser QA shell** at `https://192.168.100.7`

Checklist (light + dark):
- Sidebar 224px, WOOSOO/NEXUS branding, amber active + left rail
- Nav sections: Main / Analytics / Configuration footer; Branches dimmed
- Orders + Devices badges live (not `0` when data exists)
- Topbar cluster: HQ → Search → theme → refresh → bell → avatar
- Theme persists after reload
- Configuration hub has Accessibility, Event Logs, KDS, Media, Legacy Packages — not in sidebar
- Mobile hamburger opens Sheet drawer

- [ ] **Step 3: Fix shell defects only if checklist fails**

Scope: `resources/js/components/shell/`, `admin-shell.ts`, `useNexusTheme.ts` — no page files in this step.

---

### Task 3: Orders page alignment

**Files:**
- Modify: `woosoo-nexus/resources/js/pages/Orders/Index.vue`
- Reference: `woosoo-nexus/handoff/step-4/Orders_Index.vue` (diff only)

- [ ] **Step 1: Add hero card above status pill**

Change outer wrapper from `space-y-4` to `space-y-5`. Insert as first child inside `<AppLayout>`:

```vue
<section class="relative overflow-hidden rounded-[26px] border border-black/8 bg-card/92 px-5 py-6 shadow-sm shadow-black/5 backdrop-blur-sm dark:border-white/10 md:px-6">
  <div class="relative flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
    <div class="space-y-2">
      <span class="inline-flex rounded-full border border-border/70 bg-accent/12 px-3 py-1 text-[11px] font-semibold tracking-[0.22em] text-muted-foreground uppercase">
        Live Operations
      </span>
      <h2 class="font-header text-2xl font-semibold tracking-tight text-foreground sm:text-3xl">
        Orders
      </h2>
      <p class="text-sm text-muted-foreground">
        Live kitchen queue and order history — updates in real time when connected.
      </p>
    </div>
  </div>
</section>
```

Keep WebSocket status pill below hero (already on brand tokens).

- [ ] **Step 2: Fix print-highlight scoped CSS**

Replace raw green RGB in `<style scoped>`:

```css
@keyframes print-highlight {
  0% {
    border-left: 4px solid hsl(142 76% 36%);
    background-color: hsl(142 76% 36% / 0.05);
  }
  100% {
    border-left: 4px solid transparent;
    background-color: transparent;
  }
}
```

(Uses woosoo-green hue; no script/logic changes.)

- [ ] **Step 3: Verify no raw Tailwind status colors remain**

```bash
rg "emerald|yellow-|rose-|blue-600|amber-50" woosoo-nexus/resources/js/pages/Orders/Index.vue
```

Expected: no matches.

- [ ] **Step 4: Rebuild and smoke-test Orders**

```bash
npm run build
```

Browser: Live Orders tab, Echo pill states, order row click → detail sheet, print highlight animation.

---

### Task 4: Devices page verification

**Files:**
- Modify: `woosoo-nexus/resources/js/pages/Devices/Index.vue` (token cleanup only)
- Reference: `woosoo-nexus/handoff/step-4/Devices_Index.vue`

- [ ] **Step 1: Replace raw hex with tokens**

Find/replace in template (not logic):

| From | To |
|------|-----|
| `#f6b56d` / `#F6B56D` in class strings | `woosoo-accent` or `text-woosoo-accent` / `bg-woosoo-accent` as context requires |
| `border-[#f6b56d]/30` | `border-woosoo-accent/30` |
| `bg-[#f6b56d]/10` | `bg-woosoo-accent/10` |

Keep `batteryBg()` inline `#f6b56d` only if no Tailwind token works in JS return string — prefer `'bg-woosoo-accent'` if valid.

- [ ] **Step 2: Confirm layout matches handover**

- Outer wrapper: `space-y-5` only (no `max-w-[1600px]` double-wrap)
- Hero card present
- Fleet table in `rounded-[26px]` card section

- [ ] **Step 3: Browser QA Devices**

Row click → detail sheet; restart/security dialog; sync all; light + dark borders.

---

### Task 5: Packages (Dining Tiers) alignment

**Files:**
- Modify: `woosoo-nexus/resources/js/pages/package-configs/IndexPackageConfigs.vue`

- [ ] **Step 1: Token cleanup**

Replace template hex:

- `from-[#f6b56d]/10` → `from-woosoo-accent/10`
- `dark:from-[#f6b56d]/6` → `dark:from-woosoo-accent/6`
- `text-[#f6b56d]` on price → `text-woosoo-accent font-semibold` (remove `font-bold`)
- `bg-[#f6b56d]` bullet dots → `bg-woosoo-accent`

- [ ] **Step 2: Browser QA Packages**

Create dialog, tier cards grid, "Krypton Modifiers" link still works, light + dark.

---

### Task 6: Tablet Categories alignment

**Files:**
- Modify: `woosoo-nexus/resources/js/pages/tablet-categories/IndexTabletCategories.vue`

- [ ] **Step 1: Replace selection-state hex**

In category list item `:class`:

```vue
'bg-[#2a1e0c] text-[#F6B56D]': selectedId === cat.id,
```

→

```vue
'bg-woosoo-accent/12 text-woosoo-accent border border-woosoo-accent/30': selectedId === cat.id,
```

And drag-over: `border-[#f6b56d]/60` → `border-woosoo-accent/60`

Hero gradient: same `woosoo-accent` replacements as Task 5.

- [ ] **Step 2: Browser QA Tablet Categories**

Drag-reorder, select category, attach/detach menus, featured toggle, light + dark.

---

### Task 7: Hygiene, case checkpoint, handoff

**Files:**
- Modify: `docs/cases/nex-case-025-admin-shell-migration.md`

- [ ] **Step 1: Run code-simplifier** on all touched Vue files (Cursor hygiene gate)

- [ ] **Step 2: Final verification**

From platform root:

```powershell
.\scripts\pre-merge-check.ps1 -App woosoo-nexus
```

- [ ] **Step 3: Update case file**

- Check acceptance criteria (shell + four pages)
- `## Specialist Investigation & Implementation` — page wave summary
- `## Run State` → `next_agent: verifier`, `status: IN_PROGRESS`

Operator commits and runs Verifier / Executioner in Claude Code.

---

## Self-review (plan vs spec)

| Spec requirement | Task |
|------------------|------|
| Shell acceptance | Task 2 |
| Zip doc import | Task 1 |
| Orders page | Task 3 |
| Devices page | Task 4 |
| Packages (package-configs) | Task 5 |
| Tablet categories | Task 6 |
| No zip Steps 1–2 copy | Explicit in architecture |
| Legacy Packages/Index.vue out | Not in file map |
| Verifier gate | Task 7 |

No placeholders. Visual-only — no new PHPUnit tests for Vue templates; regression via existing suite + manual QA.

---

## Execution options

**Plan saved to:** `docs/superpowers/plans/2026-06-10-admin-shell-operator-pages.md`

1. **Subagent-Driven** — fresh subagent per task, review between tasks
2. **Inline Execution** — implement in this session with checkpoints

Operator: say **"execute the plan"** or **"go"** to start implementation (Agent mode).
