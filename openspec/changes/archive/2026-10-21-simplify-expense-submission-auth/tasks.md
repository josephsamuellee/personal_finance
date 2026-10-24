# Tasks

## 1. Public Quick Expense form

- [x] 1.1 Add `GET /quick-expense` and `POST /quick-expense` on a controller that skips the session filter only for those two actions, and verify an anonymous GET returns 200 with amount, category, date, merchant, notes, and an optional receipt field and without an existing expense, account, holding, or spending total
- [x] 1.2 Render that page without the sidebar or bottom navigation when no session is present, point the header Quick Expense link at it, and verify the anonymous page has a sign-in link and does not show Home, Expenses, Assets, or Review navigation
- [x] 1.3 Save a spending expense from amount and a typed category name, default the date to today in `America/Los_Angeles`, and verify the stored expense has that amount and category, no merchant, and no receipt
- [x] 1.4 Accept an edited date, optional merchant, notes, and an image or PDF receipt, and verify those values are stored and a missing receipt still saves
- [x] 1.5 Redirect a successful save back to the blank form with the notice "Expense saved. You can enter another.", and verify the response does not include the saved amount, a spending total, or an earlier expense
- [x] 1.6 Update the signed-in system flow to fill the typed category on this form, and verify that flow still saves the expense and can edit it after signing in

## 2. Submission boundary

- [x] 2.1 Force `kind` to spending and drop refund, transfer, account, original-expense, and record-id parameters, and verify an existing expense is unchanged and the new row has no refund link and no account link
- [x] 2.2 Ignore a client-supplied user id, leave `created_by` empty when there is no session, attribute a submission to the session user when a session already exists, and verify both cases
- [x] 2.3 Reject a missing category, a missing or zero or non-numeric amount, an unparseable date, and a non-image non-PDF receipt, and verify nothing is stored and the form keeps the entered amount without other household records
- [x] 2.4 Apply the category, merchant, notes, and date bounds from the design, and verify an out-of-bounds value is rejected without storing an expense

## 3. Request protection

- [x] 3.1 Keep CSRF enforcement on the public POST, and verify a submission without the request token stores nothing
- [x] 3.2 Throttle `POST /quick-expense` to 10 requests per client address per 60 seconds with an in-memory store, and verify the eleventh request returns 429, stores no additional expense, and includes no household financial data
- [x] 3.3 Require a Rails session for the expense list, expense detail, expense edit, expense update, expense delete, home, assets, and a receipt file, and verify each anonymous request is refused without revealing amounts or the file

## 4. Regression

- [x] 4.1 Run the full test suite, and verify the new anonymous-entry tests, the protected-route tests, the throttle test, and the existing signed-in household flow pass together

## Workflow follow-up

- Archive this change after review. `household-finance-baseline` is still unarchived, so reconcile its session-required financial routes and create attribution with `public-expense-entry` at archive time.
