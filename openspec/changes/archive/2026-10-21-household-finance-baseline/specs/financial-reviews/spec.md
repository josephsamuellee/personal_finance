# Spec Delta

## Purpose

Let the household save an optional review of a financial moment without requiring a schedule or a checklist.

## ADDED Requirements

### Requirement: Optional review event
The system SHALL let a user save a financial review with a review date and commentary.
The system MUST NOT require a review on a schedule.
The system MUST NOT require a checklist to finish a review.
Viewing historical financial data MUST NOT create a review.

#### Scenario: History without a review
- **WHEN** the user browses historical balances and expenses
- **THEN** no review is created

#### Scenario: Saved review
- **WHEN** the user saves a review date and commentary
- **THEN** the review is stored without a required checklist

### Requirement: Frozen review inputs
A saved review SHALL preserve the report inputs and the calculation version used when it was saved, along with references to the underlying records.
A later correction to those records SHALL leave the saved inputs unchanged.

#### Scenario: Later correction does not rewrite the review
- **WHEN** a record referenced by a saved review is corrected after the review was saved
- **THEN** the review still shows the inputs and calculation version stored at save time
