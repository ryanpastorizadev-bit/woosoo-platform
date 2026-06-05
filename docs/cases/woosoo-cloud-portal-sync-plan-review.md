---
status: canonical
last_reviewed: 2026-06-04
scope: woosoo-nexus
---

# CASE: woosoo-cloud-portal-sync-plan-review

## Run State
- task_slug: woosoo-cloud-portal-sync-plan-review
- tier: 3
- branch: agent/woosoo-cloud-portal-sync-plan-review
- status: COMPLETE
- last_completed_agent: executioner
- next_agent: done
- active_runner: codex
- interrupted: false
- interrupt_reason: none
- updated: 2026-06-04 00:00

## Handoff
- Phase in progress: contrarian
- Done so far: Boot docs loaded; review hook selected; live-source review starting.
- Exact next action: Validate the submitted plan's claims against woosoo-nexus source files and summarize risks.
- Working-tree state (list edited files explicitly; cross-check with `git status`): docs/cases/woosoo-cloud-portal-sync-plan-review.md created for protocol checkpoint.
- Risks / do-not-redo: Keep this as review/spec audit only; do not implement app code.

## Tier
3

## Branch
agent/woosoo-cloud-portal-sync-plan-review

## Problem
Review the proposed Woosoo Cloud Portal local sync module plan for `woosoo-nexus`, focusing on data correctness, contracts, operational isolation, security, queue/retry behavior, and one-app boundary compliance.

## Contrarian Review
Tier 3 review because the proposed module introduces cloud auth/signing, queue/retry behavior, a durable sync cursor, outbox semantics, admin-triggered EOD operations, and a cross-repo reporting contract.

Findings:
- The direction is valid: manual EOD push, local-first operation, nexus-to-cloud-only topology, and separate `cloud_branch_uuid` preserve existing Woosoo boundaries.
- The plan is not implementation-ready until it corrects cursor and idempotency semantics. The proposed `last_device_order_id + last_changed_at` cursor over local `device_orders` does not by itself capture POS-only settlement/detail corrections unless the existing POS outbox consumers have already mirrored those changes into local rows.
- `branch + business_date` as a unique outbox idempotency key conflicts with correction/re-sync behavior unless the cloud treats the key as an upsertable logical dataset, not a one-shot request dedupe key.
- The plan's "since last successful sync up to now" window can combine multiple missed business days into one push, which conflicts with the confirmed "one batch per branch per day" model.
- The report-service reuse claim should be softened. Existing reports aggregate local tables and include legacy/fragile assumptions; they are precedents, not drop-in payload builders.
- Queue isolation requires deployment/root infrastructure changes because the current worker command only processes the default Redis queue. That must be split or explicitly justified under the one-app rule.
- The admin EOD action should enqueue batch building, not build a large POS/enriched payload inline in the HTTP request.
- A cloud sync contract document is required before code because this defines a cross-repo payload/API surface for the separate portal repo.

## Success Criterion
Task is done when the submitted plan has been audited against live `woosoo-nexus` evidence and findings are summarized with blockers, risks, and recommended plan changes.

## Investigation
Evidence checked:
- `app/Models/Branch.php` confirms local `branch_uuid` generation and `settings` cast.
- `app/Models/DeviceOrder.php` confirms `order_uuid`, branch scoping, status enum casting, soft deletes, and `items()` relation.
- `app/Models/DeviceOrderItems.php` is the active line-item model. It is referenced by `DeviceOrder::items()`, order mirroring, print-ticket logic, factories, and feature tests; the only caveat is the plural class name.
- `app/Console/Commands/SetupPosOrderPaymentTrigger.php` and `ConsumePosPaymentStatusEvents.php` show POS-local outbox/trigger infrastructure for payment, session close, and order detail updates.
- `app/Services/Reports/*.php` confirms local aggregation precedents but not a ready sync payload layer.
- `config/queue.php` and `compose.yaml` confirm Redis default queue usage and a single default queue worker command.
- `../contracts/order-state.contract.md` confirms terminal order-state contract and enum values.

## Root Cause
The plan mixes three separate concepts as if they were one: exact network retry idempotency, per-business-date dataset replacement/upsert, and cursor advancement. It also assumes local `device_orders` change timestamps fully represent POS-side settlement/detail changes, which is only safe if the existing POS outbox reconciliation is part of the sync precondition.

## Proposed Fix
Revise the plan before implementation:
- Define a payload/API contract in `contracts/cloud-sync-batch.contract.md`.
- Split exact-send idempotency from correction/re-sync semantics.
- Make one durable outbox row per branch/business_date/revision or define cloud-side dataset replacement explicitly.
- Require POS outbox drain/reconciliation before building an EOD batch, or add POS outbox watermarks to cloud sync state.
- Queue batch building and sending outside the admin HTTP request.
- Split app code from deployment/root queue-worker changes.
- Treat existing reports as logic references only.

## Files Changed
- `docs/cases/woosoo-cloud-portal-sync-plan-review.md`

## Verification
Review-only. No application tests were run because no app code was changed. Validation gate was not run; this was a spec/plan audit.

## Executioner Verdict
APPROVED for completion of the review task. The submitted plan itself is REJECTED for implementation until the findings above are addressed.

## Remaining Risks
Cloud receiving semantics are out of scope in this repo but must be specified before nexus code is written.
