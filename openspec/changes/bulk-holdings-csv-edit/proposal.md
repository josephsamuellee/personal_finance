# Proposal

## Why

Today, taking a snapshot of every holding means opening each brokerage account and updating it one by one, either inline or through that account's CSV importer. Exporting all open holdings into one CSV, editing it in any spreadsheet, and uploading it back makes a full-portfolio snapshot (current or historical) a single pass. It also reuses the preview-and-confirm safety the account importer already has.

## What Changes

- New **export**: one CSV of every open holding in every active brokerage account, as of today. There is no date picker and no history export. Each row has `account_id` and a human-readable `account_name`. `price_per_share` is left blank, and a read-only `last_price` column is included for reference.
- New **bulk upload**: rows may span multiple brokerage accounts. Each row must name an account by `account_id`. The whole file must use exactly one `observation_date`. That date may be in the past (with the existing historical-date acknowledgment) and must not be in the future.
- **Missing-ticker handling**: current open holdings that are absent from the file are listed as a warning and ignored for the uploaded date. Nothing is created or closed for them. Selling is stated explicitly with quantity 0.
- **Account checks**: an `account_name` that doesn't match its `account_id` is a non-blocking warning, and `account_id` wins. An unknown, archived, or non-brokerage account blocks the import.
- **Review page**: every row shows a status marker (green check for accepted, red exclamation mark for a warning or error, with a label). The existing per-row plan, price authorization, and historical acknowledgment stay. The bottom of the page offers Upload corrected CSV (a new attempt that replaces the draft), Cancel, and Confirm (disabled while any error remains). Warnings never block.
- **Instructions page**: the entry page explains the one-date rule, quantity 0 for sold, missing rows being ignored, and keeping `account_id`. It offers the export download and the upload form.
- **Entry point**: reachable from the security maintenance utility card on Assets.
- Spreadsheet-saved files with a UTF-8 BOM are accepted.
- The existing single-account importer keeps its current behavior.

## Capabilities

### New Capabilities
- `holdings-bulk-edit`: Export all open holdings as one CSV and upload an edited single-date snapshot across multiple brokerage accounts, with row-level review, warnings, and atomic commit.

### Modified Capabilities
<!-- None: the single-account brokerage-csv-import behavior is unchanged; bulk edit reuses its security, price, and commit rules by reference. -->

## Impact

- `app/services/holdings_import/planner.rb`, `commit.rb`: generalize from one constructor `account` to a per-row account. The single-account importer passes rows that all have the same account. The duplicate key becomes (account, security, date).
- `app/models/holding_csv.rb`: add a bulk schema (account columns, `last_price` ignored), BOM stripping, and a single-date check, alongside the existing schema.
- New controller, routes, and views for bulk export, instructions, upload, review, and confirm, all behind authentication.
- `ImportBatch`: a bulk batch has a nil `account_id`, plus a new `kind` value.
- Assets page: the security maintenance utility card gains the entry link.
- No new dependencies, and no schema migration beyond what the `ImportBatch` kind change needs.
