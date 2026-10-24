# Proposal

## Why

Brokerage holdings still have to be entered one ticker at a time, even after the unified holding form. Users need a CSV snapshot import they can preview and commit atomically, plus clearer brokerage account actions, archive-with-restore instead of a dead-end remove, and a price refresh limited to that account's shared securities.

## What Changes

- **Brokerage CSV holdings import**: after creating a brokerage account (optional; Skip is valid) and from an existing brokerage account's "Update Holdings via CSV", one authenticated workflow uploads a fixed-schema CSV, validates every row, previews all proposed holding/security/note/price changes, then commits atomically. Invalid rows, cancel, and write failure leave no financial records from that import. The already-saved account is never rolled back.
- **Snapshot semantics**: CSV quantity is the total shares on the observation date, not a delta. Blank dates use a date captured once at upload. Blank notes preserve existing shared notes. Absent tickers are unchanged. Identical reimports are no-ops. Duplicate security+date rows and ambiguous ticker matches block the file.
- **Shared prices**: omitted `price_per_share` reuses an exact-date saved price; missing prices block until supplied or explicitly fetched. Conflicting prices require per-conflict confirmation. Prices stay shared (security + date), never account-specific.
- **Brokerage action grid**: on an active brokerage account's details page, a 2×2 of Add Holding, Update Holdings via CSV, Record Cash, and Remove Account.
- **Archive and restore**: Remove Account confirms archive (already the persistence model). Archived accounts leave active listings and as-of-today totals but remain in as-of reports for dates before archival. Restore returns the same account and holdings without duplicating observations. Shared securities and prices are not deleted.
- **Account-scoped Refresh Prices**: refresh distinct currently held (nonzero quantity on the selected reporting date) securities in that account, one shared quote per security, skipping silent overwrite of manual prices, reporting per-security failure while keeping the cache.

## Capabilities

### New Capabilities

- `brokerage-csv-import`: CSV snapshot import of brokerage holdings into one explicit account, with parse/validate/preview/confirm, shared security and price handling, historical-date acknowledgment, and atomic commit.

### Modified Capabilities

- `financial-history`: archive confirmation, restore/unarchive, and as-of reporting of archived accounts; archived accounts leave active totals on and after the archive date without deleting history.
- `household-interface`: brokerage account details 2×2 action grid; batch historical-date acknowledgment for CSV rows.
- `market-valuation`: account-scoped price refresh (deduped shared securities, manual-price protection, partial failure reporting).
- `investment-positions`: brokerage account details as an entry to CSV import and account-scoped refresh without changing the single-holding editor.

## Impact

- **Reuse**: `HoldingForm` / `PositionObservation.revise_current!`, `Security.find_or_create_by_identity!`, `MarketPrice.effective_on` / `upsert_effective!`, `MarketData::Refresh`/`Import` (manual-price skip already on Import, not on household Refresh), `ExpenseImportDraft` session-file pattern, `ImportBatch` for a traceable holdings batch, `Account#archive!` / `available_for_entry`, existing historical-date checkbox policy.
- **Do not reuse**: expense CSV mapping, `MM/DD/YYYY` parsing, or "exclude invalid rows then import the rest". Holdings import is a separate authenticated route family.
- **Controllers/views**: `AccountsController#create` optional import step; account `show` 2×2 grid; new holdings-import controller; restore action; account-scoped refresh route.
- **Reporting**: `Reporting::Snapshot` must apply as-of archive rules to both cash and position components (today, archived holdings still count in net worth — that is the conflict this change fixes).
- **Out of scope**: expense CSV changes, tax lots, trades, dividends, brokerage API sync, bank aggregation, new permission roles, framework replacement, dashboard redesign, account-specific price tables.

### Conflicts found in the repository (resolved in design)

1. **Archived accounts still contribute to today's snapshot** via position (and observed cash) components. Spec intent: omit from active totals on/after archival date; keep as-of history before that date.
2. **`MarketData::Refresh` overwrites manual prices**; `MarketData::Import` does not. Account-scoped refresh follows Import (preserve manual unless explicitly replaced).
3. **CSV has ticker only; securities are unique on ticker+exchange.** Ambiguous tickers block the import rather than guessing.
4. **Expense import lets users exclude invalid rows.** Holdings import does not; one invalid row blocks the file.
5. **No restore exists today.** Add unarchive; do not hard-delete.
6. **Complete but unarchived change `simplify-account-holdings-and-market-prices` already implemented** shared notes, exact-date prices, HoldingForm, brokerage cash, and historical-date ack. This change builds on that code, not on the older main spec text until that change is archived.
