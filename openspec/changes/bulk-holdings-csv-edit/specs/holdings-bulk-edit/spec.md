# Spec Delta

## Purpose

Let the household export every open holding as one CSV, edit it in any spreadsheet, and upload it back as a single-date snapshot across multiple brokerage accounts, reviewed row by row before an atomic commit.

## ADDED Requirements

### Requirement: Bulk edit entry and instructions
The security maintenance utility card on Assets SHALL link to a bulk holdings CSV page. That page SHALL explain that the export is today's open holdings, that an upload uses exactly one observation date, that quantity 0 records a sale, that a missing row is ignored rather than closed, and that account_id must be kept. It SHALL offer the export download and the upload form.

#### Scenario: Entry from Assets
- **WHEN** the user opens Assets and activates bulk holdings CSV in the security maintenance card
- **THEN** the instructions page opens with the export download and the upload form

#### Scenario: Rules are stated before upload
- **WHEN** the user opens the bulk holdings CSV page
- **THEN** the one-date rule, quantity 0 for sold, missing rows ignored, and keeping account_id are shown

### Requirement: Authenticated bulk access
Export, upload, review, and confirm SHALL require an authenticated session. Unauthenticated requests SHALL NOT receive holdings data and SHALL NOT store anything.

#### Scenario: Unauthenticated export is refused
- **WHEN** an unauthenticated request asks for the bulk export
- **THEN** authentication is required and no CSV is returned

#### Scenario: Unauthenticated upload is refused
- **WHEN** an unauthenticated request posts a bulk CSV
- **THEN** authentication is required and no holdings are stored

### Requirement: Today-only snapshot export
The export SHALL contain one row for every holding with a nonzero current quantity as of today in every active brokerage account, using carried-forward values where needed. It SHALL NOT offer another date or history. Archived accounts, non-brokerage accounts, and closed holdings SHALL be omitted.

#### Scenario: Open holdings across accounts
- **WHEN** Schwab holds VOO and VTI and Fidelity holds BND, and the user exports
- **THEN** the CSV has three rows, each naming its account

#### Scenario: Carried-forward holding is exported as of today
- **WHEN** MSFT was last verified three months ago and the user exports
- **THEN** the MSFT row carries its latest quantity and cost basis with today's observation_date

#### Scenario: Closed and archived holdings are omitted
- **WHEN** a holding's current quantity is 0 or its account is archived
- **THEN** the export has no row for it

### Requirement: Export columns
The export headers SHALL be account_id, account_name, ticker, note, currency, observation_date, quantity, cost_basis, price_per_share, and last_price, in that order. price_per_share SHALL be blank. last_price SHALL show the latest saved price for reference, or be blank when none exists.

#### Scenario: Price is left for the user
- **WHEN** VOO's latest saved price is from last week and the user exports
- **THEN** price_per_share is blank and last_price shows last week's price

### Requirement: Bulk upload schema
An upload SHALL use the export headers in the same order. last_price SHALL be ignored on upload. A leading UTF-8 byte-order mark SHALL be accepted. Ticker, quantity, cost basis, currency, price, and date rules SHALL follow the holdings CSV rules of brokerage-csv-import.

#### Scenario: Spreadsheet byte-order mark
- **WHEN** a CSV saved by a spreadsheet starts with a UTF-8 byte-order mark
- **THEN** the headers are recognized

#### Scenario: last_price is ignored
- **WHEN** a row's last_price differs from any saved price
- **THEN** no price is written from last_price

### Requirement: One observation date per upload
Every row in an upload SHALL share one observation_date. A past date SHALL require the historical-date acknowledgment. A future date SHALL be rejected. More than one distinct date SHALL block the file.

#### Scenario: Mixed dates block the file
- **WHEN** an upload has rows dated 2021-01-01 and 2021-02-01
- **THEN** the import is blocked and the rows with each date are identified

