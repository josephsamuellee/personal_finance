# Tasks

## 1. Shared fields and buttons

- [x] 1.1 Strengthen `.ui-field`, `.ui-button`, and `.ui-button-secondary` so an unfocused field has a fill that differs from the page and a visible border in light and dark, placeholders are muted, focus and pressed states are visible, and a disabled control uses a muted fill rather than opacity alone. Verify `test/integration/quick_expense_test.rb` shows the empty amount field with `ui-field`, a label, and placeholder `$1,000`, and a blank public submit does not store `1000` or `$1,000`.
- [x] 1.2 Remove the extra `border` and `bg-slate-900` classes from the expense, user, and session forms so they inherit the shared field and button styles. Use a decimal text input for empty and filled currency amounts, and leave quantity inputs numeric. Verify an expense edit request shows a saved amount as the field value, not as the placeholder, and Quick Expense still has no household navigation or totals.
- [x] 1.3 Show each validation error beside its field with `aria-invalid` and `aria-describedby`, and keep the submitted value. Verify the existing blank-account and blank-quantity examples still return 422, still show the entered values, and now include the message next to that field.

## 2. Navigation and action controls

- [x] 2.1 Style Home, Expenses, Assets, and Review as separate `ui-nav` links in both the bottom bar and the sidebar, with a path-prefix active state and `aria-current="page"`. Keep the bar fixed, add space so it does not cover content, and keep the safe-area inset. Verify `test/integration/shell_test.rb` for active Home on `/`, Assets on `/assets` and `/accounts`, Expenses on an expense and on Quick Expense, Review on `/reviews`, a 44px minimum class, and no horizontal-scroll page wrapper.
- [x] 2.2 Restyle task and destination links as button links, and leave record titles, allocation labels, and receipt links as text links. Include Import CSV, Open this month, Compare periods, the benchmark, Update balance, the asset maintenance links, Manage accounts, Edit, Cancel, Add user, and Sign in. Verify an integration example that Manage accounts and Import CSV use a button class, an account name remains `ui-link`, and the holding ticker is a button link.

## 3. Appearance settings

- [x] 3.1 Add `users.appearance` with allowed values `system`, `light`, and `dark`, defaulting existing and new users to `system`. Verify a model test rejects any other value and that a user created without the field is `system`.
- [x] 3.2 Add authenticated Settings with a labeled Light, Dark, and System choice. Link it from the bottom of Home, the signed-in header, and the sidebar, without adding it to the four primary destinations or to the anonymous Quick Expense layout. Verify a request test that a signed-out visit requires sign-in, the signed-in page shows the three choices and no household amounts, Home includes the bottom Settings link, and `/settings` does not mark a primary destination current.
- [x] 3.3 Set `data-appearance` on `<html>`, run a blocking head script before the stylesheets, switch Tailwind `dark` to the `.dark` class, and update the page immediately from the Appearance control. Persist the choice on the user and mirror it in the `appearance` cookie. Verify a request shows the script before the stylesheet, a Dark update is still Dark on the next GET, Light stays light in the rendered attribute, and a system test changes the page to dark without a manual reload.
- [x] 3.4 Restyle the net-worth chart axes and labels from the active text color when the chart connects and when the appearance changes. Verify a system test that the chart text color follows the dark appearance rather than staying on the default light-theme color.

## 4. Visual integration

- [x] 4.1 Run `bin/rails test` and inspect the running app at 375×812, 390×844, 768×1024, and 1440×900. Check active navigation, button hit areas, Light, Dark, and System, persistence after reload, Settings at the bottom of Home, empty and saved currency fields, focus, a validation error, and no horizontal scrolling. Record the result in `tmp/ui-verification/`, including screenshots when the browser can take them. Do not mark this task complete from the test suite or CSS classes alone.

## Workflow follow-up

- Sync or archive `application-ui-ux` before this change so its device-only dark wording is not the later spec text.
- Review the artifacts and the visual notes, then archive this change with `/opsx-archive`.
