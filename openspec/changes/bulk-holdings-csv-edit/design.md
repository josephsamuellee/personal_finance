# Design

## Context

The single-account holdings importer is a pipeline: `HoldingCsv.parse` builds rows, the rows are stored as a file draft (`ExpenseImportDraft`, keyed by a session token), `HoldingsImport::Planner` turns them into `PlanRow`s, and `HoldingsImport::Commit` revalidates them against a fingerprint and writes through `HoldingForm` in one transaction. Both `Planner` and `Commit` take one `account:` in their constructor and use it for every row. `ImportBatch` already allows a nil `account_id`. The set of open holdings as of a date can be derived the same way `Reporting::Snapshot#position_components` does it: distinct (account, security) pairs, then `PositionObservation.current_on`.

## Goals / Non-Goals

**Goals:**
- One plan/commit engine for both importers, with the account taken from each row.
- Bulk-specific rules (account columns, single date, missing holdings, warnings) live in the bulk path and don't change single-account behavior.

**Non-Goals:**
- Cash, debt, or property balances in the CSV.
- Exporting any date other than today, or exporting history.
- Creating accounts from a CSV.
- Row-level status markers on the single-account preview (it could adopt them later).

## Decisions

**1. Account lives on the row, not on the Planner.**
`HoldingCsv::Row` gains an `account` (optional for single-account parsing). `Planner` and `Commit` stop taking `account:`. The single-account controller stamps its fixed account onto every row before planning. `PlanRow` carries `account` so the per-row lookups (`current_on`, same-date observations) and `HoldingForm` use it.
*Alternative:* run one Planner per account and merge the results. Rejected because it splits the fingerprint and the transaction, and it duplicates the stale and historical handling.

**2. Separate bulk parser entry, shared row rules.**
`HoldingCsv` keeps `HEADERS` for single-account files and adds `BULK_HEADERS` (`account_id, account_name, ticker, note, currency, observation_date, quantity, cost_basis, price_per_share, last_price`). Both parse paths share `build_row` for field validation. The bulk path also resolves `account_id` against `Account.available_for_entry.brokerage` (blank, unknown, archived, or non-brokerage → row error), records an account-name mismatch as a row **warning**, ignores `last_price`, and checks that the file has exactly one distinct date. BOM stripping goes in `read_utf8`, so both importers benefit at no cost.
*Alternative:* one parser with an optional account column. Rejected because the single-account spec forbids taking the account from a row.

**3. Warnings are a new channel next to errors.**
`Row` and `PlanRow` gain `warnings` (an array). `valid?` still depends only on `errors`, so warnings never block `Commit`. The review renders: errors → red `!` labeled "Error", warnings → red `!` labeled "Warning", otherwise a green check.

**4. Missing holdings are computed at plan time, not stored.**
A `HoldingsImport::BulkPlan` (or a method beside the planner) compares the current open holdings (as of today, active brokerage accounts, nonzero `current_on` quantity) against the (account, security) pairs in the upload. It returns a list of missing entries that is shown as warnings and included in the fingerprint, so a holding opened between review and confirm triggers a stale result. Nothing is written for them.

**5. Duplicate key is (account, ticker, date).**
`mark_duplicates` groups by account when one is present. Single-account behavior doesn't change, because every row has the same account.

**6. Export is built from the same open-holdings query.**
`BulkHoldingsExport` produces one row per open (account, security) as of `Date.current`: account id and name, ticker, the security note and currency, today's date, the current quantity and cost basis, blank `price_per_share`, and `last_price` = `MarketPrice.usable_on(security, today)&.amount`. It's sent with `send_data` from an authenticated controller action. Account names and notes are written through Ruby's `CSV` so they're escaped. Values starting with `=`, `+`, `-`, or `@` are prefixed with `'` to prevent formula injection when the file opens in a spreadsheet.

**7. New controller and routes; draft storage reused.**
`BulkHoldingsImportsController` (a singular resource: `show` for instructions, `export`, `create` for upload, `preview`, `confirm`, `cancel`) uses its own session key and `ExpenseImportDraft` for drafts. "Upload corrected CSV" on the review is the same `create` form. It deletes the previous draft before writing the new one. A batch is `ImportBatch.create!(kind: "holdings_bulk", account: nil)`, which adds `holdings_bulk` to `ImportBatch::KINDS`.

**8. Entry link on the security maintenance utility card.**
The link sits beside the existing maintenance actions. The Assets ledger card layout doesn't change otherwise.

## Risks / Trade-offs

- [Refactoring Planner/Commit could regress the single-account importer] → Run the existing `holdings_import_test` and `holdings_import_planner_test` unchanged first. Do the account-on-row change as its own step, with all tests passing, before adding any bulk code.
- [A spreadsheet rewrites `observation_date` (for example to `1/1/2021`)] → ISO-8601 is still required. The instructions page and the row error tell the user to keep YYYY-MM-DD.
- [The upload's one date makes `captured_on` mostly irrelevant] → Blank dates still default to the session date. If any row has a date and another is blank, the blank one resolves to the session date and the single-date check catches the conflict.
- [A large household export could exceed `MAX_ROWS` (500)] → Keep the limit. It's far above a household's holdings count, and the export refuses past it instead of producing a file the upload would reject.
- [The CSV contains account names and holdings] → It's served only to authenticated sessions, with `Cache-Control: no-store`, and nothing is written to `public/`.

## Migration Plan

No data migration. Deploying adds the routes and the new `ImportBatch` kind. Rolling back removes the routes. Existing `holdings_bulk` batches stay readable as plain records.
