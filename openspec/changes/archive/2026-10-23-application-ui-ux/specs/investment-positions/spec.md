# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

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
