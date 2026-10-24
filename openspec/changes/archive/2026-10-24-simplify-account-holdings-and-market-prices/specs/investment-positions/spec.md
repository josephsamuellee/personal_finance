# Spec Delta

## MODIFIED Requirements

### Requirement: Security identity
The system SHALL store a security as a shared entity independent of any account, identified by a ticker and a currency, with an optional official name, an optional internal note, and an optional exchange or provider identifier used to distinguish ambiguous tickers.
The same security SHALL be reusable across multiple brokerage accounts without creating a duplicate record.
The currency SHALL default to USD and the official name SHALL NOT be required from the user.
The internal note SHALL belong to the shared security and SHALL be reflected wherever the security appears.

#### Scenario: Security is recorded
- **WHEN** the user adds a security with only a ticker
- **THEN** the security is created with USD currency and can be used on position observations in a brokerage account

#### Scenario: Existing ticker is reused
- **WHEN** VOO already exists and the user enters VOO while adding a holding to another account
- **THEN** the application identifies and reuses the existing security and its shared internal note is available

#### Scenario: Shared note follows the security
- **WHEN** VOO exists in two accounts and the user updates its internal note
- **THEN** both accounts display the same updated note

#### Scenario: Ambiguous tickers are distinguishable
- **WHEN** two securities share a ticker but differ in exchange or provider identifier
- **THEN** they remain distinct securities

#### Scenario: Official name is optional
- **WHEN** the user saves a security without entering an official name
- **THEN** the security saves without the name, and a name MAY be populated later from a market-data provider

### Requirement: Inline position editing
The user SHALL be able to open a holding's editor directly from Home wherever individual holdings are displayed, from the Assets overview, and from a brokerage account's details, without navigating through account management or a separate observation page.
At 1024px and above, the editor SHALL appear in place.
Below 1024px, the editor SHALL appear in a compact touch-friendly sheet.
Only one holding editor SHALL be open at a time.

#### Scenario: Edit a quantity in place
- **WHEN** the user selects a holding on the assets screen at 1024px or above
- **THEN** the quantity and cost basis can be edited and saved without a full-page form

#### Scenario: Edit a holding in a sheet
- **WHEN** the user selects a holding on the assets screen below 1024px
- **THEN** the editor opens in a touch-friendly sheet and can be saved without a full-page form

#### Scenario: Holding opens from Home
- **WHEN** the user selects a holding displayed on Home
- **THEN** the holding editor opens directly without intermediate pages

#### Scenario: Holding opens from its brokerage account
- **WHEN** the user selects a holding inside a brokerage account's details
- **THEN** the holding editor opens directly without passing through security or observation pages

### Requirement: Holding editor contents
The holding editor SHALL show the ticker, security name when known, account, quantity, aggregate cost basis, latest valuation when a price is available, last verified observation date, carried-forward status, and a market-price field for the selected observation date.
The editor SHALL include a visible observation-date control.

#### Scenario: Editor shows the holding
- **WHEN** the user opens a holding editor
- **THEN** the editor shows the ticker, security name when known, account, quantity, cost basis, valuation when available, last verified date, carried-forward status, and the price field

#### Scenario: Date control is visible
- **WHEN** the holding editor is open
- **THEN** the observation date is visible in that editor

#### Scenario: One form shows holding and price together
- **WHEN** the user opens the editor for VOO
- **THEN** quantity, cost basis, observation date, and market price are visible in one interface

### Requirement: Account ledger cards
The Assets page SHALL show the reporting date, then one card for each account in view. A card SHALL show the account name and its value on that date, then each holding in that account with its value. A cash account with no securities SHALL show its balance as the card value. A cash account card SHALL offer an Update balance action, and a brokerage account card SHALL offer an Add holding action and a Record cash action. Account maintenance and security maintenance SHALL appear as two utility cards below the accounts.

#### Scenario: Holdings sit inside their account
- **WHEN** the user opens Assets and an account has holdings on the reporting date
- **THEN** that account's card shows the account value and each holding's value

#### Scenario: Cash account has no security rows
- **WHEN** an account has a balance and no securities
- **THEN** its card shows the balance and an Update balance action

#### Scenario: Brokerage card offers holding and cash actions
- **WHEN** the user views a brokerage account's card
- **THEN** it offers Add holding and Record cash actions

#### Scenario: Reporting date stays available
- **WHEN** the user opens Assets
- **THEN** the reporting date control is shown above the account cards

## REMOVED Requirements

### Requirement: Observation intent
**Reason**: Unchanged saves must no longer record observations, verification becomes a distinct explicit action, and price-only saves update the shared market price without a holding observation.
**Migration**: Use the new "Save only intentional changes" requirement, which classifies each pending save and provides a distinct verification action.

## ADDED Requirements

### Requirement: Save only intentional changes
The holding editor SHALL identify each pending save as a new observation, an edit of the current observation for the date, a price-only update, or a save with no intentional change. A price-only change SHALL update the shared price without a holding observation; a quantity or cost-basis change SHALL record a dated holding observation that keeps revision history. A save with no intentional change SHALL create nothing, and verifying SHALL be a distinct explicit action.

#### Scenario: Changed values are an edit
- **WHEN** the selected date already has an observation and the user changes the quantity or cost basis
- **THEN** the editor identifies the save as an edit of that observation

