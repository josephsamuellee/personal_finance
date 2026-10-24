# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
