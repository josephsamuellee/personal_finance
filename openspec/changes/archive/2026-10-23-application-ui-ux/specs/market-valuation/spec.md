# Spec Delta

## ADDED Requirements

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
