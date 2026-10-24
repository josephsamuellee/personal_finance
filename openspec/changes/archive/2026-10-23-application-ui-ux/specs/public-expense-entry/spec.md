# Spec Delta

## ADDED Requirements

### Requirement: Public form uses shared controls
The Quick Expense form SHALL use the same visible field boundaries, labels, padding, focus indicators, and primary-button treatment as the rest of the application.
A visitor without a Rails session SHALL still see only the Quick Expense form, a way to sign in, and no household navigation or financial records.

#### Scenario: Anonymous form is styled
- **WHEN** a visitor with no Rails session opens Quick Expense
- **THEN** the amount, category, and other fields show visible boundaries, labels, and focus indicators, and the save action is a distinct primary button

#### Scenario: Anonymous form stays private
- **WHEN** a visitor with no Rails session opens Quick Expense after the shared control styles are applied
- **THEN** the page shows no household totals, existing expenses, accounts, holdings, or primary navigation
