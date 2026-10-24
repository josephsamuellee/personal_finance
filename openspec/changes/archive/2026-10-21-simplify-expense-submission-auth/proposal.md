# Proposal

## Why

Saving a household expense currently requires a Rails session, which gets in the way of the frequent mobile entry this app is for. Remote visitors are already gated by Cloudflare Access, and local visitors are on the household network, so the Rails login should not stand in front of creating a spending record.

## What Changes

- Add a Quick Expense page that can be opened and submitted with no Rails session.
- Accept only a new spending expense on that path. Amount and category are required. The date defaults to today in `America/Los_Angeles` and can be changed. Merchant, notes, and image or PDF receipts stay optional.
- After a successful save, show a generic confirmation and the same blank form so another expense can be entered immediately. The confirmation does not show totals, earlier expenses, or the saved amount.
- Keep Rails authentication on expense index, show, edit, update, and delete, on expense import, and on accounts, holdings, prices, reports, reviews, decisions, recurring items, and savings goals.
- Ignore client-supplied identity, record ids, refund links, and account ids on the public path. A public request cannot update an existing expense.
- Keep CSRF protection on. Add a per-IP throttle for the public submission only.
- Leave `created_by` empty when no session is present. Do not invent a system user. Existing expenses and their revision history stay as they are.
- **BREAKING:** creating a spending expense no longer requires a Rails user. Anyone who can reach the app, including a local visitor who never passed through Cloudflare Access, can submit spending.

## Capabilities

### New Capabilities

- `public-expense-entry`: Unauthenticated creation of spending expenses, the generic repeat-entry confirmation, and the boundary that leaves every other financial read and write behind a Rails session.

### Modified Capabilities

- None. `openspec/specs/` is empty because `household-finance-baseline` has not been archived. That change still says every financial route requires a session and that creating a record stores the authenticated user. This change conflicts with those unarchived requirements for the Quick Expense path only. Reconcile them when the baseline is archived; do not edit that change's artifacts here.

## Impact

- New Quick Expense controller, route, and form. The header Quick Expense link points at that route.
- `ExpensesController` keeps its session filter. Its create action is no longer the public entry path.
- `Expense` already allows a missing `created_by`. Public creates use that. Revisions continue to be written on later authenticated edits.
- Add `rack-attack` and limit it to the public submission. CSRF, host checks, and Active Storage authentication stay in place.
- Cloudflare Tunnel and Cloudflare Access are unchanged and are not treated as a Rails login.
- Tests cover a successful anonymous submission, rejection of id and identity tampering, throttling, and redirects on protected routes.
