# Design

## Context

See proposal.md for why this change exists. Home, Expenses, Assets, and Review are server-rendered ERB. Charts use ECharts through `chart_controller.js`, which already redraws when `data-appearance` or `html.dark` changes. Tracked spending is `Expense.tracked` via `Reporting::Spending`: `month_to_date` is the current month through the reporting date, and `baseline` is the three completed months before that. Appearance is `system`, `light`, or `dark` on the user, mirrored to the `appearance` cookie, and applied by the blocking head script. Button-styled links use `.ui-button`, `.ui-button-secondary`, and `.ui-nav`. A secondary button currently uses the same fill as `.ui-card`, so it blends into the card.

## Goals / Non-Goals

**Goals:**

- One card canvas for the four status pages, with the Home plots and the existing Home figures in the spec order.
- A 4px link band that is visible on both the page and a card in light and dark.
- Chart series colors that follow the active appearance.

**Non-Goals:**

- Changing valuation, observation gestures, expense kinds, or the appearance storage.
- Restyling forms, Quick Expense, Settings, Compare, the benchmark, or the saved-review detail page.
- Adding a component framework or a downloaded font.

## Decisions

1. **Compose status pages from four card roles on top of `.ui-card`.** A metric card is a label, one primary amount, optional supporting amounts, and at most one button-styled link. A ledger card is name-left, amount-right rows. A chart card is a title plus one plot in a well. A utility card is a title plus stacked button-styled links. Pairs use a two-column grid from 768px and one column below that. Chart cards span the grid.
   - Alternative: leave each page as its own stack of one-off markup. Rejected because Expenses and Review would drift from Home and Assets.

2. **Keep the existing Home figures and add the two plots in the spec order.** Previous-month spending is `Reporting::Spending.total` for the full calendar month before the reporting date. The spending chart covers that previous month, the month before it, and the current month through the reporting date. Cumulative spending restarts at each month boundary. Each calendar day in those months is a bin; a day with no tracked expenses is zero. The series uses `Expense.tracked`, so transfers stay out and refunds stay negative. Net worth keeps `Reporting::Series.net_worth_history` and stays on observation dates.
   - Alternative: chart the same three completed months as the baseline average. Rejected because the dashboard is about the current month beside the days that built it. The baseline average stays the completed-month calculation.

3. **Extend the chart controller with a second series mode.** Net worth remains one line. Spending receives daily points and cumulative points and draws bars on the right value axis and a line on the left. Colors come from computed custom properties so a theme change repaints an existing chart: daily bars `sky-700` / `sky-300`, cumulative and net-worth lines `slate-900` / `slate-100`, axes `slate-400` / `slate-500`, plot well `slate-50` / `slate-950`. The well is the chart card's inner surface, one step from the card.
   - Alternative: a second chart library. Rejected because ECharts already follows appearance.

4. **Group Assets by account without a new value formula.** Each visible account is one card. Its sum is that account's balance on the reporting date, plus the market value of its positions when it has holdings. An unknown price or balance stays unknown and labels the card sum incomplete, using the snapshot rules already on the page. Holdings are indented rows. The holding name is a text link that opens the current editor (`edit` query, in-place at `lg`, sheet below). Update balance stays a button-styled link opening the current balance editor. Add holding on a card opens the existing security maintenance screen with that account selected. The two utility cards hold the current account links and the current security, price, and securities links. The separate portfolio-summary block and the separate holdings table leave this page. The reporting date form stays above the grid. One editor and one balance editor remain.
   - Alternative: keep balances and holdings as two lists inside cards. Rejected because the wireframe nests holdings under the account that owns them.

5. **Put a 4px band on button-styled links only.** `a.ui-button`, `a.ui-button-secondary`, and `a.ui-nav` get a 4px outer shadow and a 4px margin so neighboring bands do not touch. Light band is `slate-200`. Dark band is `slate-700`. Primary fill stays `slate-900` with white text in light, and `slate-100` with `slate-950` text in dark. Secondary fill stays white with a `slate-700` border in light, and `slate-800` with a `slate-300` border in dark. Focus is a sky ring drawn outside the band (`sky-800` in light, `sky-300` in dark). Submit buttons keep their fill and do not gain the band, because they change data rather than navigate. Text links stay sky and underlined.
   - Alternative: paint the band behind every button, including Save. Rejected because the spec applies the band to links.

6. **Page and card surfaces.** Light page `slate-50`, card white, labels `slate-600`, body text `slate-900`. Dark page `slate-950`, card `slate-900`, labels `slate-300`, body text `slate-100`. These follow `.dark` on `html`, which Settings already toggles for Light, Dark, and System.

## Risks / Trade-offs

- [Assets tests expect a balances section and a holdings table] → Update those assertions to account cards, and keep the observation examples on the editor.
- [The unarchived `application-ui-ux` change still requires summary, then balances, then holdings] → Archive or sync that change before this one. Do not edit its artifacts here.
- [A 4px shadow can cover the focus ring] → Draw the sky focus ring outside the band and check it in both themes.
- [Daily bins for three months are denser than the current net-worth series] → One ECharts option with two axes is enough. Do not add a second request.
- [Account sum could diverge from Home net worth if debt sign or unknown prices are recomputed locally] → Read the account value from the snapshot rules already used for net worth.

## Migration Plan

Views, CSS, the chart controller, and one reporting method. No schema change. Deploy assets with the views. Rollback is reverting the change. Stored expenses, observations, prices, and appearance stay valid.

## Open Questions

None. The chart window, the link band, and the account-card contents are decided above.
