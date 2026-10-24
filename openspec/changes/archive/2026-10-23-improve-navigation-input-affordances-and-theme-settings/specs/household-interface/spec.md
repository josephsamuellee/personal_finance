# Spec Delta

## MODIFIED Requirements

### Requirement: Primary destinations
The interface SHALL offer Home, Expenses, Assets, and Review as separate button-shaped links. Below 1024px they SHALL sit in bottom navigation that stays clear of content and the safe area. At 1024px and above they SHALL sit in a sidebar and the bottom navigation SHALL be hidden. Each link SHALL be at least 44 by 44 CSS pixels, and its whole visible surface SHALL navigate. The current destination SHALL stay highlighted with `aria-current="page"` in both light and dark.

#### Scenario: Mobile navigation
- **WHEN** the user views the application on a viewport below 1024px
- **THEN** Home, Expenses, Assets, and Review are separate button-shaped links in bottom navigation and the sidebar is not shown

#### Scenario: Desktop navigation
- **WHEN** the user views the application on a viewport at 1024px or above
- **THEN** Home, Expenses, Assets, and Review are separate button-shaped links in a sidebar and the bottom navigation is not shown

#### Scenario: Assets is the active destination
- **WHEN** the user is on the assets page
- **THEN** Assets is highlighted and Home, Expenses, and Review are not

#### Scenario: Expenses becomes active
- **WHEN** the user navigates from Assets to Expenses
- **THEN** Expenses is highlighted and Assets is not

#### Scenario: Whole navigation item is clickable
- **WHEN** the user activates any part of a primary destination's visible surface
- **THEN** the application opens that destination

#### Scenario: Phone width keeps all four legible
- **WHEN** the viewport is 375 CSS pixels wide
- **THEN** all four destination labels are legible and each control is at least 44 CSS pixels tall

### Requirement: Entry feedback
A data-entry save SHALL tell the user whether it succeeded or failed.
When validation fails, the system SHALL keep the entered values and identify the invalid fields beside those fields.
While a save is in progress, the system SHALL show that state and SHALL prevent a second submission of that same action.

#### Scenario: Validation failure keeps input
- **WHEN** the user submits a form that fails validation
- **THEN** the entered values remain and each invalid field is identified beside that field

#### Scenario: Successful save is confirmed
- **WHEN** a data-entry save succeeds
- **THEN** the system confirms the success

#### Scenario: Repeated save is blocked
- **WHEN** the user activates the same save again before the first save finishes
- **THEN** the system does not create a second record from that repeated activation

## ADDED Requirements

### Requirement: Primary destination ownership
Home SHALL be the active primary destination only on the home page. Expenses SHALL own expense pages, expense import, and Quick Expense. Assets SHALL own the assets page, asset maintenance, accounts, and holding history. Review SHALL own reviews, decisions, comparisons, the benchmark, recurring items, and savings goals. Settings SHALL NOT highlight one of those four.

#### Scenario: Nested assets page keeps Assets active
- **WHEN** the user opens account management, asset maintenance, or a holding history page
- **THEN** Assets stays highlighted and the other primary destinations do not

#### Scenario: Spending pages keep Expenses active
- **WHEN** the user opens an expense, an expense import, or Quick Expense
- **THEN** Expenses is highlighted

#### Scenario: Planning pages keep Review active
- **WHEN** the user opens a review, a decision, a comparison, the benchmark, recurring items, or savings goals
- **THEN** Review is highlighted

#### Scenario: Settings highlights none of the four
- **WHEN** the user opens Settings
- **THEN** Home, Expenses, Assets, and Review are not marked as the current page

### Requirement: Button-styled actions
A control that opens a task screen or another working page SHALL show a visible fill or border, padding, and a text label. Activating any part of that visible surface SHALL run the control. Navigation SHALL use a link, and a control that changes stored data SHALL use a button. An inline reference to an existing record SHALL remain a text link. Keyboard focus and a pressed state SHALL be visible. A disabled control SHALL look different from an enabled one.

#### Scenario: An action is visibly a button
- **WHEN** the user sees Add an account, Manage accounts, or another task control
- **THEN** that control has a visible fill or border and is distinct from surrounding text

#### Scenario: The button surface activates
- **WHEN** the user activates the padding of that control rather than only its lettering
- **THEN** the control's action runs

#### Scenario: Keyboard focus is visible
- **WHEN** the user moves keyboard focus to the control
- **THEN** the focused control shows a visible highlight

#### Scenario: A disabled action is distinct
- **WHEN** an action cannot be used
- **THEN** its appearance is distinguishable from the same action when it can be used

