# Tasks

## 1. Shared visual system

- [x] 1.1 Add shared field, button, card, and empty-state partials, plus the system sans stack, light and `prefers-color-scheme` dark palettes, and tabular currency numerals in the Tailwind entry. Verify a rendered Quick Expense page and a signed-in page use those treatments and do not leave amount fields or primary buttons in the browser's default unstyled appearance.
- [x] 1.2 Switch the signed-in shell from the `md` sidebar to an `lg` sidebar, keep bottom navigation below 1024px, add safe-area padding and `viewport-fit=cover`, and set the main column to `max-w-7xl`. Verify `test/integration/shell_test.rb` covers Home, Expenses, Assets, and Review in both the bottom navigation and the sidebar, with destination controls at least 44px and no horizontal page scroll.
- [x] 1.3 Apply the shared controls to `layouts/quick_expense.html.erb` without adding household navigation or records. Verify `test/integration/quick_expense_test.rb` still shows the labeled fields and no Assets link, totals, or existing expenses for an anonymous visitor.

## 2. Page hierarchy and empty states

- [x] 2.1 Give Home, Expenses, Assets, and Review a title, a one-line purpose, and one identifiable primary action, with administrative actions visually secondary. Verify a system test can find each title, purpose, and primary action.
- [x] 2.2 Use the empty-state partial for Home, Expenses, Assets, Review, accounts, imports, goals, recurring items, and decisions when their collection is empty, and use different copy for an empty filter and for a failed load. Verify integration examples for a household with no records, a month or group filter with no matches, and a failed load.

## 3. Assets holding editor

- [x] 3.1 Rebuild `holdings/index` so a populated page shows the reporting date, portfolio summary, balances, and holdings in that order, with compact rows below 768px and aligned numeric columns from 1024px up. Verify `test/system/household_flow_test.rb` and `test/integration/holdings_request_test.rb` see that order and do not require every holding form to be open.
- [x] 3.2 Open one editor from a holding: in place at `lg`, and a `<dialog>` sheet below that. Show ticker, name, account, quantity, cost basis, valuation, last verified date, carried-forward status, and a visible observation date. Label the save as verification, edit, or new observation, and let cancel close it without a write. Verify tests for all three labels, a backdated save on the selected date, an untouched neighbor staying carried forward, and cancel leaving the quantity unchanged.
- [x] 3.3 Re-render an invalid holding or balance save with status 422, the editor open, the submitted values, and the error beside the field. Disable the save control while the request is in flight. Verify an integration test that posts a blank quantity keeps the other entered values and does not store a second observation when the save is repeated.

## 4. Advanced asset maintenance

- [x] 4.1 Move security creation, manual price entry, and corporate-action recording to one maintenance screen opened from a secondary Assets menu, showing only the requested form. Link add-account, add-holding, and record-balance from the empty Assets state. Verify the default Assets response contains none of those three forms, each menu choice shows only its form, and the existing save paths in `holdings_request_test.rb` and the market-price request still persist a security, a manual price, and a corporate action.

## 5. Price refresh feedback

- [x] 5.1 Extend `MarketData::Refresh::Result` with updated and failed securities, and make `MarketPricesController#refresh` show an in-progress label, a success notice with the price timestamp, a partial-failure alert that names the failed tickers, or a failure alert that is not a success. Do not delete cached prices. Verify `test/models/market_data_test.rb` and an integration request cover all three outcomes and that a failed refresh leaves the previous price in place.

## 6. Visual integration

- [x] 6.1 Run `bin/rails test` and inspect the running app at 375×812, 390×844, 768×1024, and 1440×900 for Home, Expenses, Assets, Review, Quick Expense, and one administrative page, including empty, populated, editing, success, and error states. Record the result in `tmp/ui-verification/` and verify the notes name each page and size, confirm styles and scripts loaded, and state whether the deployed hostname was reachable.

## Workflow follow-up

- Review the artifacts and the visual notes, then archive this change with `/opsx-archive`.
