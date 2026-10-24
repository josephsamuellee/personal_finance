# Spec Delta

## Purpose

Surface explainable observations from household records, and keep facts, estimates, and suggestions distinct without an external AI service.

## ADDED Requirements

### Requirement: Local explainable insights
The system SHALL derive insights from stored household data.
Each insight SHALL identify whether it states a known fact, an estimate, or a suggestion.
The system MUST NOT depend on an external AI service to produce an insight.
An insight MUST NOT create a required task.

#### Scenario: Insight stands alone
- **WHEN** the system shows a financial insight
- **THEN** the insight is computed from stored data, states its kind, and does not require the user to complete a task

### Requirement: Spending deviation
When current-month tracked spending exceeds the three-month baseline, the system SHALL be able to report that comparison.
When the current month is incomplete, the insight SHALL describe the current figure as month-to-date tracked spending.

#### Scenario: Incomplete month
- **WHEN** month-to-date tracked spending exceeds the three-month baseline before the month ends
- **THEN** the insight describes the current figure as month-to-date tracked spending

### Requirement: Carried-forward holding insight
An insight about a carried-forward holding SHALL include the `observed_on` date of the observation it uses.
The insight MUST NOT describe that quantity as verified on the later date.

#### Scenario: Carried quantity is named as carried
- **WHEN** an insight refers to a quantity carried forward from March into October
- **THEN** the insight includes the March observation date and does not call the October quantity verified

### Requirement: Upcoming obligation
The system SHALL be able to surface a recurring obligation whose next occurrence falls in the upcoming period defined by its frequency and effective dates.

#### Scenario: Obligation inside the upcoming period
- **WHEN** a recurring obligation has a next occurrence inside the upcoming period
- **THEN** an insight can show that obligation and its next date
