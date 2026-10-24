# Spec Delta

## Purpose

Import expenses from CSV only after the user has mapped, previewed, and confirmed the rows, and allow that batch to be reversed.

## ADDED Requirements

### Requirement: Expense-only CSV import
The system SHALL import expenses from CSV.
The import MUST NOT create accounts, holdings, prices, or other non-expense records.

#### Scenario: CSV contains only expense rows
- **WHEN** the user confirms an expense CSV import
- **THEN** the system creates expense records and no other financial record types

### Requirement: Desktop import workflow
The CSV import workflow SHALL be available from the desktop expenses interface.
It SHALL require column mapping, a preview of parsed rows, validation, and an explicit confirmation before creating records.

#### Scenario: Preview before save
- **WHEN** the user uploads a CSV
- **THEN** the system shows the parsed rows and does not create expenses until the user confirms

#### Scenario: Cancel creates nothing
- **WHEN** the user cancels during mapping, preview, or validation
- **THEN** no expenses are imported

### Requirement: Invalid rows are identified
When parsed rows are invalid, the system SHALL identify those rows before confirmation.
The user SHALL be able to resolve or exclude them before any import is created.

#### Scenario: Invalid row is visible
- **WHEN** a parsed row fails validation
- **THEN** the user can identify that row before confirming the import

### Requirement: Reversible import batch
Each confirmed import SHALL retain batch metadata linking the created expenses to that import.
Reversing a batch SHALL remove that batch's expenses from active reporting and SHALL preserve their audit history.

#### Scenario: Reverse an import
- **WHEN** the user reverses a confirmed import batch
- **THEN** its expenses leave active spending totals and their audit history remains available
