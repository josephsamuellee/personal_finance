# Spec Delta

## Purpose

Present the household finances as an installable, mobile-first application with a few primary destinations and clear save feedback.

## ADDED Requirements

### Requirement: Narrow layout
On a narrow viewport, primary content SHALL remain usable without horizontal page scrolling.

#### Scenario: Phone-width navigation
- **WHEN** the user navigates the application on a narrow viewport
- **THEN** the current page's primary content fits without horizontal page scrolling

### Requirement: Installable online application
The system SHALL provide a web application manifest and icons so the application can be installed.
Installed navigation and authentication SHALL work while the device is online.
The system MUST NOT queue financial entries for synchronization while offline.

#### Scenario: Installed and online
- **WHEN** the user opens the installed application while online
- **THEN** navigation and authentication function

#### Scenario: Offline save is unavailable
- **WHEN** the device is offline
- **THEN** the system does not accept or queue a financial entry as saved

### Requirement: Primary destinations
The interface SHALL offer Home, Expenses, Assets, and Review as the primary destinations.
Narrow viewports SHALL present those destinations in bottom navigation.
Wide viewports SHALL present them in a sidebar.

#### Scenario: Mobile navigation
- **WHEN** the user views the application on a narrow viewport
- **THEN** Home, Expenses, Assets, and Review are available from bottom navigation

#### Scenario: Desktop navigation
- **WHEN** the user views the application on a wide viewport
- **THEN** Home, Expenses, Assets, and Review are available from a sidebar

### Requirement: Quick expense stays available
Quick expense entry SHALL be reachable from the primary interface.
Opening it SHALL present the amount and category fields immediately.

#### Scenario: Open quick expense
- **WHEN** the user opens Quick Expense
- **THEN** the amount and category fields are immediately accessible

### Requirement: Entry feedback
A data-entry save SHALL tell the user whether it succeeded or failed.
When validation fails, the system SHALL keep the entered values and identify the invalid fields.

#### Scenario: Validation failure keeps input
- **WHEN** the user submits a form that fails validation
- **THEN** the entered values remain and the invalid fields are identified

#### Scenario: Successful save is confirmed
- **WHEN** a data-entry save succeeds
- **THEN** the system confirms the success
