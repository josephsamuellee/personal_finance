# Tasks

## 1. Shared 2×3 grid

- [x] 1.1 Extract a brokerage actions partial with 2×3 order (Add Holding, Update Holdings via CSV, Record Cash, Update prices, Remove Account, empty cell), `min-h-11 w-full` targets, archive styling, and optional id prefix. Verify a view or helper test of reading order.

## 2. Surfaces

- [x] 2.1 Render the partial on each active brokerage Assets card; leave cash/debt/property as Update balance; keep household Refresh Prices in the Assets header. Verify `account_type_behavior_test` still finds Record cash and CSV/Update prices/Remove Account ids on the brokerage card.
- [x] 2.2 Render the same partial on active brokerage `accounts#show` and remove header Refresh Prices. Verify `brokerage_actions_test` expects the 2×3 labels and no header Refresh Prices.

## 3. Wiring

- [x] 3.1 POST Update prices to `refresh_prices_account_path` with the reporting date; CSV to the existing importer; Remove Account to confirm-and-archive. Verify an integration test that Update prices from Assets is account-scoped and Remove Account archives.

## 4. Visual check

- [x] 4.1 Walk Assets and account details below 768px in light and dark. Verify no horizontal overflow and the empty bottom-right cell.

## Workflow follow-up

- Archive this change after review.
- Archive `brokerage-csv-import-and-account-management` (and `simplify-account-holdings-and-market-prices` if still open) so main specs do not keep the old 2×2 details grid.
- Verify `openspec validate --specs --strict` after archive.
