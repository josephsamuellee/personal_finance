# Proposal

## Why

The asset workflows force users to understand the database layout — Assets, Accounts, Securities, Holdings, Observations, and Manual Prices are separate pages, brokerage accounts expose an aggregate balance alongside their holdings, securities require a manually typed official name, and the holding editor cannot update the shared market price. Users should find an account or holding, open one form, and save once.

## What Changes

- **Account-type-specific behavior**: checking and savings accounts get a primary "Update balance" action with the latest balance and today's date prepopulated. Brokerage accounts are valued from their holdings plus optional uninvested cash; they no longer expose an independently entered aggregate balance.
- **Brokerage cash**: cash becomes an optional, dated observation recorded through a secondary "Record cash" action. Never-recorded cash counts as zero and shows no row; recorded cash shows only while its effective balance is nonzero; zero cash keeps its history but hides from the default overview. Cash is counted exactly once in valuation.
- **Shared securities**: a security is a shared entity reusable across accounts. The user enters only a ticker (plus an optional internal note; currency defaults to USD). The official name is optional and can be auto-populated from the market-data provider. Identity supports optional exchange/provider identifiers to disambiguate duplicate tickers. The internal note is shared everywhere the security appears.
- **Unified holding editor**: the editor adds a market-price field alongside observation date, quantity, and cost basis. Values prepopulate from the latest applicable observation on or before the selected date; the price prepopulates from the exact-date saved price, with a clear indication when no exact-date price exists (no silent cross-date substitution).
- **Save only intentional changes**: a price-only edit updates the shared price without creating a holding observation; a quantity/cost change records a dated holding observation; saving unchanged values creates nothing. Verifying an unchanged holding becomes a distinct explicit action. Holding observations keep revision history.
- **Combined add-holding workflow**: "Add holding" on a brokerage account lets the user pick an existing security or type a new ticker, with note, currency, date, quantity, cost basis, and price in one form. A saved price for the date is reused automatically; a missing price must be entered or fetched before the holding can be created. The save is transactional across security reuse/creation, holding association, initial observation, and price.
- **Historical-date handling**: forms default to today; a past observation date requires a prominent warning plus an unchecked acknowledgment checkbox before saving; changing the date reloads date-appropriate values without silently discarding unsaved edits; future dates are rejected.
- **Shared market prices**: one effective price per security and market date (uniqueness enforced, duplicates migrated). Manual entry for an existing date updates that date's effective price. New historical-price import for a security and date range caches prices with source metadata in SQLite; imports never silently overwrite manual prices (explicit replacement required); non-trading dates get no invented prices; valuation distinguishes the requested date from the effective price date.
- **Simplified navigation**: common operations (update a holding, add a holding, update a checking balance, record brokerage cash) each complete from Assets in one or two steps, using the existing card/sheet UI patterns.

## Capabilities

### New Capabilities

None — the change tightens existing capabilities rather than introducing new ones.

### Modified Capabilities

- `investment-positions`: account-type-specific actions and brokerage-cash semantics; shared security identity, optional official name, and shared internal note; unified holding editor with exact-date price field and prepopulation; intentional-change-only saves with a distinct verify action; combined add-holding and security creation workflow with coordinated transactional save.
- `market-valuation`: effective-price uniqueness per security and date; manual update semantics with provenance; historical price import, caching, and market-calendar handling; manual-override protection on imports; brokerage valuation from holdings plus optional cash counted once.
- `household-interface`: historical-date warning and acknowledgment in dated financial forms; date-aware form reload that preserves unsaved changes; account-type primary actions surfaced per the shared visual system.

## Impact

- **Models/migrations**: `securities` (optional name populated from provider, shared `note`, optional exchange/provider identifier for identity, relaxed ticker uniqueness); `market_prices` (unique effective price per security/date, deduplication of existing duplicates, adjustment-convention metadata); `accounts`/`account_observations` (brokerage balance observations re-semantics as uninvested cash; nothing destroyed). All migrations preserve existing data.
- **Controllers/views**: `HoldingsController` (unified editor with price, save-only-changes gestures, combined add-holding create, brokerage cash recording), `SecuritiesController`/`MarketPricesController` (combined creation, manual update-in-place, historical import), `asset_maintenance` remains for advanced operations, Assets/Home/account cards link holdings directly to the editor.
- **Services**: `MarketData` gains a historical-quote adapter method and manual-override-aware import; `Reporting::Snapshot` and assets valuation treat brokerage cash as optional (never-recorded cash is zero, not unknown) and never double-count brokerage value.
- **Tests**: integration tests for account-type behavior, unified editor saves, combined creation, price uniqueness, import/override, and historical-date confirmation; system tests for the sheet editor, warning/acknowledgment, and responsive/dark-mode behavior.
- **Out of scope**: investment transaction accounting, tax lots, dividends, credit-card reconciliation, bank sync, decision-log redesign, new permission roles, replacing Rails/SQLite/Hotwire, unrelated dashboard redesign.
