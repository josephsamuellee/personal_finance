# Tasks

## 1. Schema and data migrations

- [x] 1.1 Add `note` and nullable `exchange` to `securities`, make `identifier` nullable, and replace the single ticker unique index with SQLite partial unique indexes (ticker where exchange is null; ticker+exchange where exchange is present). Verify model tests for shared reuse and ambiguous-ticker coexistence pass, and `db:schema:rollback` then `db:migrate` round-trips cleanly.
- [x] 1.2 Add `adjustment_convention` (default "raw") to `market_prices`, collapse existing duplicates per (security, market date) keeping the latest `retrieved_at`, and add the unique index on (security_id, market_on, currency, adjustment_convention). Verify a migration test proving duplicates collapse and re-rollback is safe.

## 2. Shared security model and forms

- [x] 2.1 Update `Security`: drop the required-name validation, add shared `note`, normalize ticker+exchange, and add a find-or-create-by-identity helper that reuses an existing ticker instead of duplicating. Verify model tests: reuse across accounts, USD default, note shared everywhere.
- [x] 2.2 Rework the security creation form (asset maintenance) to ask only for ticker, optional note, and currency defaulting to USD; official name is no longer entered by hand. Verify integration tests for the form and its validation errors pass.

## 3. Effective market prices

- [x] 3.1 Add `MarketPrice.effective_on(security, date)` (exact-date) next to `usable_on`, plus an upsert helper that updates an existing date's effective price (amount, source, retrieved_at, entered_by) without creating duplicates. Verify model tests: same-day manual update replaces, uniqueness enforced.
- [x] 3.2 Switch manual price entry and `MarketData::Refresh` to the upsert. Verify integration tests: repeated refresh does not accumulate rows; a manual price for an existing date updates that date's effective price.

## 4. HoldingForm and save semantics

- [x] 4.1 Create `HoldingForm` (account, security or new-ticker attributes, note, observed_on, quantity, cost_basis, price, gesture) with server-side intent classification (new / edit / price-only / no-change / verify) and validations: no future dates, historical acknowledgment required for past dates. Verify form-object unit tests for each intent and both date guards.
- [x] 4.2 Implement the transactional save: price-only updates the shared price with no observation; quantity/cost changes record dated observations through existing revise/add helpers (revision history preserved); unchanged saves write nothing; verify is a distinct explicit gesture. Verify model tests for all four paths plus atomic rollback on failure.
- [x] 4.3 Rewire `HoldingsController#update_position` through `HoldingForm` and update existing integration tests (`holdings_request_test`, `interface_test`) that assumed unchanged saves create verification observations. Verify the full controller integration suite passes.

## 5. Unified holding editor UI

- [x] 5.1 Extend the holding editor with the market-price field: prepopulate from `effective_on` only, show an explicit "no price recorded for this date" indication otherwise, and show the source observation date for prepopulated quantity/cost. Verify integration tests for prepopulation and the no-price indication.
- [x] 5.2 Add the historical-date warning with an unchecked acknowledgment checkbox (required before a past-date save) and the date-change reload: dirty edits get an inline keep/discard confirmation before reloading date-appropriate values; date inputs get `max=today`. Verify system tests: past date blocks save without the checkbox, returning to today clears the warning, dirty fields are not silently discarded.
- [x] 5.3 Make holdings directly selectable wherever shown: keep Assets sheet links, add holdings with editor links to `accounts#show` (brokerage account details), and confirm any Home surface that lists holdings links to the editor. Verify a system test selecting a holding from account details opens the editor in one step.

## 6. Account-type behavior

- [x] 6.1 Make "Update balance" the primary action for checking/savings cards and its form prepopulate the latest applicable balance with today's date. Verify integration tests: checking account scenario (prepopulated latest balance, default date today).
- [x] 6.2 Implement brokerage cash: "Record cash" secondary action with dated observations, cash row visible only when the latest applicable amount is nonzero, zero cash hidden with history retained, and no aggregate brokerage balance entry anywhere. Verify integration tests for the no-cash, recorded-cash, and zero-cash scenarios.
- [x] 6.3 Update valuation (`Reporting::Snapshot`, assets card assembly): brokerage value = cash (zero when never recorded) + position values counted exactly once, and missing brokerage cash no longer marks the account or net worth incomplete. Verify model/reporting tests for the three brokerage scenarios and update existing tests that assumed balance-less brokerages are incomplete.

## 7. Combined add-holding workflow

- [x] 7.1 Build the "Add holding" form on a brokerage account: existing-security selector or new ticker, optional shared note, currency default USD, date default today, required quantity and cost basis, and a price field prepopulated from a saved exact-date price. Verify integration tests: saved price reused and overridable, defaults applied.
- [x] 7.2 Wire the coordinated save through `HoldingForm` (transaction across security reuse/creation, holding association, initial observation, price) and block creation with a clear explanation when no price exists for the date and none is entered or fetched. Verify integration tests: existing-security reuse, new-security creation in one save, missing-price rejection with no partial records, atomic failure.

## 8. Historical price import

- [x] 8.1 Add `history(security, from:, to:)` to the `MarketData::Adapter` contract with an AlphaVantage implementation, and a `MarketData::Import` service that upserts fetched prices with full metadata (market date, currency, source, retrieval timestamp, adjustment convention), skips manual prices unless `replace: true`, and is deterministic across repeated/overlapping imports. Verify service tests with a fake adapter: caching, manual protection, explicit replacement, repeated-import determinism.
- [x] 8.2 Add the user-initiated import form to asset maintenance (security, date range, explicit replace-manual choice) and route. Verify integration tests: import on request only, non-trading dates create no records, imported prices reused by reports without new requests.
- [x] 8.3 Surface the effective price date separately from the requested observation date wherever valuation explains its price (editor, snapshot output). Verify tests assert the two dates are distinguishable.

## 9. Integration and visual verification

- [x] 9.1 Run the full suite (`bin/rails test`) and RuboCop; fix fallout from changed save semantics and valuation rules. Verify zero failures and zero offenses.
- [x] 9.2 Walk the four expected workflows visually (update existing holding, add holding, update checking balance, record brokerage cash) on mobile-width and desktop viewports in light and dark mode, including the historical warning, sheet editor, and save confirmations. Verify each completes in the spec's step count with recognizable buttons and no horizontal scrolling.
- [x] 9.3 Cross-check every acceptance scenario in the three delta specs against implemented behavior and recorded test evidence; list any gap as a follow-up. Verify the scenario-by-scenario review is documented in the change folder before archive.

## Workflow follow-up

- Archive the change after implementation and review requirements are satisfied.
- Verify the archived result with `openspec validate --specs --strict`.
