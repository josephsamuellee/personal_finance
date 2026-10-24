# investment-benchmark Specification

## Purpose

Compare household investments with VOO only as far as the recorded quantities, prices, and external cash flows can support.

## Requirements

### Requirement: Portfolio value comparison
The system SHALL show how portfolio value changed between two dates using recorded quantities and prices.
That result SHALL be labeled as a change in portfolio value.

#### Scenario: Value change is labeled
- **WHEN** the user compares portfolio value on two dates that both have usable quantities and prices
- **THEN** the system shows the change in value and labels it as a value change

### Requirement: Provisional performance comparison
A VOO comparison that depends on external cash flows SHALL be labeled provisional unless the contributions, withdrawals, and other external cash flows in the period are recorded.
The system MUST NOT present a precise outperformance figure when those cash flows are incomplete.

#### Scenario: Incomplete cash flows
- **WHEN** the user requests a VOO performance comparison and external cash flows in the period are incomplete
- **THEN** the system does not present a precise outperformance figure

#### Scenario: Recorded cash flows
- **WHEN** the external cash flows between the comparison dates are recorded
- **THEN** the system shows a cash-flow-adjusted comparison and identifies it as adjusted for those recorded cash flows
