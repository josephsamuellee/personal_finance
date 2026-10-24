# Spec Delta

## Purpose

Track securities inside household accounts with aggregate cost basis, and let the user verify one holding at a time.

## ADDED Requirements

### Requirement: Security identity
The system SHALL store a security with a ticker, an identifier, and a currency.

#### Scenario: Security is recorded
- **WHEN** the user adds a security with a ticker and identifier
- **THEN** the security can be used on position observations in a brokerage account

### Requirement: Position fields
A position observation SHALL record the account, the security, the quantity held, the aggregate cost basis, and the observed date.
Notes SHALL be optional.

#### Scenario: Position saves with notes omitted
- **WHEN** the user saves a quantity, an aggregate cost basis, and an observed date for a security in an account
- **THEN** the position observation is stored without requiring notes

### Requirement: Tax lots are not required
The system MUST NOT require individual tax lots before a position observation can be saved.

#### Scenario: Aggregate basis is enough
- **WHEN** the user enters one aggregate cost basis for a holding
- **THEN** the position saves without tax-lot details

### Requirement: Inline position editing
The assets screen SHALL let the user edit a single holding value without opening a full-page form.
A wide layout SHALL edit in place.
A narrow layout SHALL edit in a compact touch-friendly sheet.

#### Scenario: Edit a quantity in place
- **WHEN** the user selects a quantity on the assets screen
- **THEN** the quantity can be edited and saved without a full-page form

### Requirement: Saved value is verified
Saving a holding value for the selected date SHALL present that value as verified for the selected date.

#### Scenario: Verified after save
- **WHEN** the user saves a quantity for the selected date
- **THEN** the assets screen shows that quantity as verified

### Requirement: Untouched holdings keep their state
Saving one holding SHALL leave every untouched holding's verified or carried-forward state unchanged.

#### Scenario: Neighbor stays carried forward
- **WHEN** the user saves one holding and another holding was carried forward
- **THEN** the untouched holding remains carried forward

### Requirement: Explicit corporate action
The system SHALL change a holding quantity for a split or similar corporate action only when the user records that action with an effective date.
A market-price refresh MUST NOT change quantities.

#### Scenario: Split is recorded explicitly
- **WHEN** the user records a corporate action with an effective date and a new quantity
- **THEN** the holding history uses that quantity from the effective date

#### Scenario: Price refresh leaves quantity
- **WHEN** prices are refreshed
- **THEN** position quantities stay as previously observed
