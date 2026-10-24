# household-interface Specification

## Purpose

Present the household finances as an installable, mobile-first application with a few primary destinations and clear save feedback.

## Requirements

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

### Requirement: Quick expense stays available
Quick expense entry SHALL be reachable from the primary interface.
Opening it SHALL present the amount and category fields immediately.

#### Scenario: Open quick expense
- **WHEN** the user opens Quick Expense
- **THEN** the amount and category fields are immediately accessible

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

### Requirement: Status card canvas
Home, Expenses, Assets, and Review SHALL present their status content in metric, ledger, chart, or utility cards. Below 768px, paired cards SHALL stack in one column. From 768px, paired cards SHALL sit two across, and every chart card SHALL remain the full width of the content column. An empty collection SHALL show its empty message and action inside its card.

#### Scenario: Phone stacks paired cards
- **WHEN** the user opens Home on a viewport below 768px
- **THEN** the paired summary cards stack in one column and the charts remain full width

#### Scenario: Wide canvas pairs cards
- **WHEN** the user opens Home on a viewport of at least 768px
- **THEN** paired cards sit two across and each chart remains full width

#### Scenario: Empty collection stays in its card
- **WHEN** a status section has no records
- **THEN** that section's card shows the empty message and its action

### Requirement: Home dashboard
Home SHALL show estimated net worth, then liquid assets beside current-month and previous-month tracked spending, then the three-month spending chart, then net worth history, then the three-month average beside estimated surplus, then asset allocation beside contextual insights, then compare, the benchmark, and the latest saved review when one exists.

#### Scenario: Dashboard regions stay in order
- **WHEN** an authenticated user opens Home and household data exists
- **THEN** those regions appear in that order

#### Scenario: Summary cards navigate
- **WHEN** the user activates the liquid-assets action or the tracked-spending action
- **THEN** the application opens Assets or the current expense month, respectively

#### Scenario: Record names stay text links
- **WHEN** Home shows an allocation group or a latest review
- **THEN** that name is a text link and the compare and benchmark actions are button-styled links

### Requirement: Expenses status cards
The Expenses page SHALL show the selected month's tracked total as a metric card that links to recording an expense, category totals as a ledger, that month's expenses as a ledger, the three-month average, and CSV import as a utility action. Each expense row SHALL remain a text link.

#### Scenario: Month is a metric card
- **WHEN** the user opens Expenses for a month that has spending
- **THEN** the month total, category ledger, expense ledger, three-month average, and import action are each in a card

#### Scenario: Expense row stays a text link
- **WHEN** the user sees an expense in the month ledger
- **THEN** the row is a text link to that expense and the record action is a button-styled link

### Requirement: Review status cards
The Review page SHALL state that opening it does not save a review. It SHALL show a link to save a review, the saved reviews, the decisions, and links to the decisions list and period comparison. A review date and a decision description SHALL remain text links.

#### Scenario: Review index uses cards
- **WHEN** the user opens Review
- **THEN** the save action, saved reviews, decisions, and the decisions and compare links are presented as cards

#### Scenario: Opening Review saves nothing
- **WHEN** the user opens Review and does not activate save
- **THEN** no review is stored

### Requirement: Link-button band
A button-styled link SHALL show a 4px band whose color differs from the page background and from the card behind the link, in both light and dark. That band SHALL be part of the clickable surface. Keyboard focus SHALL remain visible against the band.

#### Scenario: Band is visible on a card
- **WHEN** a button-styled link is shown inside a card in light or in dark
- **THEN** a 4px band separates the control from the card and from the page

#### Scenario: Band click navigates
- **WHEN** the user activates the band around the link's label
- **THEN** the application opens that link's destination

### Requirement: Status colors follow appearance
Status cards, link bands, chart text, chart axes, daily spending bars, and the cumulative spending line SHALL use the light palette when appearance is light and the dark palette when appearance is dark. System appearance SHALL follow the operating system. Changing appearance SHALL update the open page, including an already drawn chart, without a manual reload.

#### Scenario: Dark choice restyles the dashboard
- **WHEN** the user chooses Dark on Settings
- **THEN** the open status page uses the dark surfaces and the chart text and series use the dark palette

#### Scenario: System follows the operating system
- **WHEN** appearance is System and the operating system is dark
- **THEN** the status page uses the dark palette

#### Scenario: Light stays light on a dark device
- **WHEN** appearance is Light and the operating system is dark
- **THEN** the status page uses the light palette
