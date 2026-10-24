# Spec Delta

## MODIFIED Requirements

### Requirement: Archived accounts
The system SHALL keep an archived account's observations, holdings, and history intact and SHALL omit that account from current data-entry choices and from active listings.
Remove Account SHALL confirm archive and SHALL NOT hard-delete the account, its observations, or any shared securities or market prices.
An archived account SHALL be omitted from active asset totals for a reporting date on or after its archive date, and SHALL remain included in as-of reports for dates before it was archived.
The system SHALL provide a restore action that clears archival, returns the same account and holdings to active use, and SHALL NOT duplicate existing observations.

#### Scenario: Archived account leaves the entry list
- **WHEN** the user archives an account
- **THEN** new entry choices omit that account and existing observations remain in history

#### Scenario: Archive hides from active views
- **WHEN** the user confirms Remove Account on an active brokerage account with historical holdings
- **THEN** the account is hidden from active listings and today's asset totals while its historical records remain intact

#### Scenario: History remains on earlier as-of dates
- **WHEN** an account is archived today and a report is viewed for a date before archival
- **THEN** historical valuation for that date remains available

#### Scenario: Restore does not duplicate
- **WHEN** an archived account is restored
- **THEN** the same account and preserved holdings become available again without duplicated observations