#### Scenario: Another date is a new observation
- **WHEN** the user selects a date with no observation for that holding
- **THEN** the editor identifies the save as a new observation on that date

#### Scenario: Backdated save appears on that date
- **WHEN** the user saves a new observation for an earlier date
- **THEN** the holding history shows that observation on the selected date

#### Scenario: Price-only update
- **WHEN** the user changes only the market price and saves
- **THEN** the shared security price is updated for the selected date and no holding observation is created

#### Scenario: Holding update leaves price alone
- **WHEN** the quantity changes from 50 to 55 and the price field is not edited
- **THEN** a dated holding observation records the new quantity and the existing shared market price is unchanged

#### Scenario: Unchanged save records nothing
- **WHEN** the user saves the form with every value unchanged
- **THEN** no redundant holding observation or price record is created

#### Scenario: Verification is an explicit action
- **WHEN** the user wants to mark an unchanged holding as verified
- **THEN** a distinct verification action records it, rather than saving the unchanged form

#### Scenario: Cancel changes nothing
- **WHEN** the user opens the editor and cancels it
- **THEN** the holding quantity, cost basis, price, and history stay unchanged

### Requirement: Account-type primary actions
Checking and savings accounts SHALL support dated balance observations with "Update balance" as their primary action, prepopulating the latest applicable known balance and defaulting the observation date to today.
Brokerage accounts SHALL derive their total value from their holdings and any explicitly recorded uninvested cash, and SHALL NOT require or expose an independently entered aggregate account balance.

#### Scenario: Checking account primary action
- **WHEN** the user opens a checking account
- **THEN** the primary editing action is Update balance, the latest balance is prepopulated, and the date defaults to today

#### Scenario: Brokerage value is derived
- **WHEN** the user opens a brokerage account containing VOO and AAPL
- **THEN** the primary content displays those holdings and their calculated values, and no independently editable aggregate brokerage balance is displayed

#### Scenario: Aggregate balance is not double counted
- **WHEN** a brokerage account has holdings and cash
- **THEN** net worth counts the cash and the holding values exactly once and includes no aggregate brokerage total

### Requirement: Brokerage cash observations
A brokerage account's uninvested cash SHALL be an optional dated observation.
When cash has never been recorded, the system SHALL treat it as zero for valuation and SHALL NOT display a cash row in the default Assets overview.
Recorded cash SHALL be displayed while its applicable balance is nonzero.
Cash that becomes zero SHALL retain its historical observations while its row stays hidden from the default overview.

#### Scenario: No brokerage cash
- **WHEN** no cash observation exists for a brokerage account
- **THEN** no cash row appears and unrecorded cash contributes zero to the account's calculated value

#### Scenario: Brokerage cash recorded
- **WHEN** the user records 500 dollars of uninvested cash
- **THEN** a 500-dollar cash row appears for the applicable date and contributes to brokerage valuation exactly once

#### Scenario: Zero cash is hidden but kept
- **WHEN** recorded cash becomes zero
- **THEN** the cash row is hidden from the default overview and the historical observations remain

### Requirement: Combined holding creation
A brokerage account's "Add holding" action SHALL create or reuse a shared security and record the holding, its initial dated observation, and the selected-date price in one coordinated save.
The user SHALL select an existing security or enter a new ticker, with an optional shared note, currency defaulting to USD, observation date defaulting to today, required quantity, and required total cost basis.
A missing price for the selected date SHALL block creation until a price is entered or fetched.

#### Scenario: Add an existing security
- **WHEN** VOO exists with a saved price for today and the user adds VOO to a brokerage account
- **THEN** VOO is reused, the saved price is prepopulated, and only the holding-specific values are required

#### Scenario: Add a new security
- **WHEN** the user enters a new ticker with quantity, cost basis, and today's price
- **THEN** the security and holding are created through one save action

#### Scenario: Missing price blocks creation
- **WHEN** no price exists for the security on the selected date and the user saves without entering or fetching a price
- **THEN** the form explains that a price is required and no partial holding is created

#### Scenario: Save is atomic
- **WHEN** any part of the combined save fails
- **THEN** no security, holding, observation, or price is left behind from that save

### Requirement: Date-aware editor prepopulation
The holding editor SHALL prepopulate quantity and cost basis from the latest applicable observation on or before the selected date, with the source observation date identifiable.
The market-price field SHALL prepopulate only from an exact-date saved price.
When no exact-date price exists, the editor SHALL indicate that no price is recorded for that date and SHALL NOT silently substitute another date's price.
Future observations SHALL NOT be used to prepopulate a historical date.

#### Scenario: Prepopulation from the latest applicable observation
- **WHEN** a holding's last known quantity is 50 and cost basis is 18,000 dollars and the user opens the editor for a later date
- **THEN** 50 and 18,000 dollars are prepopulated and their source observation date is identifiable

#### Scenario: Historical date ignores future observations
- **WHEN** a holding has observations in 2021 and 2026 and the user selects a date in 2022
- **THEN** the form uses the latest applicable observation from 2021 and does not prepopulate from the 2026 observation

#### Scenario: Exact-date price only
- **WHEN** a price exists for the selected date
- **THEN** the price field shows that exact-date price

#### Scenario: No exact-date price
- **WHEN** no price is saved for the selected date
- **THEN** the editor shows that no price is recorded for that date rather than showing another date's price as if it were current
