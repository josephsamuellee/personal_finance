# Design

## Context

The repository has no application code. See `proposal.md` for why this product exists. The specs define the observable behavior. This design fixes the technical choices those specs leave open: runtime, persistence, the observation model, valuation, and how the app is reached on serverlite.

## Goals / Non-Goals

**Goals:**

- One Rails application, one SQLite database, and one attachment directory.
- Dated observations and revisions as separate records, so a correction does not invent a new financial date.
- Server-rendered verified, carried-forward, and unknown states.
- Synchronous request handling for the initial release.
- The same calculation path for dashboards, charts, insights, and frozen reviews.

**Non-Goals:**

- A `households` table, per-user ownership, or role-based authorization.
- A background worker, scheduled price polling, or scheduled review creation.
- Foreign-exchange conversion, tax lots, and a general corporate-action engine.
- Offline write queues, email delivery, and bank aggregation.
- Treating a brokerage statement total as an additional asset.

## Decisions

### Runtime and interface

Use Ruby 4.0.5, Rails 7.2.3, SQLite, server-rendered Rails views, Turbo, Stimulus, Tailwind CSS, and Apache ECharts. Serve the app on `0.0.0.0:8090`.

Rails 7.2 does not ship an authentication generator. Authentication follows that later generator's shape inside this app: `User` with `has_secure_password`, a server-side `Session`, and a signed cookie. The alternative, upgrading to Rails 8 for the generator, would drop the required Rails pin.

The first screen when no user exists creates the first account. After that, only an authenticated user can create another user. There is no public signup and no email. An operator can reset a password from the server console.

Tailwind is integrated without a separate Node application. ECharts is vendored for the import map. Charts are Stimulus islands fed by JSON. Turbo navigates and replaces page sections; it does not morph a live chart.

The web manifest and icons make the app installable. The service worker does not cache writes and does not register background sync. Offline use shows an unavailable state.

Navigation is bottom tabs on narrow viewports and a sidebar on wide viewports. Quick expense stays outside those four destinations so it remains one action away. Desktop inline editing uses a Turbo Frame per value. Narrow editing uses a Stimulus sheet. Both post to the same observation endpoint.

### Entry points and cookies

`config.hosts` allows `serverlite` and the configured tunnel hostname. `config.force_ssl` stays off so `http://serverlite:8090` can keep a session. The session cookie is `Secure` only when the request is HTTPS. SameSite is `Lax`. CSRF protection stays on. The app trusts Cloudflare's forwarded protocol header from the tunnel, and it does not treat Cloudflare Access identity as a Rails user.

Cloudflare Access is an additional gate in front of the tunnel only. Local users authenticate once, to Rails. Remote users pass Access and then Rails.

### Accounts and observations

There is no household row. Every account is shared.

`accounts.type` is one of `checking`, `savings`, `brokerage`, `debt`, or `property`. `archived_at` removes an account from current entry choices and leaves its observations in history. Currency is an ISO code. Reporting reads USD only.

Two observation tables keep different shapes apart:

- `account_observations` hold one amount for checking, savings, brokerage cash, debt, and property value.
- `position_observations` hold `account_id`, `security_id`, `quantity`, `cost_basis`, and optional notes.

Debt amounts are nonnegative and reports subtract them. A brokerage account contributes its cash observation plus derived position market values. It has no stored total-account value.

Each observation has `observed_on`, `sequence`, attribution, and `discarded_at`. The unique key is the subject plus `observed_on` plus `sequence`. The subject is the account, or the account and security for a position.

```
selected date D
        |
        v
current row = highest sequence
              on the latest observed_on <= D
              among rows that are not discarded
        |
        +-- observed_on == D --> verified
        +-- observed_on < D  --> carried forward
        +-- no row           --> unknown
```

Three gestures share that rule:

- Verify, or save on the assets sheet for date D, inserts the first observation for that subject and D, or revises the current row when one already exists. Sequence does not change on revision.
- Add another observation for the same subject and date inserts the next sequence. Reports then use that new row. The previous row stays in history.
- Correct opens a specific past row and writes a revision. `observed_on` changes only when the user edits that field.

A position quantity of zero is a normal observation. Later dates carry zero and the holding is closed. Discarding a row sets `discarded_at`, drops it from current calculations, and keeps its revisions.

`record_revisions` is polymorphic. Each revision stores the revision number, previous values, new values, user, timestamp, and optional reason. Application code writes the revision. A gem is not introduced for this, because the financial date and the reason need to stay explicit.

Corporate actions are position observations whose reason is `corporate_action`. A price refresh never writes a position observation.

### Prices and valuation

`market_prices` stores `security_id`, `amount`, `currency`, `market_on`, `retrieved_at`, `source`, and `entered_by_id`. Provider prices and manually entered prices share the table. `source` is `manual` or the adapter name.

`MarketData::Adapter` is the only type allowed to call the network. The concrete provider is chosen in the market-valuation tasks and configured with credentials outside the repository. One refresh collects the distinct securities in active holdings, requests each once, and upserts prices. A failed request leaves existing rows in place and returns an error to the page.

