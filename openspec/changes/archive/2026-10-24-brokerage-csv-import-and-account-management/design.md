# Design

## Context

Expense CSV already has upload → session draft (`ExpenseImportDraft` in `tmp/imports`) → preview → transactional confirm, plus `ImportBatch`. Holdings persistence already exists via `HoldingForm` (create/revise, exact-date prices, historical ack, no-op when unchanged). Securities resolve with `find_or_create_by_identity!(ticker:, exchange:)`. Prices are unique on `(security, market_on, currency, adjustment_convention)`. Accounts archive with `archived_at` and `available_for_entry`, but there is no restore, and `Reporting::Snapshot` still includes archived accounts' positions (and observed cash) in today's net worth.

See proposal.md for motivation. This change stacks on the implemented (not yet archived) `simplify-account-holdings-and-market-prices` behavior.

## Goals / Non-Goals

**Goals:**
- One holdings-CSV planner that reuses holding/security/price writes instead of a parallel ledger.
- Fail-closed validation (whole file), atomic commit, frozen session date, stale-preview revalidation.
- Archive/restore with as-of reporting; 2×2 brokerage actions; account-scoped refresh that does not clobber manuals.

**Non-Goals:** changing expense CSV mapping/exclude-invalid-rows; adding an `exchange` CSV column in this change; account-specific price tables; reversing a holdings import batch in this change (traceable batch only).

## Decisions

### D1. Separate holdings importer, same draft/batch pattern
- New `HoldingCsv` parser and `HoldingsImportsController` nested under `accounts/:account_id/holdings_imports` (new, create, preview, confirm, cancel, template). Never share `ExpenseCsv` or expense routes.
- Draft JSON in `tmp/imports` keyed by session token, including `account_id`, `captured_on`, filename, planned rows, and authorized price-conflict ids. Capture `Date.current` (app time zone America/Los_Angeles) at upload; do not refresh it on confirm.
- Extend `ImportBatch` with `kind` (`expenses` default, `holdings`) and optional `account_id`. Holdings confirm creates a holdings batch for traceability; reversal of holdings batches is out of scope (observations are revisable history, not discarded expenses).

### D2. Strict parse; identity without an exchange column
- Headers must match exactly, in order. Dates: `Date.iso8601` only (no `MM/DD/YYYY` from expense import). Numbers: `BigDecimal` after stripping `$` and `,`; reject non-numeric, negatives, and empty required fields. UTF-8. Max 1 MB / 500 rows (document on the upload screen); oversize is a file-level error.
- Ticker resolution: `Security.where(ticker: normalized)` — 0 rows → create with `exchange: nil`, currency default USD; 1 row → reuse; 2+ rows → ambiguous, block. Do not invent an exchange from the CSV.
- Blank note → leave `security.note` unchanged. Nonblank note differing from current → planned shared-note update, disclosed in preview.
- Duplicate key inside the file: resolved security id + observation date.

### D3. Plan rows through HoldingForm, commit in one transaction
- Each valid row becomes a `HoldingForm` (`gesture: "create"` for new account/security association, `"save"` otherwise) with captured/parsed date, quantity, cost basis, and price. Intent `:no_change` is a preview no-op and is skipped on commit.
- Same-date existing observations use `revise_current!` (keeps sequence, writes revision). Do not call `add_another!` from CSV.
- Price: blank → `MarketPrice.effective_on`; missing → row error (optional explicit fetch uses existing `MarketData` quote into the draft, still no write until confirm). Equal price → reuse. Different price → conflict until the user checks that row's replace control; then `upsert_effective!` with source `manual` (CSV is a user-supplied price).
- Historical ack: if any planned `observed_on < captured_on`'s "today" at confirm time... actually use `Date.current` for "is this historical" at confirm, but default blank dates from `captured_on`. One checkbox for the batch.
- Confirm: reload securities/prices/observations; if any planned conflict/no-op/error classification changed, re-render preview with an explanation. Else `ActiveRecord::Base.transaction` around batch + all form saves. Partial exception rolls back.

### D4. New-account fork
- `AccountsController#create` for `brokerage` redirects to `new_account_holdings_import_path(account)` with Skip linking to `account_path` / Assets. Non-brokerage create stays on `accounts_path`.
- Skip, cancel, and validation failure never `destroy` the account.

### D5. Archive as-of and restore
- Keep `archived_at` datetime. Add `unarchive!` (`archived_at: nil`). Remove Account on the 2×2 is `button_to` with a confirm dialog (archive, not DELETE destroy of rows).
- Snapshot/Assets active totals: include an account iff `archived_at.nil? || archived_at.to_date > on`. Positions use the same rule via the account. History pages and an archived-account show remain reachable from Manage accounts (index already lists archived).
- Do not convert existing brokerage `AccountObservation` rows; they remain cash observations.

### D6. Account-scoped refresh
- `MarketData::Refresh` accepts `account:` and `on:` (default today). Securities: `PositionObservation.current_on` per pair on that account/date with `quantity > 0`. Distinct securities, one `quote` each.
- Skip upsert when `existing&.manual?` (same as `MarketData::Import`). Report skipped manuals, updates, and failures.
- Alpha Vantage free tier is request-limited (on the order of a handful per minute / tens per day). Sequential quotes; if today's provider-sourced effective price already exists for the security, reuse it and do not call the API. Do not promise a full-market backfill from this button.
- Household Assets "Refresh Prices" can keep working; route it through the same skip-manual + cache-reuse behavior so manuals are consistent.

### D7. 2×2 grid
- On `accounts#show` for active brokerage only: CSS grid `grid-cols-2 gap-2`, four `ui-button` / `ui-button-secondary` / archive-styled controls, `min-h-11`. Refresh Prices stays as a separate control on the same page (and on Assets).

## Risks / Trade-offs

- [Ambiguous tickers cannot be imported until exchange exists in the CSV] → Block with both security ids/exchanges named; user disambiguates in the UI later. Alternative (add exchange column now) deferred to keep the confirmed 7-column schema.
- [Holdings import is not reversible like expenses] → Batch id is for support/audit; corrections go through dated observations. Reversal would need discard semantics we are not adding.
- [As-of archive changes today's net worth for already-archived accounts] → Intended; add reporting tests so charts do not drop pre-archive history.
- [Provider rate limits] → Cache reuse + sequential calls + partial-failure UI; never invent prices for skipped securities.

## Migration Plan

1. Additive: `import_batches.kind`, `import_batches.account_id` (nullable FK). No destructive data change.
2. Deploy code + migration together. Rollback drops the new columns; drafts in `tmp/imports` are ephemeral.
3. No backfill. Existing expense batches default `kind: expenses`.

## Open Questions

None that block implementation. Holdings-batch reversal is explicitly deferred.
