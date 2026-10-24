# Proposal

## Why

A single household needs a low-maintenance record of spending, assets, and decisions that stays historically accurate without bank synchronization, credit-card reconciliation, or a required monthly review. The repository has no application yet, so the baseline has to define the product before implementation starts.

## What Changes

- Introduce a mobile-first household finance application served locally and through a Cloudflare Tunnel, with shared administrative access for every authenticated user.
- Record accounts, balances, property values, and investment positions as dated observations that can be backdated, carried forward, and corrected without rewriting the financial date.
- Track expenses with optional receipts, reversible CSV import, and a clear split between spending, refunds, and transfers.
- Value holdings from explicitly refreshed, cached market prices, and keep missing prices unknown.
- Show an estimated dashboard, approximate cash flow, savings targets, optional reviews, a decision journal, and explainable insights.
- Compare portfolio value with VOO, and withhold a precise performance claim until external cash flows can support it.
- Back up the database and receipt files together.

Adopted defaults for the gaps called out before implementation:

- Several observations may share one subject and calendar date; an explicit sequence decides which one is current.
- Debt balances are stored as nonnegative amounts and subtracted in reports.
- Refunds are signed expense adjustments, linked to an original expense when one is known.
- Transfers are separate records and are excluded from spending and income.
- Market data uses a pluggable adapter; the provider is selected during implementation.
- Quantity changes from splits and similar events are explicit corporate-action adjustments.
- Reporting currency is USD. Amounts in another currency stay unknown until conversion exists.
- Each recurring item declares whether it is already inside tracked spending or is an additional planning amount.
- A saved review preserves the report inputs and the calculation version used at save time.
- Backups run daily, with configurable retention.

## Capabilities

### New Capabilities

- `household-access`: Authentication, equal shared access, edit attribution, and both local and tunneled entry points.
- `household-interface`: Installable mobile-first interface, primary navigation, quick expense access, and entry feedback.
- `financial-history`: Accounts, dated observations, carry-forward, same-day ordering, and revision history.
- `investment-positions`: Securities, aggregate cost basis, and inline verification of individual holdings.
- `market-valuation`: On-demand price refresh, cache, and point-in-time valuation that preserves unknown values.
- `expense-tracking`: Quick expense entry, categories, receipts, refunds, transfers, and monthly spending baselines.
- `expense-import`: Mapped, previewed, confirmed CSV import and reversible batches.
- `cash-flow`: Recurring income and obligations, estimated surplus, and dated savings targets.
- `financial-reporting`: Dashboard, historical charts, drill-down, and comparison with visible data quality.
- `investment-benchmark`: VOO comparison that separates portfolio-value change from cash-flow-adjusted performance.
- `decision-journal`: Editable financial decisions with rationale, alternatives, and outcomes.
- `financial-reviews`: Optional saved review events with frozen inputs.
- `financial-insights`: Explainable observations computed in the application, without an external AI service.
- `operational-recovery`: Durable storage and recoverable backups of the database and attachments.

### Modified Capabilities

- None. The project has no existing specs.

## Impact

- New Rails application, SQLite database, Active Storage files, and a serverlite deployment on port 8090 behind Cloudflare Tunnel and Cloudflare Access.
- No existing application code, API, or data migration.
- External market-data provider is contacted only after an explicit refresh.
- Bank connections, automatic transaction import, credit-card reconciliation, offline sync, per-user ownership, permission roles, tax lots, predictive return models, and AI-dependent features stay out of scope.
- Precise cash-flow-adjusted benchmarking, comprehensive corporate actions, and inflation-adjusted reporting stay deferred.
