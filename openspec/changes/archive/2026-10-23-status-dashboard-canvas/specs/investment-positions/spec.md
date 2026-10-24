# Spec Delta

## ADDED Requirements

### Requirement: Account ledger cards
The Assets page SHALL show the reporting date, then one card for each account in view. A card SHALL show the account name and its value on that date, then each holding in that account with its value. A cash account with no securities SHALL show its balance as the card value. Each card SHALL offer adding a holding for that account. Account maintenance and security maintenance SHALL appear as two utility cards below the accounts.

#### Scenario: Holdings sit inside their account
- **WHEN** the user opens Assets and an account has holdings on the reporting date
- **THEN** that account's card shows the account value and each holding's value

#### Scenario: Cash account has no security rows
- **WHEN** an account has a balance and no securities
- **THEN** its card shows the balance and an action to add a holding

#### Scenario: Reporting date stays available
- **WHEN** the user opens Assets
- **THEN** the reporting date control is shown above the account cards

### Requirement: Asset maintenance stays secondary
The Assets page SHALL NOT display the security-creation form, the manual-price form, or the corporate-action form. Those forms SHALL remain available from the security maintenance card. Selecting a holding SHALL still open the single-holding editor without a full-page form.

#### Scenario: Advanced forms stay closed
- **WHEN** the user opens Assets
- **THEN** the security-creation, manual-price, and corporate-action forms are not displayed

#### Scenario: Holding editor still opens
- **WHEN** the user selects a holding on an account card
- **THEN** that holding can be edited and saved without a full-page form
