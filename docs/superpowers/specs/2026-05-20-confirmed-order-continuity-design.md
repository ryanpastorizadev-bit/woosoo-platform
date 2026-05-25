---
status: canonical
date: 2026-05-20
source: WOOSOO_ROADMAP_REVIEW
---

# Confirmed Order Continuity Design

**Date:** 2026-05-20  
**Source:** `docs/WOOSOO_ROADMAP_REVIEW.md`  
**Primary target:** `tablet-ordering-pwa/`  
**Supporting contract:** Nexus session/order recovery payload

## Goal

Ensure that after a tablet submits an order successfully, the device can always recover the active confirmed order with complete item details after app restart, device reboot, or temporary interruption, as long as the order is still in the backend's `confirmed` state.

## Why this is the right next slice

This is the most relevant near-term functionality because it directly protects the live ordering flow without adding speculative offline behavior. The tablet does not need offline transactions. Its job is to capture the order, submit it online, and let staff operate from the printed order. What it does need is deterministic recovery so a rebooted tablet does not lose the current confirmed order, misroute to the wrong screen, or render an in-session state with missing items.

## Product decisions

1. **No offline transaction model.** The tablet remains live-only for submit.
2. **Persist only active-session state.** Local persistence exists only to recover the current ordering flow or active confirmed order.
3. **Backend remains source of truth.** Local storage may help resume quickly, but confirmed-order details come from the backend.
4. **Bootstrap is blocking.** The app must stay in a loading state until it knows whether an active session or confirmed order exists.
5. **No partial confirmed-order rendering.** The app must not enter the in-session confirmed view until items and required details are present.

## Problem statement

The current failure mode is a reboot or restart path where the tablet eventually redirects to the correct screen, but too slowly and sometimes without restoring the confirmed order's items. That means routing can complete before recovery data is reliable. In a live restaurant flow, that creates operator confusion and undermines trust in the tablet.

## Proposed design

### 1. Recovery model

Use a two-layer recovery model:

- **Local resume pointer** on the tablet for the active device/session/order context
- **Canonical backend recovery response** for the authoritative confirmed-order payload

The local layer exists only to tell the app what to attempt to recover. It is not the final source of truth for confirmed items.

### 2. Lifecycle behavior

#### Before submit

The tablet may persist the current draft ordering session so the in-progress flow can survive transient interruption.

#### After successful submit

Persist a small recovery record that identifies the active confirmed order context. This record may include a lightweight cached snapshot for immediate startup continuity, but it must be treated as provisional until the backend confirms it.

#### On cold start or resume

The app enters a blocking bootstrap state and does not route immediately. It checks for the recovery record and resolves the active state through one canonical recovery path.

Possible outcomes:

1. **Confirmed order still active**  
   Rebuild tablet state from the backend response, refresh any cached snapshot, and route to the confirmed in-session screen only after required order details are present.

2. **Active ordering session but no confirmed order**  
   Resume the ordering flow from the appropriate session state.

3. **No active session or confirmed order**  
   Clear stale recovery data and route to the clean start flow.

4. **Recovery unresolved because of transient connectivity or slow backend**  
   Stay in loading/reconnecting state until the app can distinguish between a real active state and no active state.

### 3. Routing model

The app should route only after bootstrap resolves into one explicit phase:

- no active session
- active ordering session
- confirmed order in progress

This avoids the current race where route selection and data hydration happen separately.

### 4. Data ownership

- **Tablet owns:** loading state, route gating, local resume pointer, active-session draft persistence, confirmed-order UI state after hydration
- **Backend owns:** authoritative active-session status, authoritative confirmed-order details, terminal-state determination

### 5. Persistence boundaries

Allowed local persistence:

- active draft order state for the current session
- resume pointer for the current active confirmed order
- cached confirmed-order snapshot used only as a temporary startup aid

Not allowed:

- offline submit queue
- deferred transaction processing
- long-lived historical order persistence on the tablet after the active session ends

Once the order is no longer active, the tablet clears the recovery state and starts clean for the next session.

## Error handling

1. Keep users on a friendly loading or reconnecting state while recovery is unresolved.
2. Never show raw technical errors on customer-facing screens.
3. If the backend reports that the order is no longer active, clear stale local recovery state immediately.
4. If the recovery payload is incomplete, do not route into the confirmed-order screen.
5. If recovery ultimately fails, show a clear staff-safe message rather than a broken or partially populated session screen.

## Acceptance criteria

1. After a confirmed order is submitted, restarting the tablet while the order is still `confirmed` restores the correct in-session screen with the full confirmed item list and required details.
2. The tablet does not route to the confirmed-order screen before the confirmed-order payload is complete.
3. If no active confirmed order exists, the tablet clears stale recovery data and lands on the correct clean-start state.
4. Under normal local-network conditions, bootstrap reaches the correct route in about 2 seconds or less; slower cases remain on a loading/reconnecting state rather than misrouting.
5. No customer-facing technical error is exposed during recovery.

## Validation scenarios

1. Restart after submit while order is still `confirmed`
2. Restart after the order has already moved out of `confirmed`
3. Slow bootstrap response from the backend
4. Stale local snapshot with newer backend truth
5. Regression case where the screen routes correctly but items are missing

## Out of scope

- true offline ordering
- offline transaction replay
- print-pipeline redesign
- staff notification redesign
- long-term analytics or handover work

## Implementation decomposition

This design should become one implementation plan, but execution will likely break into two tightly scoped tracks:

1. **Tablet track**  
   Blocking bootstrap, route gating, persistence ownership cleanup, confirmed-order hydration guard, recovery-state clearing rules

2. **Nexus contract track**  
   Guarantee one canonical recovery/bootstrap payload that includes everything required to reconstruct the confirmed-order screen safely

If the current backend contract already provides the full payload, implementation can remain tablet-only. If not, the contract change must be planned explicitly before app code is changed.
