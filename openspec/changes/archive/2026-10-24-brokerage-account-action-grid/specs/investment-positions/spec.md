# Spec Delta

## ADDED Requirements

### Requirement: Brokerage card batch and archive actions
An active brokerage Assets card SHALL offer Update Holdings via CSV into that account's importer, Update prices as an account-scoped refresh for the reporting date, and Remove Account as confirm-and-archive. Checking, savings, debt, and property cards SHALL keep a single Update balance action.

#### Scenario: CSV from the Assets card
- **WHEN** the user chooses Update Holdings via CSV on a Fidelity card
- **THEN** the holdings importer opens for Fidelity

#### Scenario: Update prices is account-scoped
- **WHEN** the user chooses Update prices on a Fidelity card
- **THEN** prices are requested only for Fidelity's nonzero holdings on the reporting date

#### Scenario: Remove Account archives
- **WHEN** the user confirms Remove Account on a Fidelity card
- **THEN** Fidelity is archived and remains on Assets only for as-of dates before it was archived

## MODIFIED Requirements

### Requirement: Account ledger cards
The Assets page SHALL show the reporting date, then one card for each account in view. A card SHALL show the account name and its value on that date, then each holding in that account with its value. A cash account with no securities SHALL show its balance as the card value. A cash, debt, or property card SHALL offer an Update balance action. A brokerage card SHALL offer the brokerage action grid. Account maintenance and security maintenance SHALL appear as two utility cards below the accounts.

#### Scenario: Holdings sit inside their account
- **WHEN** the user opens Assets and an account has holdings on the reporting date
- **THEN** that account's card shows the account value and each holding's value

#### Scenario: Cash account has no security rows
- **WHEN** an account has a balance and no securities
- **THEN** its card shows the balance and an Update balance action

#### Scenario: Reporting date stays available
- **WHEN** the user opens Assets
- **THEN** the reporting date control is shown above the account cards

#### Scenario: Brokerage card offers the action grid
- **WHEN** the user opens Assets and a brokerage account is in view
- **THEN** that card offers Add Holding, Update Holdings via CSV, Record Cash, Update prices, and Remove Account
