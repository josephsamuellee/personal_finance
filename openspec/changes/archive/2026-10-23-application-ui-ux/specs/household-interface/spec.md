# Spec Delta

## ADDED Requirements

### Requirement: Shared visual system
The application SHALL present pages with one sans-serif type family, one spacing scale, and one color palette for light appearance and for the device's dark appearance.
Text and controls SHALL remain readable in both appearances.
Currency amounts SHALL use tabular numerals and one consistent currency format.

#### Scenario: Light page uses the shared type
- **WHEN** a user opens Home, Expenses, Assets, Review, or an administrative page in light appearance
- **THEN** the page uses the shared sans-serif type, spacing, and palette rather than the browser's default serif presentation

#### Scenario: Dark appearance stays readable
- **WHEN** the device requests a dark appearance
- **THEN** text and controls remain readable against their backgrounds

#### Scenario: Currency uses tabular figures
- **WHEN** a page shows two currency amounts
- **THEN** both use the same currency format and tabular numerals

### Requirement: Recognizable controls
Every text input, select, and date control SHALL show a visible boundary, a visible label, padding, and a focus indicator.
A primary button SHALL be visually distinct from a secondary button and from a text link.
The finished page SHALL NOT present those controls in the browser's default unstyled appearance.

#### Scenario: Input has a boundary and label
- **WHEN** a user focuses an amount or date field
- **THEN** the field shows its label, a visible boundary, and a focus indicator

#### Scenario: Primary button is distinct
- **WHEN** a page shows a primary save button and a secondary or text action
- **THEN** the primary button is visually distinct from the other action

### Requirement: Page hierarchy
Each page SHALL show a title and a short purpose, then one identifiable primary action, then the main financial information.
Advanced and administrative controls SHALL be visually secondary to that primary action.

#### Scenario: Primary action is identifiable
- **WHEN** a first-time user opens a primary page
- **THEN** the page title, purpose, and one primary action are identifiable without separate documentation

#### Scenario: Advanced control is secondary
- **WHEN** a page includes an infrequent administrative action
- **THEN** that action does not take the visual place of the page's primary action

### Requirement: Empty data states
A data section with no records SHALL explain what is missing and what the user can do next.
When a next action exists, the section SHALL offer it.
The section SHALL NOT show only an empty heading.
An empty data set, a failed load, and an empty search SHALL use different messages.

#### Scenario: No records yet
- **WHEN** a data section has no records
- **THEN** the section explains the absence and offers the action that creates the first record

#### Scenario: Search finds nothing
- **WHEN** a search or filter matches no records and records exist outside that filter
- **THEN** the section says that the search has no matches rather than saying that no records exist

#### Scenario: Load fails
- **WHEN** a data section cannot be loaded
- **THEN** the section says that the load failed and does not present the failure as an empty data set

### Requirement: Progressive disclosure
A frequently used action SHALL be available without opening an advanced menu.
A creation form SHALL appear only after the user asks to create that record.
The user SHALL be able to cancel an open form without changing stored data.

#### Scenario: Create form stays closed
- **WHEN** a user opens a page that can create a record
- **THEN** the creation form is closed until the user asks to create the record

#### Scenario: Cancel leaves data unchanged
- **WHEN** the user opens a form and then cancels it
- **THEN** no stored record changes

### Requirement: Accessible controls
Every input SHALL have a programmatic label.
An action that changes data SHALL use a button.
Navigation to another page SHALL use a link.
A dialog SHALL move focus into itself when opened and return focus when closed.
A status SHALL include text and SHALL NOT rely on color alone.
Error and status text SHALL be exposed to assistive technology.

#### Scenario: Input name is announced
- **WHEN** assistive technology reaches an input
- **THEN** it can announce that input's label

#### Scenario: Dialog returns focus
- **WHEN** the user closes a dialog
- **THEN** focus returns to the control that opened it

#### Scenario: Status includes text
- **WHEN** a record shows a verified, estimated, or failed status
- **THEN** the status includes text and is not indicated only by color

### Requirement: Mobile form layout
Below 768px, a form SHALL use a single column.
A data table that would require horizontal scrolling below 768px SHALL be shown as cards or compact rows.
A primary form control and a primary button SHALL be at least 44 by 44 CSS pixels.

#### Scenario: Phone form is one column
- **WHEN** a user opens a form below 768px
- **THEN** the fields stack in one column and the page does not scroll horizontally

#### Scenario: Wide table becomes compact
- **WHEN** a data table would extend past the viewport below 768px
- **THEN** the same records are shown as cards or compact rows without horizontal page scrolling

## MODIFIED Requirements

### Requirement: Narrow layout
Below 768px, and from 768px through 1023px, primary content SHALL remain usable without horizontal page scrolling.
At 1024px and above, a data-rich page SHALL keep its main column within about 1280px.

#### Scenario: Phone-width navigation
- **WHEN** the user navigates the application on a viewport below 768px
- **THEN** the current page's primary content fits without horizontal page scrolling

#### Scenario: Tablet-width navigation
- **WHEN** the user navigates the application on a viewport from 768px through 1023px
- **THEN** the current page's primary content fits without horizontal page scrolling

#### Scenario: Desktop content width
- **WHEN** the user opens a data-rich page at 1024px or above
- **THEN** the main column stays within about 1280px and does not stretch across the full viewport

### Requirement: Primary destinations
The interface SHALL offer Home, Expenses, Assets, and Review as the primary destinations.
Viewports below 1024px SHALL present those destinations in compact bottom navigation that stays reachable and respects the device safe area.
Viewports at 1024px and above SHALL present them in a sidebar.
Each of those destination controls SHALL be at least 44 by 44 CSS pixels.

#### Scenario: Mobile navigation
- **WHEN** the user views the application on a viewport below 1024px
- **THEN** Home, Expenses, Assets, and Review are available from bottom navigation and the sidebar is not shown

#### Scenario: Desktop navigation
- **WHEN** the user views the application on a viewport at 1024px or above
- **THEN** Home, Expenses, Assets, and Review are available from a sidebar and the bottom navigation is not shown

### Requirement: Entry feedback
A data-entry save SHALL tell the user whether it succeeded or failed.
When validation fails, the system SHALL keep the entered values and identify the invalid fields.
While a save is in progress, the system SHALL show that state and SHALL prevent a second submission of that same action.

#### Scenario: Validation failure keeps input
- **WHEN** the user submits a form that fails validation
- **THEN** the entered values remain and the invalid fields are identified

#### Scenario: Successful save is confirmed
- **WHEN** a data-entry save succeeds
- **THEN** the system confirms the success

#### Scenario: Repeated save is blocked
- **WHEN** the user activates the same save again before the first save finishes
- **THEN** the system does not create a second record from that repeated activation