#### Scenario: A record reference stays a text link
- **WHEN** a list shows an existing expense, account, decision, or review
- **THEN** that record's name or date remains a text link rather than a button

### Requirement: Settings entry
A signed-in Home page SHALL end with a Settings link that is visible after scrolling to the bottom of the page. The signed-in header and the desktop sidebar SHALL also link to Settings. Settings SHALL require a signed-in user and SHALL NOT show household financial amounts. Settings SHALL NOT replace the four primary destinations. The anonymous Quick Expense page SHALL NOT add those destinations.

#### Scenario: Settings is at the bottom of Home
- **WHEN** a signed-in user scrolls to the bottom of Home
- **THEN** a Settings control is visible and opens Settings

#### Scenario: Settings is also in the shell
- **WHEN** a signed-in user looks at the header or the desktop sidebar
- **THEN** Settings is available there as well

#### Scenario: Anonymous Quick Expense stays free of household navigation
- **WHEN** a visitor with no session opens Quick Expense
- **THEN** the page does not show Home, Expenses, Assets, Review, or household amounts

### Requirement: Appearance choices
Settings SHALL include a labeled Appearance choice of Light, Dark, or System. System SHALL follow the device color scheme. Light SHALL remain light when the device uses a dark scheme. Dark SHALL remain dark when the device uses a light scheme. The current page SHALL take the new appearance immediately, without signing out or reloading by hand.

#### Scenario: Dark applies immediately
- **WHEN** the user selects Dark
- **THEN** the current page changes to the dark appearance without a manual reload

#### Scenario: Light ignores a dark device
- **WHEN** the user selects Light and the device uses a dark scheme
- **THEN** the application stays in the light appearance

#### Scenario: System follows the device
- **WHEN** the user selects System
- **THEN** the application follows the device color scheme

### Requirement: Saved appearance
The signed-in user's appearance SHALL persist across navigation, reloads, and later visits. A user who has not chosen SHALL use System. The first painted page SHALL already use the saved appearance. Pages, navigation, buttons, inputs, dialogs, and chart labels SHALL use that appearance, and their text SHALL stay readable in Light and in Dark.

#### Scenario: Dark survives reload
- **WHEN** the user has selected Dark and reloads or opens another page
- **THEN** the application is still dark

#### Scenario: The first paint matches the saved choice
- **WHEN** a page loads for a user whose saved appearance is Dark
- **THEN** the first painted frame uses the dark appearance

#### Scenario: Chart labels stay readable
- **WHEN** a chart is shown in either appearance
- **THEN** its labels and axes remain legible against the chart background

### Requirement: Visible fields
Every editable text, number, currency, date, and select field SHALL have a visible label and a visible boundary or contrasting fill before it is focused. It SHALL have padding and a minimum height of 44 CSS pixels. Focus SHALL change the boundary or show a focus ring. Placeholder text SHALL look different from an entered value. In both appearances the unfocused field SHALL stay visible. A failed save SHALL keep the entered value and SHALL show the error beside that field.

#### Scenario: An unfocused field is visible
- **WHEN** the user looks at an empty field before focusing it
- **THEN** the field's boundary or fill shows where the value can be entered

#### Scenario: Focus changes the field
- **WHEN** the field receives focus
- **THEN** its boundary or focus ring changes

#### Scenario: Dark mode keeps the field visible
- **WHEN** the dark appearance is active and the field is not focused
- **THEN** the field remains visible without hovering

#### Scenario: The error marks the field
- **WHEN** validation fails
- **THEN** the user can see which field failed without guessing, and the entered value is still there

### Requirement: Currency example is not a value
An empty currency field SHALL show a muted example, such as "$1,000", as placeholder text and SHALL NOT use that example as its only label. The example SHALL NOT be submitted. After the user types an amount, the field SHALL show that amount in high-contrast text. A saved amount SHALL be shown as the field's value.

#### Scenario: Empty currency shows the example
- **WHEN** a currency field has no value
- **THEN** its boundary is visible and the muted example is shown inside it

#### Scenario: A typed amount replaces the example
- **WHEN** the user enters 2500
- **THEN** the field shows 2500 in high-contrast text

#### Scenario: The example is not saved
- **WHEN** the user submits a currency field without entering a value
- **THEN** the system does not store 1000 or "$1,000" from the example

#### Scenario: A saved amount stays a value
- **WHEN** the user opens a form for a record that already has an amount
- **THEN** that amount is the field value and the example is not shown in its place
