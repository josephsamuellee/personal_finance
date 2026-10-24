# Spec Delta

## MODIFIED Requirements

### Requirement: Homepage summaries
The homepage SHALL show estimated net worth, liquid assets, tracked spending for the current month and the previous month, the three-month spending average, estimated monthly surplus, asset allocation, a three-month daily spending chart, net worth history, and contextual insights.

#### Scenario: Dashboard content
- **WHEN** an authenticated user opens Home
- **THEN** each of those summaries is shown, with estimates and incomplete totals labeled

#### Scenario: Previous month is shown
- **WHEN** an authenticated user opens Home
- **THEN** tracked spending for the current month and the previous month are both shown

## ADDED Requirements

### Requirement: Spending chart axes
The Home spending chart SHALL cover the last three calendar months. Its left axis SHALL be cumulative tracked spending within each month, restarting at each month boundary. Its right axis SHALL be tracked spending totaled for each calendar day. A day with no tracked spending SHALL appear as zero. The daily series and the cumulative series SHALL be visually distinct.

#### Scenario: Daily bin and cumulative line
- **WHEN** a month in the chart has spending on some days and none on others
- **THEN** each day has a bin, empty days are zero, and the cumulative line restarts at the beginning of that month

#### Scenario: Series stay distinct
- **WHEN** the spending chart is shown in light or in dark
- **THEN** the daily series and the cumulative series can be told apart

### Requirement: Spending chart uses tracked spending
The spending chart SHALL use the same tracked-spending definition as the monthly total. Transfers SHALL be excluded. Refunds SHALL remain negative.

#### Scenario: Transfer is absent from the chart
- **WHEN** a day contains a transfer and a spending expense
- **THEN** that day's bin includes the spending expense and excludes the transfer

### Requirement: Net worth chart uses observation dates
The Home net worth chart SHALL plot net worth on each recorded observation date across the available history. It MUST NOT collapse those dates into one point per month.

#### Scenario: Mid-month net worth stays on its date
- **WHEN** net worth observations exist on 10 October and 24 October
- **THEN** the Home chart shows those values on those dates
