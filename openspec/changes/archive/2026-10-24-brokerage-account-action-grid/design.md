# Design

## Context

See proposal.md. Assets brokerage cards (`holdings/index.html.erb`) use a vertical `flex-col` of Add holding and Record cash. Account details (`accounts/show.html.erb`) already has a 2×2 plus header Refresh Prices. CSV import, archive, restore, and `AccountsController#refresh_prices` already exist.

## Goals / Non-Goals

**Goals:**
- One shared 2×3 markup pattern on the Assets brokerage card and active brokerage details.
- Update prices posts to `refresh_prices_account_path(account, on: @on)`.
- Remove Account uses the existing archive confirm path.

**Non-Goals:**
- New market-data providers or quote APIs.
- Changing household Assets header Refresh Prices.
- Checking/savings/debt/property card actions.
- New archive semantics.

## Decisions

### D1. Empty bottom-right cell
Keep a 2×3 CSS grid (`grid-cols-2`) with five children. Do not `col-span-2` Remove Account. Matches the requested layout.

### D2. Same grid on Assets and details
Partial in `app/views/accounts/_brokerage_actions.html.erb` (or equivalent) so order cannot drift. Details drop the header Refresh Prices; Update prices in the grid replaces it.

### D3. Update prices is live, not a stub
Call the existing account-scoped refresh. Label the control "Update prices". Keep household Refresh Prices on Assets.

### D4. Per-card ids
Assets: `add-holding-#{id}`, `update-holdings-csv-#{id}`, `record-cash-#{id}`, `update-prices-#{id}`, `remove-account-#{id}`. Details can keep unprefixed ids or use the same helper with a prefix option.

### D5. button_to vs link_to
Add Holding, CSV, Record Cash: `link_to`. Update prices and Remove Account: `button_to` (POST). `min-h-11` and `w-full` so the cell is the hit target.

## Risks / Trade-offs

- [Two Refresh Prices on Assets: header household + per-card account] → Distinct labels: header stays "Refresh Prices"; card says "Update prices".
- [Unarchived 2×2 spec] → This change's specs supersede details layout; archive CSV change before or with this one.
- [button_to inside CSS grid] → Style the form `w-full` so the button fills the cell.

## Migration Plan

View-only plus tests. No schema. Rollback is reverting the partial.

## Open Questions

None. Empty cell, live Update prices, and matching details were recorded as planning assumptions from explore.
