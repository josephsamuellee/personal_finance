# Scenario review

Reviewed 2026-10-24 against the three delta specs, the automated suite, and a live walkthrough of the four expected workflows on `http://127.0.0.1:8090`.

## Visual walkthrough (task 9.2)

| Workflow | Steps taken | Result |
|---|---|---|
| Update existing holding | Assets → VOO → quantity 50→55 → save | Confirmation "Holding saved."; Fidelity value became $29,700 (55 × $540). Editor showed date, quantity, cost basis, and exact-date price in one sheet. |
| Add holding | Assets → Add holding → ticker AAPL, qty 10, basis 1800, price 180 → save | Confirmation "Holding saved."; AAPL appeared under Fidelity; account value became $31,500. Currency defaulted to USD and date to today. |
| Update checking balance | Assets → Update balance → amount prefilled 1250 / date today → 1400 → save | Confirmation; Everyday Checking showed $1,400. |
| Record brokerage cash | Assets → Record cash → 500 → save | Cash row $500 appeared; Fidelity became $32,000 ($31,500 + $500, counted once). |

Viewports and themes:

- Mobile (~375px): stacked cards, bottom navigation, Assets highlighted, `scrollWidth === 375` (no horizontal scroll).
- Desktop (1280px): sidebar navigation, Assets highlighted, cards remain in the content column.
- Dark (system) and Light (Settings → Light): fields, buttons, and cards stay readable; primary/secondary buttons remain distinct.

Historical-date check: opening the VOO editor on 2021-06-01 showed the amber warning "This observation date is in the past", an unchecked acknowledgment checkbox, "No price recorded for 2021-06-01", and pending save "New observation".

Live-server note: the first editor open failed with `uninitialized constant HoldingsController::HoldingForm` because the long-running Puma process had started before `app/forms` existed. The controller now references `::HoldingForm`, and a restarted server loads the editor.

## investment-positions

| Scenario | Evidence | Status |
|---|---|---|
| Security is recorded | `test/models/security_test.rb` "a security requires only a ticker…"; `test/integration/security_form_test.rb` | Pass |
| Existing ticker is reused | `security_test.rb` "an existing ticker is reused"; `add_holding_workflow_test.rb` "an existing security… is reused" | Pass |
| Shared note follows the security | `security_test.rb` "a note change is reflected wherever the security appears" | Pass |
| Ambiguous tickers are distinguishable | `security_test.rb` "the same ticker can exist on different exchanges" | Pass |
| Official name is optional | `security_test.rb` "requires only a ticker"; security form no longer asks for a name | Pass |
| Edit a quantity in place | Desktop editor at 1280px; `holdings_request_test.rb` editor contents | Pass |
| Edit a holding in a sheet | Mobile-width sheet editor walked live | Pass |
| Holding opens from Home | Home does not list individual holdings today (design D7: deferrable). No Home surface to click. | Gap — no current Home holdings list |
| Holding opens from its brokerage account | `holding_date_test.rb` "selecting a holding from the brokerage account details…" | Pass |
| Editor shows the holding | `holdings_request_test.rb` "the holding editor names the pending save, shows the price field…" | Pass |
| Date control is visible | Live editor; integration editor tests | Pass |
| One form shows holding and price together | Live editor showed date, qty, basis, price | Pass |
| Holdings sit inside their account | Live Assets: VOO/AAPL under Fidelity | Pass |
| Cash account has no security rows | Everyday Checking card: balance + Update balance only | Pass |
| Brokerage card offers holding and cash actions | Live: Add holding + Record cash | Pass |
| Reporting date stays available | Live reporting-date control above cards | Pass |
| Changed values are an edit | `holding_form_test.rb` classification + quantity-change save | Pass |
| Another date is a new observation | `holding_form_test.rb` "a date with no observation classifies as a new observation" | Pass |
| Backdated save appears on that date | `holdings_request_test.rb` "a backdated save is stored on the selected date" | Pass |
| Price-only update | `holdings_request_test.rb` / `holding_form_test.rb` price-only path | Pass |
| Holding update leaves price alone | `holding_form_test.rb` "a quantity change… leaves the price alone" | Pass |
| Unchanged save records nothing | `holdings_request_test.rb` "an unchanged save records nothing" | Pass |
| Verification is an explicit action | Distinct "Verify holding" button; form-object verify gesture | Pass |
| Cancel changes nothing | `holdings_request_test.rb` cancel does not write | Pass |
| Checking account primary action | `account_type_behavior_test.rb`; live Update balance with 1250/today | Pass |
| Brokerage value is derived | Live Fidelity showed holdings, no aggregate balance field | Pass |
| Aggregate balance is not double counted | `reporting_test.rb` brokerage cash + positions; live $32,000 = 29700+1800+500 | Pass |
| No brokerage cash | `account_type_behavior_test.rb`; live before cash save | Pass |
| Brokerage cash recorded | Live $500 cash row; integration recorded-cash test | Pass |
| Zero cash is hidden but kept | `account_type_behavior_test.rb` "zero brokerage cash hides the cash row but keeps its history" | Pass |
| Add an existing security | `add_holding_workflow_test.rb` reuse + prefilled price | Pass |
| Add a new security | Live AAPL create-in-one-save; matching integration test | Pass |
| Missing price blocks creation | `add_holding_workflow_test.rb` missing-price rejection | Pass |
| Save is atomic | `holding_form_test.rb` / `add_holding_workflow_test.rb` failed combined save | Pass |
| Prepopulation from the latest applicable observation | Live editor: qty 50 / basis 18000 from 2026-10-23; source date labeled | Pass |
| Historical date ignores future observations | `holding_form_test.rb` + date-aware editor (2021 form did not use 2026 qty) | Pass |
| Exact-date price only | `holdings_request_test.rb` prefills exact-date price | Pass |
| No exact-date price | Live 2021-06-01: "No price recorded for 2021-06-01." | Pass |

