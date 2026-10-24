# Proposal

## Why

Home, Expenses, Assets, and Review still read as stacked headings, so the household's numbers, charts, and next steps do not form one dashboard. The status pages should share a card canvas, keep the data already on Home, and stay readable in the configured light, dark, and system appearance.

## What Changes

- Home becomes a dashboard of metric, ledger, chart, and utility cards. It keeps estimated net worth, liquid assets, tracked spending, the three-month average, estimated surplus, asset allocation, net worth history, and contextual insights. It adds previous-month tracked spending and a three-month spending chart.
- The spending chart uses two axes: cumulative tracked spending within each month on the left, and each day's tracked spending on the right. The net worth chart stays a line across every recorded observation date.
- Assets groups each account into a ledger card with that account's holdings and an add-holding link. Account and security maintenance move into two utility cards. The reporting date stays above the cards.
- Expenses and Review use the same card types for the totals, lists, and actions already on those pages. Record names, expense rows, review dates, and decision descriptions stay text links.
- A button that navigates has a 4px band in a surface color different from the page and from the card, in both light and dark. Chart series and text follow the active appearance.
- **BREAKING:** The Assets main page no longer shows a separate balances list followed by a separate holdings table. Holdings appear inside their account cards.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `household-interface`: Status pages use the shared card canvas, link-button bands, and the light/dark surface palette.
- `financial-reporting`: Home also shows previous-month tracked spending and a dual-axis chart of the last three months of spending.
- `investment-positions`: The Assets main page presents accounts as ledger cards while keeping the existing observation editor.

## Impact

- Views for Home, Expenses, Assets, and Review, plus the shared card and button styles in `app/assets/tailwind/application.css`.
- A daily spending series for the chart. Net worth history, valuation, expense definitions, observation gestures, and appearance storage stay as they are.
- Chart colors update when `html.dark` changes. Settings continues to offer Light, Dark, and System.
- Expense forms, the holding editor's save rules, Quick Expense, Settings, Compare, the benchmark, and the saved-review detail page stay work pages.
- The completed, unarchived `application-ui-ux` change still describes Assets as a portfolio summary, then balances, then a holdings table. Archive or sync that change before this one so the account-card composition is the later spec text. Do not edit that change's artifacts from this change.
