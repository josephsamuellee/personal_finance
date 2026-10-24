# Spec Delta

## ADDED Requirements

### Requirement: Brokerage account action grid
An active brokerage account SHALL show a 2-column, 3-row of fully clickable button-styled actions on its Assets card and on its details page, in this order: Add Holding, Update Holdings via CSV, Record Cash, Update prices, Remove Account, then an empty cell. Each control SHALL be about 44 CSS pixels and usable below 768px without horizontal overflow. Remove Account SHALL look distinct as archive.

#### Scenario: Assets card layout
- **WHEN** the user opens Assets on a viewport below 768px and a brokerage account is visible
- **THEN** the card shows Add Holding top-left, Update Holdings via CSV top-right, Record Cash middle-left, Update prices middle-right, Remove Account bottom-left, and an empty bottom-right cell, and each entire visible surface activates the action

#### Scenario: Account details match Assets
- **WHEN** the user opens the same active brokerage account's details page
- **THEN** the same 2-by-3 order and empty cell appear, and Refresh Prices is not a separate header control on that page
