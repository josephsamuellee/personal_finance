# Tasks

Each task writes its failing test first, then the minimum code to make it pass.

## 1. Account on the row (refactor, no behavior change)

- [x] 1.1 Add `account` to `HoldingCsv::Row` and `HoldingsImport::PlanRow`. Make `Planner` and `Commit` read the account per row instead of from a constructor `account:`. Verify: the existing `test/models/holdings_import_planner_test.rb` and `test/integration/holdings_import_test.rb` pass after updating only their construction calls.
- [x] 1.2 Have `HoldingsImportsController` stamp the fixed account onto every row (parse and draft reload). Verify: `bin/rails test test/integration/holdings_import_test.rb` passes, and the single-account preview and confirm work unchanged.
- [x] 1.3 Group duplicate detection by (account, ticker, date). Verify: a new planner test passes where the same ticker appears in two accounts with no duplicate error, plus the existing same-account duplicate test.

## 2. Parsing: BOM, bulk schema, single date, warnings

- [x] 2.1 Strip a leading UTF-8 BOM in `HoldingCsv.read_utf8`. Verify: a `holding_csv_test` case with a BOM-prefixed file parses its headers, for both schemas.
- [x] 2.2 Add `warnings` to `Row` and `PlanRow`, kept out of `valid?`. Verify: a model test where a row with only warnings is `valid?`.
- [x] 2.3 Add `HoldingCsv.parse_bulk` with `BULK_HEADERS`, `last_price` ignored, and shared `build_row` field rules. Verify: tests for wrong header order (file error) and for `last_price` never reaching `price_per_share`.
- [x] 2.4 Resolve `account_id` against active brokerage accounts: blank, unknown, archived, or non-brokerage gives a row error, and a name mismatch gives a row warning naming both names. Verify: one model test per case.
- [x] 2.5 Enforce one distinct `observation_date` per file, with an error that identifies the rows for each date. Verify: a mixed-date test is blocked, and an all-blank-date file resolves to the session date.

## 3. Bulk planning: missing holdings and fingerprint

- [x] 3.1 Add an open-holdings query (as of today, active brokerage accounts, nonzero current quantity, carried-forward included) shared by the export and the planner. Verify: a model test with a closed holding, an archived account, and a carried-forward holding.
- [x] 3.2 Compute the missing holdings (open pairs absent from the upload) as warnings, and include them in the fingerprint. Verify: the planner test for "VTI open, 2021 upload without VTI" lists VTI and writes nothing, and a holding opened after review produces a stale fingerprint.
- [x] 3.3 Bulk commit: one transaction across accounts, `ImportBatch` kind `holdings_bulk` with nil account (add it to `KINDS`), and a summary that includes the ignored count. Verify: model tests for rollback across two accounts and for qty 0 closing a holding on the uploaded date.

## 4. Export

- [x] 4.1 Build the export CSV: `BULK_HEADERS`, today's date, current quantity and cost basis, blank `price_per_share`, and `last_price` from the latest usable price. Neutralize formula-leading cells in text fields. Verify: model tests for the column order, the blank price, `last_price`, and a `=cmd` account name exported as text.
- [x] 4.2 Verify the round trip: exporting and re-uploading unchanged gives only verified, no-op, or price-needed rows, with no errors and no warnings. Verify: an integration test.

## 5. Controller, routes, and review UI

- [x] 5.1 Add `BulkHoldingsImportsController` and routes (instructions, export, create, preview, confirm, cancel) behind authentication, with `Cache-Control: no-store` on the export. Verify: integration tests show unauthenticated export and upload are refused and nothing is stored.
- [x] 5.2 Build the instructions page with the one-date rule, qty 0 for sold, missing rows ignored, keeping `account_id`, the export download, and the upload form. Verify: an integration test asserts the rules text and both controls.
- [x] 5.3 Build the review page: one line per row with a green check, or a red `!` labeled Warning or Error. Missing holdings use the same style. The existing price authorization and historical acknowledgment stay. Verify: an integration test with one accepted row, one warning row, and one error row asserts each marker and label.
- [x] 5.4 Add the review actions at the bottom: Upload corrected CSV (replaces the draft), Cancel, and Confirm (disabled while any error exists; warnings don't block). Verify: integration tests that a re-upload replaces the plan and persists nothing, that errors disable Confirm, and that a warnings-only file commits.
- [x] 5.5 Add the entry link on the Assets security maintenance utility card, keeping Assets highlighted on the bulk pages. Verify: an integration test that the link is present and navigation highlights Assets.

## 6. Integration check

- [ ] 6.1 Run the full suite (`bin/rails test` and `bin/rails test:system`) and confirm everything passes, including the unchanged single-account importer tests.
