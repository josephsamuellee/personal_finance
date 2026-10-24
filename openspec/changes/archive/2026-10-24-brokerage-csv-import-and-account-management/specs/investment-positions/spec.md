# Spec Delta

## ADDED Requirements

### Requirement: Brokerage details reach batch update
An active brokerage account's details SHALL offer Update Holdings via CSV and Refresh Prices without requiring the user to open asset maintenance or the expense importer.
Add Holding and Record Cash SHALL remain available from that page. Selecting a holding SHALL still open the single-holding editor.

#### Scenario: CSV update from the account
- **WHEN** the user opens an active brokerage account and chooses Update Holdings via CSV
- **THEN** the holdings importer opens for that account

#### Scenario: Holding editor still opens
- **WHEN** the user selects a holding on the brokerage account details
- **THEN** that holding's editor opens without a full-page security-maintenance detour
