# Spec Delta

## ADDED Requirements

### Requirement: Brokerage account action grid
An active brokerage account's details page SHALL show a 2-by-2 of fully clickable button-styled actions: Add Holding, Update Holdings via CSV, Record Cash, and Remove Account, in that reading order.
Each control SHALL be about 44 CSS pixels, keyboard-focusable, and usable below 768px without horizontal overflow. Remove Account SHALL look distinct as archive. Refresh Prices MAY remain elsewhere on the page.

#### Scenario: Mobile action layout
- **WHEN** the user opens an active brokerage account on a viewport below 768px
- **THEN** Add Holding is top-left, Update Holdings via CSV top-right, Record Cash bottom-left, and Remove Account bottom-right, and each entire visible surface activates the action
