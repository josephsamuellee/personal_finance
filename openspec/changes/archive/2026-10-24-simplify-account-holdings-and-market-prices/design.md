# Design

## Context

The app already has the right data primitives: `Account` (typed `checking/savings/brokerage/debt/property`), shared `Security` (unique ticker, required `identifier` shown as "Name", required currency), `MarketPrice` (per security/date, non-unique index), and dated, sequenced, revisable observations (`AccountObservation` for balances, `PositionObservation` for holdings) with revision history via `Revisable`. Assets renders per-account cards with a sheet/in-place holding editor; security/price/corporate-action forms live on a separate `asset_maintenance` page; prices refresh through `MarketData::Refresh` (AlphaVantage `GLOBAL_QUOTE`).

The problem is surface area, not schema: brokerage balances are entered as aggregates, securities demand a manually typed name, the holding editor cannot touch prices, saves always write observations, and adding a holding spans three pages. See proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- One form per common operation: update holding (with price), add holding + security, update cash-account balance, record brokerage cash.
- Never double-count brokerage value; treat unrecorded brokerage cash as zero, not unknown.
- One effective market price per security/date; imports never clobber manual prices.
- Preserve all existing dated observations, revision history, and auth behavior; migrations are additive or deduplicating, never destructive of history.

**Non-Goals:** transaction/tax-lot/dividend accounting, bank sync, background price jobs, new permissions, framework changes (see proposal - Out of scope).

## Decisions

### D1. Security identity: reuse `identifier` as optional official name; add `exchange` and `note`
- Keep `securities.identifier` but make it optional and relabel it as the official name (views already label it "Name"). It gets auto-populated by the market-data adapter when a quote/history response includes one; users never type it.
- Add nullable `note` (shared internal note) and nullable `exchange` (MIC code).
- Replace the single `unique: true` on ticker with two SQLite partial unique indexes: `ticker` where `exchange IS NULL`, and `(ticker, exchange)` where `exchange IS NOT NULL`. SQLite treats NULLs as distinct, so this preserves the common single-VOO case while allowing ambiguous tickers to coexist.
- Alternative considered: a separate `provider_identifiers` join table — rejected as premature; a nullable `exchange` column covers the SEC-001 requirement without a new concept.

### D2. Brokerage cash: reuse `AccountObservation`, change semantics at the edges
- No new table. A brokerage account's `AccountObservation` rows are its uninvested-cash observations. Existing brokerage balance history stays valid as cash history.
- UI: brokerage cards show "Record cash" (secondary action) instead of "Update balance" (primary for checking/savings). Checking/savings forms prepopulate the latest applicable amount and default the date to today.
- Visibility rule: a cash row renders only when the account has any cash observation AND its latest applicable amount on the reporting date is nonzero. Zero-cash history is retained, hidden from the default overview.
- Valuation (`Reporting::Snapshot` and `HoldingsController#account_card`): for brokerage accounts, missing cash is `0`, not an unknown/incomplete component. Brokerage value = cash (0 when unrecorded) + Σ position values; no aggregate total is ever added on top. Non-brokerage account behavior is unchanged (missing balance stays unknown).

### D3. One `HoldingForm` form object for edit, verify, and combined creation
- New `HoldingForm` (ActiveModel, `app/forms/holding_form.rb`) wrapping account, security (existing or new-ticker attributes), note, observed_on, quantity, cost_basis, price, and gesture (`new` / `edit` / `verify` / `create`).
- It computes intent server-side by comparing submitted values against the latest applicable observation and the exact-date effective price: price-only → update price only; quantity/cost change → dated observation (via existing `revise_current!`/`add_another!`, preserving revision history); unchanged → persist nothing; `verify` → record the explicit verification observation. This replaces the current editor's inferred "Verify" default gesture.
- Combined creation (Add holding) uses the same object: find-or-create the shared security inside the save, require an exact-date price (prepopulated when present; otherwise user-entered or fetched), and wrap security + holding + observation + price writes in one `ActiveRecord::Base.transaction` so partial failure leaves nothing behind.
- Exact-date lookup: add `MarketPrice.effective_on(security, date)` (exact `market_on` match) alongside the existing `usable_on` (on-or-before). The editor prepopulates only `effective_on`; `usable_on` continues to serve valuation.

