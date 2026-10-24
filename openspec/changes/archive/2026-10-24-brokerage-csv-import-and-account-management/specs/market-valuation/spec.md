# Spec Delta

## ADDED Requirements

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
