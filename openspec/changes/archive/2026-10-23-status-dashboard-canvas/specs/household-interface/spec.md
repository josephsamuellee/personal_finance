# Spec Delta

## ADDED Requirements

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