### D4. Effective price uniqueness with a deduplicating migration
- Add nullable `adjustment_convention` (default `"raw"`) and enforce a unique index on `(security_id, market_on, currency, adjustment_convention)`.
- Migration first collapses existing duplicates per `(security_id, market_on)` (keep the row with the latest `retrieved_at`), then adds the index. Manual entry becomes an upsert: updating an existing date's effective price updates that row (amount, source, retrieved_at, entered_by) — provenance preserved, no `Revisable` history required (matches PRICE-002).
- `MarketData::Refresh` changes from `create!` to the same upsert so refreshed today-prices update rather than accumulate.

### D5. Historical import as a synchronous, opt-in adapter method
- Extend `MarketData::Adapter` with `history(security, from:, to:)` returning records with amount, market_on, currency, and adjustment convention; implement for AlphaVantage (`TIME_SERIES_DAILY(_ADJUSTED)`) behind the existing `MarketData::ProviderError` contract. No vendor is hardcoded at the service level — the adapter stays swappable.
- New `MarketData::Import` service: user supplies security (or ticker) and a date range; results are upserted subject to D4 uniqueness, skipping dates that already hold a manual-source price unless `replace: true` is explicitly chosen. No jobs/scheduling — same synchronous pattern as refresh, only on explicit request.
- Non-trading dates simply return no rows; nothing synthesizes them. Valuation keeps using `usable_on` and already reports the price date separately from the observation date.

### D6. Historical-date confirmation and predictable date reload
- Server-side: `HoldingForm` (and the balance/cash form) reject `observed_on` in the future and require a truthy `historical_ack` param when `observed_on < Date.current`. Date inputs get `max=today`.
- Client-side: a warning banner with an unchecked checkbox appears under the date field whenever the selected date is past (rendered server-side on the form, toggled by the existing `sheet`/editor markup; removing the past date removes it).
- Date-change reload: extend the editor with a small Stimulus behavior — when the observation date changes and any field is dirty, show an inline confirm ("Reload values for this date? Your edits will be kept/discarded") before the existing GET reload; clean forms reload directly. No silent loss.

### D7. Navigation surface
- Assets account cards: primary per-type action (Update balance / Add holding), Record cash secondary on brokerage; holdings stay text links opening the existing sheet editor. The separate `asset_maintenance` page survives for corporate actions, manual standalone price entry, and the new historical import — but the common path never visits it.
- `AccountsController#show` gains the account's holdings with direct editor links so "brokerage account details" satisfies one-click holding access.
- Home needs no structural change: the spec's "wherever individual holdings are displayed" applies to surfaces that show holdings; today that is Assets and account detail.

## Risks / Trade-offs

- [Migration collapses duplicate market prices] → Keep the latest `retrieved_at` row per `(security_id, market_on)` and run `Backup::Snapshot` first; duplicates carry no distinct semantics today (`usable_on` already picks the newest).
- [SQLite partial unique indexes need explicit `where:` clauses] → Rails supports them; verify with `db/schema.rb` round-trip in tests.
- [Changing save semantics (unchanged form no longer verifies) contradicts existing tests/spec language] → The delta specs modify `Observation intent`; tasks explicitly update `interface_test.rb` and `holdings_request_test.rb` expectations alongside behavior.
- [Server-inferred intent could misclassify a legitimate same-value re-entry] → "No change" is exactly the intended no-op per HOLD-003; explicit `verify` gesture remains available for verification.
- [Import rate limits / provider outage mid-range] → Same partial-failure reporting pattern as refresh: report failed securities, keep cached prices.
- [Brokerage accounts previously "incomplete" without a balance now show as valued] → Intended (spec: unrecorded cash is zero); existing tests asserting incompleteness for balance-less brokerages must be updated in tasks.

## Migration Plan

1. Deploy schema migration (dedupe + unique index, new columns) and code together — the upsert paths are written against the new uniqueness from the start.
2. Rollback: `db:rollback` restores the pre-index schema; dedupe is the only data-affecting step, so pair the deploy with a fresh `Backup::Snapshot`.
3. No data backfill is required for brokerage cash (existing balance rows are valid cash rows) or securities (existing `identifier` values become optional names).

## Open Questions

- Should Home's asset-allocation card eventually list individual holdings (giving the Home→holding path a concrete surface)? Deferrable; the spec covers "wherever holdings are displayed."
- AlphaVantage's adjusted-vs-raw series choice per security — the `adjustment_convention` column stores whichever is imported; a UI toggle can come later without schema change.
