# Spec Delta

## Purpose

Keep the household's accounts and dated observations accurate when values are backdated, carried forward, or corrected later.

## ADDED Requirements

### Requirement: Account identity
The system SHALL store each financial account with a name, a type, a currency, and an active or archived state.
Supported types SHALL include checking, savings, brokerage, debt, and non-security property.

#### Scenario: Create a checking account
- **WHEN** the user creates a checking account with a name and USD currency
- **THEN** the account is stored as an active checking account in the shared household

### Requirement: Household account ownership
Every account SHALL belong to the shared household.

#### Scenario: Second user sees the account
- **WHEN** one user creates an account
- **THEN** every authenticated user can view and edit that account

### Requirement: Archived accounts
The system SHALL keep an archived account's observations available in history and SHALL omit that account from current data-entry choices.

#### Scenario: Archived account leaves the entry list
- **WHEN** the user archives an account
- **THEN** new entry choices omit that account and existing observations remain in history

### Requirement: Observation kinds
Checking, savings, brokerage-cash, and debt accounts SHALL record dated balance observations.
Property accounts SHALL record dated value observations.
A security held in a brokerage account SHALL record dated position observations.

#### Scenario: Balance and position stay distinct
- **WHEN** a brokerage account has a cash balance and a security position on the same date
- **THEN** the system stores those as separate observations

### Requirement: Financial date and record timestamps
Every balance, property-value, and position observation SHALL store an explicit `observed_on` date separately from the time the record was created or last modified.

#### Scenario: Backdated entry keeps both times
- **WHEN** a user in 2026 records an observation dated 15 August 2021
- **THEN** the financial date is 15 August 2021 and the record timestamp is in 2026

### Requirement: Unlimited backdating
The system SHALL accept an `observed_on` date in the past without a recent-date limit.
The observation SHALL belong to that financial date in later reports.

#### Scenario: Historical month
- **WHEN** the current year is 2026 and the user records an observation dated 15 August 2021
- **THEN** the observation appears in August 2021 reporting

### Requirement: Retained observation history
The system SHALL retain every saved observation, including multiple observations for the same subject in one calendar month.

#### Scenario: Two dates remain distinct
- **WHEN** a subject has observations on 28 August and 4 September
- **THEN** both observations remain available on their own dates

### Requirement: Multiple observations on one date
The system SHALL allow more than one observation for the same subject on the same calendar date, each with its own explicit sequence.
The system SHALL create an additional observation only when the user explicitly adds one.

#### Scenario: Explicit second entry
- **WHEN** the user adds a second observation for the same account and date
- **THEN** both observations are retained and the new one receives the next sequence

### Requirement: Current observation for a date
For one subject and calendar date, the system SHALL treat the observation with the highest sequence as the current observation for that date.

#### Scenario: Higher sequence is current
- **WHEN** the same subject and date have observations with sequences 1 and 2
- **THEN** calculations for that date use sequence 2
- **AND** sequence 1 remains available in history

### Requirement: Revising the current observation
Saving an edit of the current observation SHALL revise that observation and SHALL keep its sequence.

#### Scenario: Edit does not stack a new row
- **WHEN** the user saves a change to the current observation for a date
- **THEN** the same observation is revised and no additional sequence is created

### Requirement: Carry forward the latest current value
For a reporting date, the system SHALL use the current observation from the latest `observed_on` on or before that date.
The system SHALL keep using that value until a later observation exists.
The system MUST NOT require the user to re-enter an unchanged value.

#### Scenario: March quantity appears in October
- **WHEN** 50 shares were last recorded in March and the user opens October
- **THEN** the application shows 50 as the latest known quantity, marked carried forward

### Requirement: Verified, carried-forward, and unknown values
A current observation on the selected date SHALL be presented as verified.
A value taken from an earlier date SHALL be presented as carried forward.
A subject with no observation on or before the selected date SHALL be presented as unknown.

#### Scenario: Selected date has its own observation
- **WHEN** the selected date has a current observation for a holding
- **THEN** the value is presented as verified

#### Scenario: No history is unknown
- **WHEN** a subject has no observation on or before the selected date
- **THEN** the value is presented as unknown

### Requirement: Verify on the selected date
When the user verifies a value for a selected date, the system SHALL save a current observation on that date.
Verification MUST NOT require a purchase, sale, or other transaction.

#### Scenario: Unchanged quantity is verified
- **WHEN** the user verifies an unchanged carried-forward quantity for October
- **THEN** the October value is verified and the earlier observation is unchanged

### Requirement: Partial update
Updating one subject SHALL leave every other subject's observations unchanged.
The system MUST NOT require the remaining subjects to be completed.

#### Scenario: One holding is updated
- **WHEN** the user updates a single holding
- **THEN** every untouched holding keeps its previous state and no completion step is required

### Requirement: Closed quantity
A current position quantity of zero SHALL carry forward as zero until a later observation.
The system SHALL treat that holding as closed.

#### Scenario: Sold-out holding
- **WHEN** the latest current quantity for a holding is zero
- **THEN** later dates show zero carried forward rather than unknown

### Requirement: Historical correction
The system SHALL let a user edit an existing observation.
The edit SHALL preserve the previous values, the modifying user, and the modification time.
The financial date SHALL stay the same unless the user changes that date.

#### Scenario: Share count correction
- **WHEN** a 2021 observation of 50 shares is corrected to 55 shares and the date is left unchanged
- **THEN** historical calculations use 55 shares
- **AND** revision history shows the previous quantity of 50
- **AND** the observation remains in 2021

### Requirement: Removal preserves history
Removing an observation from active use SHALL exclude it from current calculations and SHALL retain its revision history.

#### Scenario: Removed observation leaves calculations
- **WHEN** the user removes an observation from active use
- **THEN** current calculations omit it and its revision history remains available

### Requirement: Nonnegative debt
A debt balance SHALL be stored as a nonnegative amount owed.
Reports SHALL subtract debt balances from assets.

#### Scenario: Mortgage reduces net worth
- **WHEN** a debt account has a balance of 100000
- **THEN** the stored balance is 100000 and reports subtract 100000 from assets
