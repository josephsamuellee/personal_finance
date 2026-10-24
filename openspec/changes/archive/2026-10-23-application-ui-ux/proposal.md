# Proposal

## Why

The household app already has the primary destinations and financial behavior, but the pages still mix unstyled controls, always-open maintenance forms, and empty headings. A shared visual system and a quieter Assets page make the common tasks readable on a phone and on a desktop without changing how money is calculated.

## What Changes

- Apply one sans-serif design system, through the existing Tailwind pipeline, to every page: type scale, spacing, color, cards, tables, dialogs, buttons, navigation, and forms.
- Give inputs visible boundaries, labels, padding, and focus; distinguish primary buttons from secondary buttons and text links; format currency with tabular numerals.
- Support a light palette by default and a dark palette when the device requests it. Both keep WCAG 2.2 AA contrast for text and controls. There is no separate in-app theme switch.
- **BREAKING** Move the sidebar breakpoint from 768px to 1024px. Below 1024px, Home, Expenses, Assets, and Review stay in compact bottom navigation that respects the safe area. At 1024px and above, those destinations stay in the sidebar. Data-rich pages use a content width of about 1280px.
- On viewports below 768px, forms stay one column and data tables become cards or compact rows. Primary navigation, form controls, and primary buttons are at least 44×44 CSS pixels.
- Give each page one obvious title, purpose, and primary action. Keep advanced work in menus, collapsed sections, or dedicated pages.
- Replace empty data headings with an explanation and a contextual next action. Separate empty data from a failed load and from an empty search.
- Keep entered values after validation failure, confirm a successful save, block a second submit while a save is in flight, and show loading, success, and failure for price refresh.
- On Assets, show the reporting date, portfolio summary when data exists, account balances, holdings, and the action to add or update a record. Do not show security creation, manual price entry, and corporate-action forms on that default page.
- Open one holding editor at a time: inline on desktop, a touch-friendly sheet below 1024px. The editor shows identity, quantity, cost basis, valuation, verification, and a visible observation date, and it labels a new observation, an edit, and a verification differently.
- Keep the anonymous Quick Expense page on its own layout. It uses the same control treatments and still shows no household records or primary navigation.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `household-interface`: Design system, explicit viewport breakpoints, page hierarchy, empty states, progressive disclosure, save feedback, and accessible controls.
- `investment-positions`: Assets page order, empty start, holding editor, historical date, and advanced maintenance kept off the default page.
- `market-valuation`: Visible in-progress, success, partial-failure, and provider-failure states for Refresh Prices, without deleting cached prices.
- `public-expense-entry`: The public form uses the shared control styles and keeps its anonymous presentation.

## Impact

- Views and layouts under `app/views`, especially `layouts/application.html.erb`, `layouts/quick_expense.html.erb`, `shared/_navigation.html.erb`, `holdings/index.html.erb`, `holdings/show.html.erb`, Home, Expenses, Review, and the account, import, goal, recurring, and decision pages.
- Tailwind styles in the existing asset pipeline. No new CSS framework and no calculation, schema, or authentication change.
- System and integration tests for navigation breakpoints, empty states, the holding editor, hidden advanced forms, and price-refresh feedback. Apply also inspects the running app at 375×812, 390×844, 768×1024, and 1440×900.
- Assumptions: tablet uses the compact bottom navigation; the page-level reporting date remains, and the holding editor has its own date; verifying unchanged values, revising the current observation, and adding a same-day sequence keep their current observation rules; screenshot notes go in `tmp/ui-verification/` and are not committed; the deployed hostname is checked only when it is reachable.
