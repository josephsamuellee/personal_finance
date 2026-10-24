# investment-positions Specification

## Purpose

Track securities inside household accounts with aggregate cost basis, and let the user verify one holding at a time.

## Requirements

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
The assets screen SHALL let the user edit one holding without opening a full-page form.
At 1024px and above, the editor SHALL appear in place.
Below 1024px, the editor SHALL appear in a compact touch-friendly sheet.
Only one holding editor SHALL be open at a time.

#### Scenario: Edit a quantity in place
- **WHEN** the user selects a holding on the assets screen at 1024px or above
- **THEN** the quantity and cost basis can be edited and saved without a full-page form

#### Scenario: Edit a holding in a sheet
- **WHEN** the user selects a holding on the assets screen below 1024px
- **THEN** the editor opens in a touch-friendly sheet and can be saved without a full-page form

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

### Requirement: Assets page order
The Assets page SHALL show the title and reporting date, then the portfolio summary when any balance or holding exists, then account balances, then investment holdings, then the action to add or update a record.
The default Assets page SHALL NOT show the security-creation form, the manual-price form, or the corporate-action form.

#### Scenario: Populated assets order
- **WHEN** the user opens Assets and at least one balance or holding exists
- **THEN** the reporting date, portfolio summary, balances, and holdings appear in that order

#### Scenario: Advanced forms stay closed
- **WHEN** the user opens Assets
- **THEN** the security-creation, manual-price, and corporate-action forms are not displayed

### Requirement: Assets empty start
When no accounts and no holdings exist, the Assets page SHALL explain how to begin.
It SHALL offer actions to add an account, add an investment holding, and record a balance.
It SHALL NOT show empty Balances and Holdings headings without that guidance.

#### Scenario: Nothing recorded yet
- **WHEN** the user opens Assets and no account or holding exists
- **THEN** the page explains that nothing is recorded yet and offers those three actions

### Requirement: Holding editor contents
The holding editor SHALL show the ticker, security name, account, quantity, aggregate cost basis, latest valuation when a price is available, last verified observation date, and carried-forward status.
The editor SHALL include a visible observation-date control.

#### Scenario: Editor shows the holding
- **WHEN** the user opens a holding editor
- **THEN** the editor shows the ticker, security name, account, quantity, cost basis, valuation when available, last verified date, and carried-forward status

#### Scenario: Date control is visible
- **WHEN** the holding editor is open
- **THEN** the observation date is visible in that editor

### Requirement: Observation intent
The holding editor SHALL identify the pending save as a new observation, an edit of the current observation for the selected date, or a verification that the shown quantity and cost basis are unchanged.
Canceling the editor SHALL NOT change the holding.

#### Scenario: Unchanged values are a verification
- **WHEN** the selected date already has an observation and the quantity and cost basis are unchanged
- **THEN** the editor identifies the save as a verification

#### Scenario: Changed values are an edit
- **WHEN** the selected date already has an observation and the user changes the quantity or cost basis
- **THEN** the editor identifies the save as an edit of that observation

#### Scenario: Another date is a new observation
- **WHEN** the user selects a date with no observation for that holding
- **THEN** the editor identifies the save as a new observation on that date

#### Scenario: Backdated save appears on that date
- **WHEN** the user saves a new observation for an earlier date
- **THEN** the holding history shows that observation on the selected date

#### Scenario: Cancel changes nothing
- **WHEN** the user opens the editor and cancels it
- **THEN** the holding quantity, cost basis, and history stay unchanged

### Requirement: Advanced asset maintenance
Security creation, manual price entry, and a corporate action SHALL be reachable from secondary navigation or a contextual menu.
Those three forms SHALL NOT be open at the same time on the default Assets page.

#### Scenario: Maintenance remains reachable
- **WHEN** the user asks for security creation, manual price entry, or a corporate action from the secondary control
- **THEN** that one form opens

#### Scenario: Maintenance forms are not simultaneous
- **WHEN** the user is looking at the default Assets page
- **THEN** those three forms are not open together

### Requirement: Responsive holdings
Below 768px, each holding SHALL be shown as a compact row or card.
At 1024px and above, holdings SHALL show numeric columns aligned with one another.
Either presentation SHALL let the user open the holding editor without passing through an unrelated form.

#### Scenario: Phone holdings are compact
- **WHEN** the user views holdings below 768px
- **THEN** each holding is a compact row or card and the page does not scroll horizontally

#### Scenario: Desktop numbers align
- **WHEN** the user views holdings at 1024px or above
- **THEN** quantity, cost basis, and value use aligned numeric columns

#### Scenario: Editor opens from the holding
- **WHEN** the user selects a holding in either presentation
- **THEN** its editor opens without a security, price, or corporate-action form

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
