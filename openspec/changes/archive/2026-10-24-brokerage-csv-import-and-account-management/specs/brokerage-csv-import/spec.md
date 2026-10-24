# Spec Delta

## Purpose

Import a CSV snapshot of holdings into one explicit brokerage account after preview and confirmation, without mixing that flow with expense CSV import.

## ADDED Requirements

### Requirement: Two entry points, one workflow
The holdings CSV importer SHALL be reachable after saving a new brokerage account and from an existing brokerage account, with that account fixed for the session and not taken from a CSV row.
The workflow SHALL be distinct from expense CSV import. Skip, cancel, and validation failure SHALL leave an already-saved account in place and SHALL NOT persist holdings or prices from that attempt.

#### Scenario: New account skip
- **WHEN** the user saves a new brokerage account and skips CSV import
- **THEN** the account exists with no holdings and holdings can be added later

#### Scenario: New account import failure
- **WHEN** a newly saved brokerage account's CSV fails validation
- **THEN** the account remains and no partial holdings or prices are saved

#### Scenario: Existing account entry
- **WHEN** the user chooses Update Holdings via CSV on an existing brokerage account
- **THEN** the shared importer opens with that account as the target

### Requirement: CSV template and guidance
The upload screen SHALL offer a downloadable CSV template and concise field guidance for the required column headers and rules.
The importer SHALL require an authenticated session and SHALL NOT expose an unauthenticated asset-import endpoint.

#### Scenario: Template is downloadable
- **WHEN** the user opens the holdings CSV upload screen
- **THEN** a template file with the required headers can be downloaded

#### Scenario: Unauthenticated import is refused
- **WHEN** an unauthenticated request opens or posts the holdings importer
- **THEN** the system requires authentication and stores no holdings

### Requirement: CSV schema and session date
A holdings CSV SHALL use headers ticker, note, currency, observation_date, quantity, cost_basis, and price_per_share in that order.
Ticker, quantity, and cost_basis SHALL be required and nonnegative; zero quantity SHALL close a position. Blank currency SHALL default to USD. Blank observation dates SHALL use the household-local date captured once at upload. Dates SHALL be ISO-8601. Duplicate security-and-date rows SHALL block the import.

#### Scenario: Blank date uses the session date
- **WHEN** a row's observation_date is empty
- **THEN** that row uses the date captured at the start of the upload session

#### Scenario: Quantity is a snapshot
- **WHEN** an account already holds 50 VOO and a CSV row states quantity 55
- **THEN** the resulting observation is 55 shares, not 105

#### Scenario: Duplicate rows are blocked
- **WHEN** two CSV rows refer to the same resolved security and observation date for the target account
- **THEN** the import is blocked and both row numbers are identified

### Requirement: Shared security resolution
The importer SHALL reuse a uniquely matching shared security or create one with USD, and SHALL block an ambiguous ticker instead of guessing.
A nonblank note SHALL update the shared security note and SHALL be disclosed in preview; a blank note SHALL NOT erase an existing note.
Holdings absent from the CSV SHALL stay unchanged. Identical reimports SHALL be no-ops. Same-date observations SHALL be revised without discarding history.

#### Scenario: Shared security is reused
- **WHEN** VOO is already held in another brokerage account and the CSV imports VOO
- **THEN** the same shared security is reused and a holding is associated with the target account

#### Scenario: Partial import leaves other holdings
- **WHEN** an account holds VOO, AAPL, and MSFT and the CSV contains only VOO
- **THEN** AAPL and MSFT remain unchanged

#### Scenario: Shared note change is disclosed
- **WHEN** a nonblank CSV note differs from the existing shared note and the import is confirmed
- **THEN** the note changes globally and the preview had shown the old and new values

#### Scenario: Identical reimport is a no-op
- **WHEN** an identical CSV is imported a second time
- **THEN** preview identifies unchanged rows and no redundant observations are written

#### Scenario: Ambiguous ticker is blocked
- **WHEN** two securities share the CSV ticker and differ by exchange
- **THEN** the import is blocked until the match is unambiguous

### Requirement: Shared prices on import
Omitted price_per_share SHALL reuse a saved exact-date price, or block confirmation until a price is supplied or fetched.
An equal CSV price SHALL be reused. A conflicting CSV price SHALL require per-conflict confirmation of the old and new values and the cross-account impact.
Prices SHALL stay shared by security and date, never per account.

#### Scenario: Existing exact-date price is reused
- **WHEN** an exact-date VOO price exists and the CSV leaves price_per_share blank
- **THEN** validation reuses the saved price

#### Scenario: Missing price blocks confirmation
- **WHEN** no exact-date price exists and the CSV leaves price_per_share blank
- **THEN** confirmation is blocked until a price is supplied or explicitly fetched

#### Scenario: Price conflict needs authorization
- **WHEN** the saved price is 500 and the CSV says 510 for the same security and date
- **THEN** preview requires explicit authorization to replace 500 with 510

#### Scenario: Cross-account price impact
- **WHEN** two accounts hold VOO and an import updates VOO's shared price for a date
- **THEN** both accounts use the new effective price for that date

### Requirement: Preview then atomic commit
The workflow SHALL upload, validate, preview every proposed change, then commit in one transaction or write nothing.
Any invalid row SHALL block the file. Preview SHALL not persist financial records. Past observation dates SHALL require one unchecked historical-date acknowledgment; future dates SHALL be rejected.
Commit SHALL revalidate against current data, roll back on write failure, and report a batch summary.

#### Scenario: One invalid row blocks the file
- **WHEN** a 30-row CSV has one invalid quantity
- **THEN** no rows can be committed and the error identifies the row and field

#### Scenario: Cancel creates nothing
- **WHEN** the user cancels from preview
- **THEN** no financial records change

#### Scenario: Atomic failure rolls back
- **WHEN** a database write fails after some rows were processed
- **THEN** none of the proposed financial changes persist

#### Scenario: Historical rows need acknowledgment
- **WHEN** at least one CSV row is dated in the past and the user confirms
- **THEN** an unchecked-by-default historical-date acknowledgment is required

#### Scenario: Stale preview is revalidated
- **WHEN** a price changes after preview and the user confirms
- **THEN** the importer revalidates and does not silently replace the newly changed price
