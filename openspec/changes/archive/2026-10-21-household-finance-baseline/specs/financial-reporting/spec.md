# Spec Delta

## Purpose

Show point-in-time household totals and historical comparisons that keep unknown, estimated, and observed values distinct.

## ADDED Requirements

### Requirement: Homepage summaries
The homepage SHALL show estimated net worth, liquid assets, tracked spending for the current month, the three-month spending average, estimated monthly surplus, asset allocation, net worth history, and contextual insights.

#### Scenario: Dashboard content
- **WHEN** an authenticated user opens Home
- **THEN** each of those summaries is shown, with estimates and incomplete totals labeled

### Requirement: Point-in-time net worth
Net worth at a date SHALL equal known asset values minus known debt balances at that date.
Liquid assets SHALL equal known checking, savings, and brokerage-cash balances at that date.

#### Scenario: Debt is subtracted
- **WHEN** known assets and known debt exist for the selected date
- **THEN** net worth equals those assets minus that debt

### Requirement: Unknown values stay unknown
The system MUST NOT substitute zero for an unknown balance, property value, quantity, price, or unconverted non-USD amount.
A reported total that omits an unknown component SHALL be labeled incomplete.

#### Scenario: Missing price does not become zero
- **WHEN** a holding has no usable price on the selected date
- **THEN** net worth is labeled incomplete and the missing market value is not counted as zero

#### Scenario: Unconverted currency
- **WHEN** an account balance is denominated in a currency other than USD and no conversion is recorded
- **THEN** that amount is excluded from USD totals and the total is labeled incomplete

### Requirement: Carried values stay labeled
A reported total that includes a carried-forward component SHALL include that component and SHALL be labeled estimated.

#### Scenario: Carried balance remains in the total
- **WHEN** net worth includes a balance carried forward from an earlier date
- **THEN** the total includes that balance and is labeled estimated

### Requirement: Detailed history uses observation dates
A detailed time-series chart SHALL place each observation on its `observed_on` date.
The chart MUST NOT collapse several observations into a single month-end point.

#### Scenario: Mid-month observations stay separate
- **WHEN** a subject has observations on 28 August and 4 September
- **THEN** the detailed chart positions those observations on those dates

### Requirement: Monthly summary point
A monthly summary SHALL use the current observation with the latest `observed_on` in that month.

#### Scenario: Latest observation represents the month
- **WHEN** a month contains observations on the 10th and the 24th
- **THEN** the monthly summary uses the current observation from the 24th

### Requirement: Drill-down
The user SHALL be able to open the records behind a dashboard metric or chart point.

#### Scenario: Spending month
- **WHEN** the user selects a spending month
- **THEN** the system opens that month's expenses

#### Scenario: Asset category
- **WHEN** the user selects an asset category
- **THEN** the system opens the assets in that category

#### Scenario: Holding history
- **WHEN** the user selects a holding
- **THEN** the system opens that holding's observation history

#### Scenario: Saved review
- **WHEN** the user selects a saved review
- **THEN** the system opens that review's saved financial context

### Requirement: Historical comparison
The system SHALL compare a selected period with a prior observation, a prior month, and a prior year using the same financial definitions.
The comparison SHALL identify missing and estimated values.

#### Scenario: Prior-year comparison
- **WHEN** the user compares a month with the same month in the prior year
- **THEN** both sides use the same definitions and any missing or estimated values are identified

### Requirement: Provenance without a score
The system SHALL show the age and source of a displayed figure when that figure is carried forward, estimated, cached, or unknown.
The system MUST NOT replace that explanation with a single accuracy score.

#### Scenario: Carried figure shows its source date
- **WHEN** a displayed quantity is carried forward
- **THEN** the interface shows the observation date it came from and does not show a single accuracy score
