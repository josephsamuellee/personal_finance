# market-valuation Specification

## Purpose

Value holdings from explicitly requested, cached market prices while keeping missing prices unknown and leaving quantities unverified.

## Requirements

### Requirement: Explicit price retrieval
The system SHALL contact an external price provider only after the user requests a refresh.
The system MUST NOT poll or schedule price retrieval on its own.

#### Scenario: Refresh requests prices
- **WHEN** the user chooses Refresh Prices
- **THEN** the system requests prices for the relevant securities

#### Scenario: No background retrieval
- **WHEN** the user has not requested a refresh
- **THEN** the system does not contact the price provider

### Requirement: Cached price metadata
The system SHALL cache each retrieved price with its market date, retrieval time, and source.

#### Scenario: Retrieved price is reused
- **WHEN** a price has been retrieved successfully
- **THEN** later views can use the cached price and its source metadata without another request

### Requirement: One request per security
When several accounts hold the same security, one refresh SHALL use a single provider request for that security.

#### Scenario: Shared ticker
- **WHEN** two accounts hold the same security and the user refreshes prices
- **THEN** the provider is not asked twice for that security during the refresh

### Requirement: Provider failure keeps the cache
When a provider request fails, the system SHALL keep existing cached prices, SHALL remain usable for other actions, and SHALL tell the user that the refresh failed.

#### Scenario: Provider unavailable
- **WHEN** the price provider is unavailable during a refresh
- **THEN** previously cached prices remain available and the failure is shown

### Requirement: Manual price entry
The system SHALL accept a price entered by the user and SHALL store it with manual provenance, a market date, the entering user, and an update timestamp.
Entering a price for a date that already has an effective price SHALL update that date's effective price rather than creating a duplicate.
Manual market-price updates SHALL NOT require full field-level revision history.
A manually entered price SHALL affect all account holdings of that security when valued on that date.

#### Scenario: User supplies a price
- **WHEN** the user saves a price for a security and a market date
- **THEN** valuation can use that price and its provenance is manual

#### Scenario: Same-day manual update
- **WHEN** VOO already has a price for October 23 and the user saves a different manual price for October 23
- **THEN** the effective October 23 price is updated and a duplicate effective record is not created

#### Scenario: Shared valuation
- **WHEN** two accounts hold VOO and its historical price changes
- **THEN** both accounts use the same effective historical price

### Requirement: Refresh does not verify quantity
A price refresh MUST NOT mark position quantities or cost bases as verified.

#### Scenario: Quantity stays carried forward
- **WHEN** a carried-forward quantity receives a newly refreshed price
- **THEN** the quantity remains carried forward and the price is shown with its own age

### Requirement: Market value and gain
When quantity and a price with a market date on or before the valuation date are known, market value SHALL equal quantity multiplied by the latest such price.
When aggregate cost basis is also known, unrealized gain SHALL equal market value minus that cost basis.

#### Scenario: Priced position
- **WHEN** a holding has a known quantity and a cached price on or before the valuation date
- **THEN** market value equals quantity times that price

### Requirement: Missing price stays unknown
When no price on or before the valuation date exists, market value SHALL be unknown.
The system MUST NOT substitute zero for a missing price.

#### Scenario: No cached price
- **WHEN** a holding has quantity and no usable price
- **THEN** market value is unknown and is not shown as zero

### Requirement: Brokerage value components
Position market value SHALL be derived from quantity and price.
Brokerage cash SHALL remain an optional dated balance observation.
When no cash has ever been recorded, cash SHALL count as zero and SHALL NOT make the brokerage incomplete or unknown.
The system MUST NOT add another brokerage total that already includes that cash and those position values.
Cash and position values SHALL each be counted exactly once.

#### Scenario: Cash and positions are the brokerage assets
- **WHEN** a brokerage account has cash and priced positions
- **THEN** its asset contribution is the cash balance plus the derived position market values

#### Scenario: Brokerage without cash is not incomplete
- **WHEN** a brokerage account has priced positions and no cash observation
- **THEN** its asset contribution is the derived position market values and the account is not shown as incomplete for the missing cash

### Requirement: Effective price uniqueness
Market prices SHALL belong to the shared security, not to individual accounts.
The system SHALL enforce one effective market-price record per security, market date, and relevant price convention and currency context, and SHALL prevent duplicate effective prices for the same security and date.

#### Scenario: Duplicate effective price is prevented
- **WHEN** two effective prices are saved for the same security and market date
- **THEN** only one effective price exists for that security and date

### Requirement: Historical price import
The system SHALL fetch historical prices for a user-selected security and date range only on explicit request.
Fetched prices SHALL be cached locally with the security, market date, price, currency, source, retrieval timestamp, and adjustment convention, and later reporting SHALL reuse the cache.
The import SHALL use the existing provider integration or a swappable adapter, and prices SHALL NOT be refreshed continuously or on a schedule.