#### Scenario: Historical snapshot
- **WHEN** every row is dated 2021-01-01 and the user acknowledges the historical date
- **THEN** observations are recorded for 2021-01-01

### Requirement: Row account is required and valid
Every row SHALL name an account by account_id. A blank, unknown, archived, or non-brokerage account_id SHALL be an error that blocks confirmation. A new ticker for a valid account SHALL be allowed as a new holding.

#### Scenario: Archived account blocks
- **WHEN** a row names an archived brokerage account
- **THEN** that row is an error and confirmation is blocked

#### Scenario: New ticker in an existing account
- **WHEN** a row adds AAPL to a valid account that does not hold it
- **THEN** the review shows a new holding for that account

### Requirement: Account name mismatch warns
When a row's account_name differs from the name of its account_id, the review SHALL show a warning naming both, and the row SHALL be saved to the account_id account. The warning SHALL NOT block confirmation.

#### Scenario: Mismatched name
- **WHEN** a row says account_id 3 and account_name Fidelity, but account 3 is Schwab
- **THEN** the row shows a warning that it will save to Schwab, and confirmation stays available

### Requirement: Missing holdings are ignored
Each current open holding with no row in the upload SHALL be listed as a non-blocking warning. No observation SHALL be created, closed, or changed for it on the uploaded date. A sale SHALL be recorded only by a row with quantity 0.

#### Scenario: Holding bought after the uploaded date
- **WHEN** VTI is currently open and a 2021-01-01 upload has no VTI row
- **THEN** the review warns that VTI is ignored for 2021-01-01, and no VTI observation is written

#### Scenario: Sale is explicit
- **WHEN** an upload row states VTI quantity 0
- **THEN** VTI is closed on the uploaded date

### Requirement: Shared import rules apply
Bulk upload SHALL apply brokerage-csv-import's shared security resolution, note disclosure, price reuse and conflict authorization, no-op detection, and same-date revision rules per row. Two rows for the same account and security SHALL block the file.

#### Scenario: Duplicate within one account
- **WHEN** two rows name account 3 and VOO
- **THEN** the import is blocked and both row numbers are identified

#### Scenario: Same ticker in two accounts
- **WHEN** one row names account 3 and VOO and another names account 5 and VOO
- **THEN** both rows are accepted against the same shared security

### Requirement: Row-by-row review
The review SHALL show every uploaded row with its account, ticker, values, and planned outcome. It SHALL mark accepted rows with a green check and rows needing attention with a red exclamation mark, labeled as a warning or an error. Missing holdings SHALL appear in the same list style.

#### Scenario: Accepted and flagged rows
- **WHEN** an upload has one valid row, one name mismatch, and one unknown account
- **THEN** the review shows a green check, a red mark labeled warning, and a red mark labeled error

### Requirement: Review decisions
The bottom of the review SHALL offer Upload corrected CSV, Cancel, and Confirm. Uploading a corrected CSV SHALL replace the current attempt without saving it. Confirm SHALL be unavailable while any error remains. Warnings SHALL NOT block. Review SHALL NOT persist financial records.

#### Scenario: Re-upload replaces the attempt
- **WHEN** the user uploads a corrected CSV from the review
- **THEN** a new review replaces the previous one and nothing from the previous one is saved

#### Scenario: Errors disable Confirm
- **WHEN** any row is an error
- **THEN** Confirm is unavailable until a corrected CSV is uploaded

### Requirement: Atomic multi-account commit
Confirm SHALL revalidate against current data and write every change across all accounts in one transaction, or write nothing. It SHALL record one import batch and report a summary of created, updated, unchanged, and ignored holdings.

#### Scenario: Failure rolls back every account
- **WHEN** a write fails after one account's rows were processed
- **THEN** no account receives any change from the upload

#### Scenario: Stale review is revalidated
- **WHEN** a holding changes after review and the user confirms
- **THEN** the updated plan is shown again and nothing is silently overwritten