Valuation uses the latest `market_on` on or before the valuation date. Market value is quantity times that price. Unrealized gain is market value minus cost basis when both exist. A missing price, a missing observation, or a non-USD amount without a conversion is unknown. Unknown is never coerced to zero.

A `Reporting` module owns net worth, liquid assets, allocation, spending, surplus, and chart series. Controllers and the review snapshot call that module. Liquid assets are checking, savings, and brokerage-cash observations. Net worth is known assets minus known debt. A total that includes any carried-forward component is `estimated`. A total that omits any unknown component is `incomplete`.

The calculation version is the constant `household-finance-1`. A saved review stores that version and a JSON snapshot of the inputs it used, including observation, price, and expense identifiers. Later corrections do not rewrite the snapshot.

VOO comparison has two queries. Value change uses portfolio market value on two dates. Performance against VOO is calculated only when external cash-flow records cover the period; otherwise the screen states that a precise figure is unavailable. External cash flows are the transfers and other non-valuation movements recorded for the brokerage accounts in that interval. This stays the last implementation slice.

### Expenses, imports, and cash flow

`expenses.kind` is `spending`, `refund`, or `transfer`. Spending amounts are positive. Refund amounts are negative and may point at `refund_of_id`. Transfers store source and destination accounts and are excluded from spending and income queries. Category is required for spending and refunds.

Receipts are Active Storage attachments on the expense, stored on the local disk service under a persistent path. Preview uses the browser for images and PDFs. No variant job queue is required for the initial file sizes.

`import_batches` store the uploading user, the column mapping, and the result. Created expenses point at the batch. Confirmation is the only step that inserts expenses. Cancel deletes nothing because nothing has been inserted. Reversal discards every expense in the batch and writes revisions. Parsing and insert run in the request.

`recurring_items.treatment` is `included_in_tracked_spending` or `additional`. Surplus is expected recurring income, minus the three-month tracked-spending baseline, minus additional recurring obligations. Items marked included are not added again. The baseline averages the previous three completed calendar months and the page shows those three totals. The current month is shown separately as month-to-date.

`savings_goals` have `starts_on`, `ends_on`, `amount`, `reason`, and optional `review_on`. An open `ends_on` means the goal is still in effect. Overlapping periods fail validation. The applicable goal for a date is the single period that contains it.

Insights are rule objects in the application. They do not call an external model. Each insight has a kind of `fact`, `estimate`, or `suggestion`. The two-month surplus alert is one of those rules and creates no task record.

The household timezone is configuration, initially `America/Los_Angeles`. Expense and review "today" uses that zone. Financial dates are calendar dates, not timestamps.

### Database operation and backups

SQLite runs in WAL mode with a busy timeout and short write transactions. Puma is the web server. No second process writes the database in the initial release.

A daily backup is a SQLite online backup plus a copy of the Active Storage root, invoked by the host scheduler rather than an in-app worker. Default retention is 30 daily backups and is configurable. Restore replaces both the database and the attachment root from the same backup set. A restore drill is part of accepting the deployment.

### Deployment

The process listens on port 8090 and uses a persistent volume for the SQLite file and `storage/`. Cloudflare Tunnel points at that port. The tunnel hostname is injected as configuration. A restart must not use an ephemeral disk for either store.

## Risks / Trade-offs

- [SQLite write contention from threaded Puma] → WAL, a busy timeout, and short transactions. No worker process in this release.
- [A file copy of a live SQLite database drops the WAL] → backups use the SQLite backup API and include the attachment directory.
- [Local HTTP cannot set a Secure cookie, while the tunnel should] → the Secure flag follows the current request scheme.
- [Users will read a carried-forward quantity as freshly checked] → the state is rendered by the server, and a price refresh writes only `market_prices`.
- [Same-day edits accidentally create extra sequences] → an ordinary save revises the current row; a new sequence requires the explicit add action.
- [ECharts state is destroyed by a Turbo morph] → the chart is mounted by Stimulus and replaced by navigating to the drill-down.
- [CSV rows that are transfers get imported as spending] → the mapping step includes the expense kind, and transfer rows must name both accounts before confirmation.
- [A saved review changes after a historical correction] → the review displays its stored snapshot, not a live recomputation.
- [The price provider chosen later has different symbol rules] → only the adapter changes. Securities already store an identifier separate from the ticker.

## Migration Plan

This is a new deployment, not a migration from an existing app.

1. Create the Rails app and pin Ruby and Rails.
2. Provision a persistent data directory on serverlite.
3. Run migrations and create the first user.
4. Bind the service to port 8090 and allow the local host plus the tunnel hostname.
5. Point Cloudflare Tunnel at the service and put Cloudflare Access in front of the public hostname.
6. Schedule the daily backup and run one restore drill onto a spare copy before treating the system as accepted.

Rollback of a bad release is redeploying the previous release with the same data directory. Rollback of bad financial data is revision restore, observation discard, or import reversal. Rollback of a bad backup restore is returning to the previous backup set, which is why the drill happens before cutover.

## Open Questions

- Which market-data vendor sits behind `MarketData::Adapter`. The interface, cache, and failure behavior are fixed; the vendor and credential setup are chosen when that task starts.
