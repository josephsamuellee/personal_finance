# Tasks

## 1. Audit and batch schema

- [x] 1.1 Confirm holdings import stays off expense routes and that `HoldingForm`, `Security.find_or_create_by_identity!`, and `MarketPrice.effective_on` remain the write path. Verify a short note in the change folder or test helper names those reuse points.
- [x] 1.2 Add `kind` (default `expenses`) and optional `account_id` to `import_batches`. Verify existing expense import tests still pass and a holdings batch can be created without expenses.

## 2. Parser and planning

- [x] 2.1 Implement `HoldingCsv` with ordered headers, ISO dates only, strict decimals, UTF-8, size/row limits, session `captured_on`, snapshot quantity, zero-quantity allowed, negatives rejected, in-file duplicate security+date detection. Verify parser tests for blank date, snapshot 50→55, duplicates, oversize, and invalid numbers.
- [x] 2.2 Resolve tickers (unique reuse, create with USD, ambiguous ticker+exchange blocked), blank vs nonblank shared notes, missing vs reused vs conflicting exact-date prices. Verify planner tests for shared security reuse, note preservation/update, price reuse/missing/conflict, and partial-file holdings left unchanged.

## 3. Preview, ack, and atomic commit

- [x] 3.1 Build the preview model (row number, ticker, date, quantity, cost basis, price, outcome, shared-effect flags) and require per-conflict price authorization plus one unchecked historical-date ack when any row is past. Verify preview tests list no-ops, conflicts, and historical rows without writing records.
- [x] 3.2 Commit through `HoldingForm` in one transaction, skip no-ops, revise same-date observations (no extra sequence), revalidate stale prices/notes before write, roll back on failure, store a holdings `ImportBatch`. Verify tests: one invalid quantity blocks all rows; cancel writes nothing; forced write failure persists nothing; identical reimport writes nothing; stale price after preview returns to preview.

## 4. Entry points and UI

- [x] 4.1 After creating a brokerage account, offer Import Holdings via CSV or Skip; existing brokerage details offer Update Holdings via CSV into the same flow with a locked account id. Verify skip leaves an empty account; failed CSV leaves the account; expense importer is not used.
- [x] 4.2 Upload screen: downloadable template, field guidance, authenticated-only routes. Verify unauthenticated GET/POST are rejected and the template headers match the spec.

## 5. Account actions, archive, restore

- [x] 5.1 On active brokerage `accounts#show`, render the 2×2 grid (Add Holding, Update Holdings via CSV, Record Cash, Remove Account) with 44px targets, dark-mode styles, and no horizontal overflow below 768px. Verify a system test of order and clickable surfaces; keep Refresh Prices on the page outside the grid.
- [x] 5.2 Remove Account confirms archive; add restore/unarchive; snapshot and Assets omit archived accounts when `archived_at.to_date <= on` and include them for earlier as-of dates; restore does not duplicate observations or delete shared prices. Verify archive/history/restore tests and that brokerage cash observations are not auto-converted.

## 6. Account-scoped refresh

- [x] 6.1 Scope `MarketData::Refresh` to distinct nonzero holdings of one account on the reporting date, one quote per security, reuse today's provider cache, skip manual prices, report per-security success/failure. Verify Fidelity-vs-Schwab selection, closed-position skip, manual protection, and partial provider failure.

## 7. Integration and visual checks

- [x] 7.1 Run `bin/rails test` and RuboCop; cover CSV happy path, invalid row, historical ack, concurrency/stale preview, archive as-of, and refresh dedupe. Verify zero failures and zero offenses.
- [x] 7.2 Walk new-account skip/import, existing-account CSV, 2×2 mobile grid, archive/restore, and account-scoped refresh in light and dark. Verify each flow matches the spec step count without horizontal scrolling.

## Workflow follow-up

- Archive this change after review.
- Verify `openspec validate --specs --strict` after archive (and after archiving `simplify-account-holdings-and-market-prices` if it is still open).
