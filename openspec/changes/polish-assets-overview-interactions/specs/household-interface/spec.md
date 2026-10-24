# Spec Delta

## MODIFIED Requirements

### Requirement: Brokerage account action grid
An active brokerage account SHALL show four routine actions in a 2-by-2 of equal-width controls on its Assets card and on its details page: Add Holding, Update Holdings via CSV, Record Cash, and Update prices. Remove Account SHALL sit in a separate full-width footer, styled as archive, and SHALL NOT occupy a grid cell. Horizontal and vertical gaps SHALL match. Each control SHALL be about 44 CSS pixels tall, fill its cell, and remain usable below 768px without horizontal overflow.

#### Scenario: Assets card layout
- **WHEN** the user opens Assets on a viewport below 768px and a brokerage account is visible
- **THEN** Add Holding is top-left, Update Holdings via CSV is top-right, Record Cash is middle-left, Update prices is middle-right, the grid has no empty cell, and Remove Account is a full-width control below the grid

#### Scenario: Account details match Assets
- **WHEN** the user opens the same active brokerage account's details page
- **THEN** the same 2-by-2 and footer appear, and Refresh Prices is not a separate header control on that page

## ADDED Requirements

### Requirement: Assets cards omit repeated carried-forward lines
The Assets overview SHALL NOT repeat "Carried forward from &lt;date&gt;" under each account or holding. It SHALL still show the reporting date, names, values, and an incomplete or unknown signal when that state applies.

#### Scenario: Carried-forward rows stay concise
- **WHEN** several holdings are carried forward and the user opens Assets
- **THEN** each card shows the holding name and value without a carried-forward date on every row

#### Scenario: Incomplete state stays visible
- **WHEN** an account or holding is incomplete or unknown
- **THEN** the overview still shows that incomplete or unknown signal

### Requirement: Revealed editors scroll into view
When an Assets action reveals an editor or detail panel elsewhere on the same page, the system SHALL scroll that panel into view after it has rendered and SHALL move focus to its heading or first field. Route changes, a bottom sheet already on screen, and in-place updates SHALL NOT force a scroll. Reduced motion SHALL use an instant scroll. A failed action SHALL show the error at the control or the panel and SHALL NOT scroll to missing content.

#### Scenario: Offscreen holding editor is revealed
- **WHEN** the user selects a ticker whose editor is below the viewport
- **THEN** the editor is shown, scrolled into view, and focus moves to its heading or first field

#### Scenario: A new route does not jump
- **WHEN** the user chooses Add Holding or Update Holdings via CSV
- **THEN** the browser navigates to that page without an extra scroll on Assets

#### Scenario: Reduced motion
- **WHEN** the user prefers reduced motion and an editor is revealed
- **THEN** the panel is brought into view without a smooth scroll

### Requirement: Dark account-card actions
In dark mode, the four routine brokerage card actions SHALL use a dark background, a light border, and light text. Add Holding SHALL NOT use a bright filled surface. Focus, hover, and pressed states SHALL stay legible. Remove Account SHALL stay visually distinct as archive and SHALL keep its confirmation. Light mode SHALL keep readable contrast. This treatment SHALL NOT replace primary buttons on other pages.

#### Scenario: Dark routine actions
- **WHEN** brokerage cards render in dark mode
- **THEN** all four routine actions have dark surfaces, light borders, and light text

#### Scenario: Keyboard focus stays readable
- **WHEN** keyboard focus lands on one of those actions
- **THEN** the focus indicator is visible and the label stays legible
