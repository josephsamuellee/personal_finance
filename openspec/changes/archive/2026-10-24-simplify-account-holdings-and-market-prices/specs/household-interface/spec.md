# Spec Delta

## ADDED Requirements

### Requirement: Historical-date confirmation
Holding and price editing forms SHALL default the observation date to the current household-local date.
When the selected observation date is earlier than today, the form SHALL display a prominent historical-date warning and SHALL require an explicit checkbox acknowledgment, unchecked by default, before saving.
Returning the date to today SHALL remove the warning and the acknowledgment requirement.
The forms SHALL NOT accept future-dated holdings or market prices.

#### Scenario: Today's update needs no acknowledgment
- **WHEN** the selected date is today and the user saves
- **THEN** no historical-date acknowledgment is required

#### Scenario: Historical update requires acknowledgment
- **WHEN** the selected date is in 2021 and the user attempts to save
- **THEN** a warning identifies the historical date and saving requires the explicit checkbox

#### Scenario: Acknowledgment starts unchecked
- **WHEN** a historical-date warning is shown
- **THEN** its acknowledgment checkbox is unchecked by default

#### Scenario: Returning to today clears the warning
- **WHEN** the user changes the date back to today
- **THEN** the historical warning and acknowledgment requirement are removed

#### Scenario: Future dates are rejected
- **WHEN** the user selects a date after today
- **THEN** the form does not accept the save

### Requirement: Date changes reload predictably
When the selected observation date changes in a holding or price form, the form SHALL load the latest applicable observation and the exact-date price for the new date without using future observations.
The form SHALL NOT silently discard unsaved changes when the date changes; it SHALL use a predictable reload or confirmation behavior that lets the user keep or abandon those changes.

#### Scenario: Date change reloads applicable values
- **WHEN** the user changes the observation date in an open editor
- **THEN** the form shows the latest applicable observation and exact-date price for the new date

#### Scenario: Unsaved changes are not silently lost
- **WHEN** the user has edited fields and then changes the date
- **THEN** the form either preserves the edits or asks for confirmation before discarding them
