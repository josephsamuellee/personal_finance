# Proposal

## Why

Primary navigation and several page actions still look like ordinary blue text, and unfocused inputs blend into the page, so people cannot tell what can be tapped. The application also follows the device color scheme only, with no way to choose light or dark and keep that choice.

## What Changes

- Style action and destination controls as buttons with a visible fill or border, padding, and hover, focus, pressed, and disabled states. Keep links for navigation and buttons for actions that change data. Leave record titles and other inline references as text links.
- Draw Home, Expenses, Assets, and Review as separate button-shaped items in the bottom bar and the sidebar. Highlight the destination that owns the current route, including its nested pages, with `aria-current="page"`.
- Add an authenticated Settings page with Light, Dark, and System appearance. Reach it from the bottom of Home and from the signed-in header and sidebar. Apply the choice immediately, persist it for that user, and avoid a flash of the wrong theme.
- Make every text, number, date, and select field visibly bounded before focus, in both themes, with its label, focus ring, and nearby validation message. Empty currency fields show a muted example such as "$1,000" that is not submitted.
- Apply those controls on Home, Expenses, Assets, Review, account management, Quick Expense, and the financial forms already in the app. Keep phone layouts stacked, at least 44px on primary targets, and clear of the bottom bar.
- Do not change financial calculations, observation rules, validation rules, authentication rules, or the public Quick Expense field set.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `household-interface`: Primary destinations gain a button shape and a route-based active state. Entry errors are identified beside the invalid field. New requirements cover action affordances, appearance preference, Settings entry, and visible inputs, including empty currency examples.
- `public-expense-entry`: The public amount field uses the same visible empty state, and a blank amount still does not store the example text or any other household data.

## Impact

- Shell and navigation: `app/views/layouts/application.html.erb`, `app/views/layouts/quick_expense.html.erb`, `app/views/shared/_navigation.html.erb`, and Home.
- Shared controls: Tailwind component classes, `UiFormBuilder`, and the shared field and button partials. Expense, account, user, and session forms that add their own border classes need to stop overriding the shared field.
- Settings: a new authenticated route and a `users.appearance` value (`system`, `light`, or `dark`), plus a matching cookie so the first render matches the saved choice. Existing users default to `system`, which keeps today's device-following appearance.
- Charts: net-worth chart colors follow the active theme.
- Tests and a browser pass at 375×812, 390×844, 768×1024, and 1440×900.
- The completed change `application-ui-ux` is not archived. Its device-only dark appearance is superseded here by an explicit preference whose default is still System. This change does not edit that change's artifacts.
