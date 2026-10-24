# decision-journal Specification

## Purpose

Record why a financial choice was made, what alternatives were considered, and what happened afterward.

## Requirements

### Requirement: Decision record
The system SHALL store a financial decision with a decision date, a description, a rationale, the alternatives considered, and the expected effect.
A review date and a later outcome SHALL be optional.

#### Scenario: Decision without an outcome
- **WHEN** the user saves a decision date, description, rationale, alternatives, and expected effect
- **THEN** the decision is stored without requiring a review date or an outcome

#### Scenario: Outcome added later
- **WHEN** the user later adds an outcome to an existing decision
- **THEN** the decision shows that outcome and keeps the original decision date

### Requirement: Decision revisions
The system SHALL let the user edit a past decision and SHALL keep the previous values, the modifying user, and the modification time.

#### Scenario: Rationale correction
- **WHEN** the user corrects a decision's rationale
- **THEN** the current decision shows the new rationale and revision history shows the previous rationale
