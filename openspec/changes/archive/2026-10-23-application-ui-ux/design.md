# Design

## Context

See proposal.md for why this change exists. The app is Rails 7.2, Hotwire, and Tailwind v4 through `app/assets/tailwind/application.css`. The signed-in shell is `app/views/layouts/application.html.erb`: a sidebar from the `md` breakpoint (768px), bottom navigation below that, and a `max-w-5xl` column. Quick Expense uses `layouts/quick_expense.html.erb` and must stay free of household navigation and records.

Assets (`app/views/holdings/index.html.erb`) renders a balance form and a holding form for every row, plus security, manual-price, and corporate-action forms on the same page. `HoldingsController#update_position` and `#update_balance` already distinguish `add`, `correct`, and the default revise-current gesture. A failed save redirects with an alert, so the entered values disappear. `MarketData::Refresh` already keeps cached prices and records provider errors, but `MarketPricesController#refresh` shows every error as one failure notice and does not name a partial success.

## Goals / Non-Goals

**Goals:**

- One set of Tailwind treatments for type, color, cards, buttons, and fields, including the public Quick Expense form.
- Navigation and holding editing that follow the viewport rules in the delta specs.
- One open holding editor, with the observation date and the save intent visible inside it.
- Refresh feedback that matches all-success, partial failure, and total failure.

**Non-Goals:**

- Changing observation sequencing, valuation math, authentication, or the public expense field rules.
- Adding an in-app theme switch, a component framework, or a new font download.
- Making `holdings#show` the primary editor. That page stays the history and correction view.

## Decisions

1. **Stay with Tailwind utilities and a few shared partials.** Add field, button, card, and empty-state partials under `app/views/shared/`. Use the Tailwind v4 `dark:` variant, which follows `prefers-color-scheme`, for the dark palette. Set the document font to the system sans stack and apply `tabular-nums` anywhere `money` is shown.
   - Alternative: a ViewComponent library or a downloaded font. Rejected because the app is small ERB and a new dependency is unnecessary.

2. **Move the shell breakpoint from `md` to `lg`.** Below 1024px, keep the existing bottom navigation, add safe-area padding, and set `viewport-fit=cover`. At `lg`, show the sidebar and hide the bottom bar. Raise the main column to `max-w-7xl` (1280px). Primary destination links and primary buttons use at least 44px of height and width.
   - Alternative: keep the sidebar at 768px. Rejected because the proposal makes tablet use the compact navigation.

3. **Open one holding editor from the row.** The Assets list shows compact rows below 768px and aligned numeric columns from 1024px up. Selecting a holding opens one editor: an in-place region at `lg`, and a `<dialog>` sheet below that. The editor includes the observation date, defaulting to the page reporting date. Its label is "Verify" when that date's current quantity and cost basis are unchanged, "Edit observation" when they differ, and "New observation" when that date has no observation. Save posts the existing revise-current gesture. Cancel closes the editor and does not submit. The same-day "add another observation" control stays collapsed inside the editor.
   - Alternative: send every edit to `holdings#show`. Rejected because the current spec requires editing without a full-page form.

4. **Keep advanced asset forms off the default page.** Add one maintenance screen reached from a secondary Assets menu. It shows one of security creation, manual price entry, or corporate action, chosen by the menu. The existing create endpoints stay. Account creation continues to use the accounts screen and is linked from the empty state.
   - Alternative: leave the three forms in collapsed `<details>` on Assets. Rejected because the default page must not display those forms.

5. **Re-render a failed holding or balance save.** Invalid input renders the Assets page again with status 422, the editor open, the submitted values, and the error next to the field. Successful saves still redirect with the existing confirmation.
   - Alternative: stash the values in the flash. Rejected because a re-render keeps the errors attached to the fields.

6. **Report refresh outcomes from the result the service already builds.** Extend `MarketData::Refresh::Result` with the securities that were updated and those that failed. The controller sets a success notice with the newest price timestamp when all succeed, a partial-failure alert that names the failed tickers when some succeed, and a failure alert when none succeed. The button shows "Refreshing prices…" and stays disabled until the response returns. Cached rows are not deleted in any of these paths.
   - Alternative: a progress channel per security. Rejected because refresh is one request and the page only needs the final outcome.

7. **Empty sections use one partial.** It takes a message and an optional action. Home, Expenses, Assets, Review, and the administrative lists use it when their collection is empty. A search or filter with no matches uses different copy from a truly empty collection. A failed load uses an alert, not the empty-state partial.

8. **Verification evidence is operational, not a product feature.** Apply checks the running app at 375×812, 390×844, 768×1024, and 1440×900, and writes the notes under `tmp/ui-verification/`. Check the deployed hostname only when it responds. Rack tests still cover the behavior that does not depend on computed style.

## Risks / Trade-offs

- [Existing tests assume the always-visible Assets forms or the 768px sidebar] → Update those assertions in the same change, and keep the financial examples intact.
- [Rack tests cannot see contrast, focus rings, or overflow] → Browser checks at the four viewports are required before the tasks are marked done.
- [A `<dialog>` sheet can trap focus or leave the page scrollable] → Use the native dialog, move focus in on open, and return focus to the holding control on close.
- [Partial refresh currently looks like a total failure] → The result must count successes separately so a mixed run does not say the whole refresh failed.
- [Dark utilities can miss a one-off slate color] → Apply the shared field and card partials instead of styling each view from scratch.

## Migration Plan

This change is views, styles, and the refresh result. It has no schema migration. Deploy the assets with the views. Rollback is reverting the change; stored observations and cached prices stay valid.

## Open Questions

None. Viewport breakpoints, the maintenance screen, and the three save labels are decided above.