## market-valuation

| Scenario | Evidence | Status |
|---|---|---|
| User supplies a price | `market_price_entry_test.rb`; editor price field | Pass |
| Same-day manual update | `market_price_test.rb` "a same-day manual update replaces…" | Pass |
| Shared valuation | `market_price_test.rb` "a manual price affects every account holding…" | Pass |
| Cash and positions are the brokerage assets | `reporting_test.rb`; live $32,000 | Pass |
| Brokerage without cash is not incomplete | `reporting_test.rb` "a brokerage without recorded cash…" | Pass |
| Duplicate effective price is prevented | Unique index + `market_price_migration_test.rb` | Pass |
| Historical import caches real market dates | `market_data_import_test.rb` | Pass |
| Cached prices are reused | `historical_price_import_test.rb` reports reuse the cache | Pass |
| Import only on request | `historical_price_import_test.rb` "only imports on request" | Pass |
| Manual override protection | `market_data_import_test.rb` preserves manual prices | Pass |
| Explicit replacement | `historical_price_import_test.rb` replace choice | Pass |
| Repeated imports are deterministic | `market_data_import_test.rb` | Pass |
| Non-trading date gets no price | import tests invent no weekend/holiday prices | Pass |
| Requested date differs from effective price date | `reporting_test.rb` / `holdings_request_test.rb` distinguish the two dates | Pass |
| Adjusted prices are labeled | import stores `adjustment_convention` | Pass |

## household-interface

| Scenario | Evidence | Status |
|---|---|---|
| Today's update needs no acknowledgment | Live today-save of VOO/checking/cash required no checkbox | Pass |
| Historical update requires acknowledgment | `holdings_request_test.rb` / `holding_date_test.rb` past-date rejection | Pass |
| Acknowledgment starts unchecked | Live 2021 editor: `checked: false` | Pass |
| Returning to today clears the warning | `holding_date_test.rb` "clears when back to today" | Pass |
| Future dates are rejected | `holding_form_test.rb` / `holdings_request_test.rb` | Pass |
| Date change reloads applicable values | `holding_date_test.rb` reload behavior | Pass |
| Unsaved changes are not silently lost | `holding_date_test.rb` "preserves unsaved edits" | Pass |

## Follow-ups

1. **Home does not list individual holdings**, so "Holding opens from Home" has no current surface. Design D7 already deferred this. Add holding rows to Home only if we want that path; Assets and account details already satisfy one-click editing.
2. **Development server must be restarted** after adding `app/forms` (or any new autoload directory). The `::HoldingForm` qualifier avoids the nested-constant miss after reload.
3. Editor primary-button label stays "No changes" until a server round-trip; the save still classifies intent correctly. Optional later: update the label client-side as fields change.
