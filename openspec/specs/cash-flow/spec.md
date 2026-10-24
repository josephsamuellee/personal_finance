# cash-flow Specification

## Purpose

Estimate near-term cash flow from recurring income, tracked spending, and savings targets without presenting the estimate as reconciled activity.

## Requirements

### Requirement: Recurring items
The system SHALL store recurring income and recurring obligations with an amount, a frequency, an effective start date, and an optional end date.

#### Scenario: Salary with no end date
- **WHEN** the user saves a recurring income amount, a monthly frequency, and a start date
- **THEN** the item remains in effect from that start date until an end date is set

### Requirement: Recurring treatment
Each recurring item SHALL be marked either as already represented in tracked spending or as an additional planning amount.
Estimated cash flow SHALL include only recurring amounts marked as additional.
The system MUST NOT add a recurring item that is marked as already represented in tracked spending.

#### Scenario: Subscription already tracked
- **WHEN** a recurring obligation is marked as already represented in tracked spending
- **THEN** the cash-flow estimate does not add that obligation again

#### Scenario: Obligation added separately
- **WHEN** a recurring obligation is marked as an additional planning amount
- **THEN** the cash-flow estimate includes that obligation

### Requirement: Estimated surplus
The system SHALL estimate monthly surplus from expected recurring income, the tracked-spending baseline, and additional recurring obligations.
The system SHALL label the result as an estimate.
The system MUST NOT present the estimate as reconciled account activity.

#### Scenario: Surplus is labeled
- **WHEN** the user views the estimated monthly surplus
- **THEN** the figure is labeled as an estimate and is not described as reconciled cash activity

### Requirement: Savings target history
The system SHALL store each savings target with an amount, an effective period, a reason, and an optional review date.
The system SHALL reject a target whose effective period overlaps another target.
The applicable target for a date SHALL be the target whose period contains that date.
Earlier targets SHALL remain available after a new target takes effect.

#### Scenario: Temporary target change
- **WHEN** the user saves a new target with a later effective period, a reason, and no overlap
- **THEN** the new target applies in its period and the previous target remains in history

#### Scenario: Overlap is rejected
- **WHEN** the user saves a target whose period overlaps an existing target
- **THEN** the system rejects the save and keeps the existing targets unchanged

### Requirement: Surplus below target
When estimated monthly surplus is below the applicable savings target for two consecutive completed months, the system SHALL show an informational alert.
The alert MUST NOT create a required task.

#### Scenario: Two months below target
- **WHEN** estimated surplus is below the applicable target for two consecutive completed months
- **THEN** the system shows an informational alert and does not require the user to act
