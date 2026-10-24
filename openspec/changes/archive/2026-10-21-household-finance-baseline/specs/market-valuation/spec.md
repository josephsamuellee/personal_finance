# Spec Delta

## Purpose

Value holdings from explicitly requested, cached market prices while keeping missing prices unknown and leaving quantities unverified.

## ADDED Requirements

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
The system SHALL accept a price entered by the user and SHALL store it with manual provenance, a market date, and the entering user.

#### Scenario: User supplies a price
- **WHEN** the user saves a price for a security and a market date
- **THEN** valuation can use that price and its provenance is manual

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
Brokerage cash SHALL remain a balance observation.
The system MUST NOT add another brokerage total that already includes that cash and those position values.

#### Scenario: Cash and positions are the brokerage assets
- **WHEN** a brokerage account has cash and priced positions
- **THEN** its asset contribution is the cash balance plus the derived position market values
