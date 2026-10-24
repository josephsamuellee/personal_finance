# Tasks

## 1. Surfaces and link bands

- [x] 1.1 Apply the light and dark page, card, label, and text colors from the design, and add a 4px outer band plus margin on `a.ui-button`, `a.ui-button-secondary`, and `a.ui-nav`. Draw the sky focus ring outside that band. Verify a system test that, in Dark, a primary navigation link's box shadow is 4px and its band color differs from the card background, and that keyboard focus remains visible.

## 2. Spending and net-worth charts

- [x] 2.1 Add a three-month daily spending series through `Expense.tracked` for the current month through the reporting date and the two calendar months before it. Include a zero bin for every day, restart the cumulative total at each month boundary, exclude transfers, and keep refunds negative. Verify a model or service test for a zero day, a transfer excluded from that day, a negative refund, and a cumulative total that restarts at the next month.
- [x] 2.2 Teach the chart controller a spending mode with daily bars on the right axis and a cumulative line on the left, and keep net worth as one line on observation dates. Read bar, line, axis, and plot-well colors from the active theme and redraw when appearance changes. Verify a system test that choosing Dark changes the spending chart's series color away from the light-theme color without a manual reload.

## 3. Home dashboard

- [x] 3.1 Rebuild Home in the spec order: net worth, liquid assets beside current-month and previous-month spending, the spending chart, net worth history, the three-month average beside surplus, allocation beside insights, then compare, the benchmark, and the latest review when one exists. Use metric, chart, ledger, and utility cards. Keep allocation names and the latest review as text links. Verify an integration test for that order, both spending amounts, both chart payloads, and that compare is a button-styled link.

## 4. Asset account cards

- [x] 4.1 Replace the separate balances list, holdings table, and portfolio-summary block with one card per account. Show the account value and its holdings, label an incomplete sum, and keep the reporting date above the grid. A holding name opens the existing editor as a text link. Update balance and add holding are button-styled links. Add holding opens security maintenance with that account selected. Verify an integration test that a holding is inside its account card, a cash account shows its balance, the reporting date is present, and the security, price, and corporate-action forms are absent.
- [x] 4.2 Add the account-maintenance and security-maintenance utility cards, and keep the single holding editor and balance editor. Verify the existing holding and balance save tests still return 422 with the entered values, and that a successful holding save still redirects with the current confirmation.

## 5. Expenses and Review cards

- [x] 5.1 Present the Expenses month total, category ledger, expense ledger, three-month average, and CSV import as cards. Keep each expense row a text link and the record action a button-styled link. Verify an integration test for those cards and for the row remaining a text link.
- [x] 5.2 Present Review as cards for the save action, saved reviews, decisions, and the decisions and compare links, and keep the note that opening the page does not save a review. Review dates and decision descriptions stay text links. Verify an integration test that opening Review creates no review and that a saved review date is a text link.

## 6. Dashboard integration

- [x] 6.1 Run `bin/rails test` and `bin/rails test:system`. Inspect Home, Expenses, Assets, and Review at 375×812, 390×844, 768×1024, and 1440×900 in Light and Dark. Check card pairing, both Home plots, link bands, focus, text links, and the absence of horizontal scrolling. Record the result in `tmp/ui-verification/`. Do not mark this task complete from the test suite or CSS classes alone.

## Workflow follow-up

- Archive or sync `application-ui-ux` before this change so its balances-then-holdings Assets order is not the later spec text. Do not edit that change's artifacts.
- Review the artifacts and the visual notes, then archive this change with `/opsx-archive`.