#### Scenario: Historical import caches real market dates
- **WHEN** the user requests prices for January through March and the provider returns historical prices
- **THEN** the valid prices are cached with their actual market dates and metadata

#### Scenario: Cached prices are reused
- **WHEN** a report values holdings for a date whose price was previously imported
- **THEN** the cached price is used without another provider request

#### Scenario: Import only on request
- **WHEN** the user has not requested a historical import
- **THEN** the system does not fetch historical prices

### Requirement: Imports preserve manual prices
A provider import SHALL NOT silently overwrite a manually entered price.
When imported data conflicts with a manual price for the same security and date, the manual price SHALL be preserved by default.
The user MAY explicitly replace a manual price with provider data through a distinct replacement action.
Repeated imports and overlapping date ranges SHALL produce the same effective prices each time.

#### Scenario: Manual override protection
- **WHEN** a manually entered price exists for a date and a historical API import includes that date
- **THEN** the manual price is preserved unless the user explicitly chooses replacement

#### Scenario: Explicit replacement
- **WHEN** the user chooses to replace a manual price with provider data
- **THEN** the effective price for that date becomes the provider price and its provenance reflects the provider

#### Scenario: Repeated imports are deterministic
- **WHEN** the same date range is imported twice
- **THEN** the effective prices after the second import match those after the first

### Requirement: Market calendar handling
A historical price import SHALL account for weekends, holidays, and non-trading dates.
The system MUST NOT invent closing prices for non-trading dates.
Valuation SHALL distinguish the requested observation date from the effective market-price date used.
The system SHALL NOT present an adjusted historical price as a raw market price or vice versa.

#### Scenario: Non-trading date gets no price
- **WHEN** the imported range includes a weekend or market holiday
- **THEN** no price record is created for that date

#### Scenario: Requested date differs from effective price date
- **WHEN** a valuation is requested for a date with no trading price and a price exists on the latest earlier market date
- **THEN** the valuation uses that earlier market date's price and shows that effective price date

#### Scenario: Adjusted prices are labeled
- **WHEN** an imported price uses an adjustment convention
- **THEN** its stored metadata identifies that convention
### Requirement: Refresh in progress
While a price refresh is running, the interface SHALL show that the refresh is in progress.
The interface SHALL prevent another refresh from starting until the current refresh finishes.

#### Scenario: Refresh shows progress
- **WHEN** the user starts Refresh Prices
- **THEN** the interface shows that the refresh is in progress and does not start a second refresh

### Requirement: Successful refresh confirmation
When every requested price is retrieved, the interface SHALL confirm the refresh and show the price timestamp.
The confirmation SHALL NOT delete previously cached prices.

#### Scenario: Refresh succeeds
- **WHEN** Refresh Prices retrieves a price for every requested security
- **THEN** the interface confirms success and shows the timestamp of the retrieved prices

### Requirement: Partial price refresh
When some requested prices are retrieved and others fail, the interface SHALL identify the partial failure.
Cached prices for the securities that failed SHALL remain available.

#### Scenario: Some prices fail
- **WHEN** a refresh retrieves some prices and fails for others
- **THEN** the interface identifies the partial failure and the previously cached prices for the failed securities remain

### Requirement: Failed refresh is visible
When a price refresh fails, the interface SHALL show the failure.
The interface SHALL NOT present that refresh as successful.
Previously cached prices SHALL remain available.

#### Scenario: Provider failure is not a success
- **WHEN** the price provider fails during Refresh Prices
- **THEN** the interface shows the failure, does not present the refresh as successful, and previously cached prices remain

### Requirement: Account-scoped price refresh
Refresh Prices on a brokerage account SHALL request prices only for distinct securities with nonzero quantity in that account on the reporting date, one shared quote per security, and only on explicit request.
Closed positions SHALL NOT be selected. Saved prices SHALL remain shared by security and date, never account-specific.

#### Scenario: Account scope
- **WHEN** Fidelity holds VOO and AAPL and Schwab holds VOO and MSFT and the user refreshes prices for Fidelity
- **THEN** only VOO and AAPL are selected, with one shared effective price per security and date

#### Scenario: Closed positions are skipped
- **WHEN** a security's current quantity in that account on the reporting date is zero
- **THEN** that security is not selected for the account-scoped refresh

### Requirement: Account refresh preserves manuals and cache
An account-scoped refresh SHALL NOT silently overwrite a manually entered effective price for the same security and date.
When a provider request fails, previously cached prices SHALL remain and the interface SHALL report which securities failed.
A later view SHALL reuse a successfully cached provider price without another request when that cache is still the effective price.

#### Scenario: Provider failure keeps the price
- **WHEN** a request for AAPL fails during an account-scoped refresh
- **THEN** AAPL's previously saved price remains available and the failure is shown

#### Scenario: Manual override is kept
- **WHEN** VOO has a manually entered price for today and Refresh Prices runs for that account
- **THEN** the manual price is not silently overwritten
