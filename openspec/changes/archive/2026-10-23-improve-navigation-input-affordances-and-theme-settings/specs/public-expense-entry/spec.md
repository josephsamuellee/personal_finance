# Spec Delta

## MODIFIED Requirements

### Requirement: Invalid public input is rejected in place
The system SHALL reject a public submission with a missing amount, a missing category, a non-numeric amount, a zero amount, an unparseable date, or a receipt that is not an image or PDF.
The error response SHALL keep the visitor's entered values, SHALL identify the invalid field beside that field, and SHALL NOT include other household records.
An empty amount SHALL NOT be stored as an example value.

#### Scenario: Validation failure
- **WHEN** a public submission has no category
- **THEN** no expense is stored and the form shows the entered amount without other household records

#### Scenario: The error sits beside the field
- **WHEN** a public submission has no category
- **THEN** the category field shows the error and the entered amount remains

#### Scenario: The amount example is not stored
- **WHEN** a visitor submits Quick Expense without entering an amount
- **THEN** no expense is stored with 1000 or "$1,000"

## ADDED Requirements

### Requirement: Public amount field stays visible
The Quick Expense amount field SHALL show a visible boundary before focus and a muted example, such as "$1,000", while it is empty. The example SHALL NOT be the field's only label. The anonymous page SHALL still omit household navigation and household records.

#### Scenario: Empty public amount is obvious
- **WHEN** a visitor with no session opens Quick Expense
- **THEN** the empty amount field shows its label, a visible boundary, and a muted example

#### Scenario: Anonymous page still hides household data
- **WHEN** that visitor views the empty amount field
- **THEN** the page does not show Home, Expenses, Assets, Review, spending totals, or existing expenses
