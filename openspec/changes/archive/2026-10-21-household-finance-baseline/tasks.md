# Tasks

## 1. Application shell

- [x] 1.1 Generate the Rails 7.2.3 app on Ruby 4.0.5 with SQLite and importmap, pin those versions, and verify `bin/rails about` reports Rails 7.2.3 with the SQLite adapter
- [x] 1.2 Add Tailwind, the shared layout, bottom navigation, sidebar, and a persistent Quick Expense action, and verify a request test shows Home, Expenses, Assets, Review, and Quick Expense
- [x] 1.3 Add the web manifest, icons, and a service worker that does not cache state-changing requests or register background sync, and verify the manifest is served and the worker source has no sync registration
- [x] 1.4 Configure port 8090, the host allow list, forwarded HTTPS, request-dependent secure cookies, and CSRF, and verify an unapproved host is rejected and a state-changing request without a CSRF token is rejected
- [x] 1.5 Implement session authentication, first-user setup only when no user exists, and creation of later users by an authenticated user, and verify a protected route requires login and two users can both authenticate
- [x] 1.6 Enable SQLite WAL and a busy timeout on the persistent database path, and verify the connection reports `journal_mode` of `wal`
- [x] 1.7 Document boot, test, and port commands in the README, and verify the documented test command runs

## 2. Accounts, observations, and revisions

- [x] 2.1 Create shared accounts with type, name, currency, and archive state, and verify tests for checking, savings, brokerage, debt, and property types, plus archive hiding the account from new entry while keeping history
- [x] 2.2 Create account and position observations with `observed_on`, explicit sequence, user attribution, and discard, and verify an ordinary save revises the current row while an explicit add allocates the next sequence
- [x] 2.3 Write a revision record for previous values, user, time, and optional reason, and verify correcting a 2021 quantity from 50 to 55 keeps `observed_on` in 2021 and stores the previous quantity
- [x] 2.4 Implement carry-forward selection and verified, carried-forward, and unknown labels, and verify a March quantity is carried into October, the higher same-day sequence wins, a zero quantity stays closed, and no history is unknown
- [x] 2.5 Implement verify, add-another, and correct actions for a selected date, and verify request tests for those three gestures and that updating one subject leaves another unchanged

## 3. Expenses and import

- [x] 3.1 Implement categories and quick expense with a household-timezone default date, optional merchant and notes, and an offer to enter another, and verify a system test saves with only amount and category
- [x] 3.2 Implement expense detail, edit, and revision history, and verify a validation failure keeps the entered values and a successful edit records the modifying user
- [x] 3.3 Implement signed refunds, optional links to an original expense, and transfers with source and destination accounts, and verify tracked spending subtracts refunds and excludes transfers
- [x] 3.4 Store optional image and PDF receipts with Active Storage on the persistent disk, and verify an expense saves without a receipt, an authenticated user can view both file types, and an unauthenticated attachment request is refused
- [x] 3.5 Implement monthly and category totals and the previous three completed-month baseline, and verify the baseline shows those three monthly totals and calls them tracked spending
- [x] 3.6 Implement CSV mapping, preview, validation, confirmation, cancel, and batch reversal for expenses only, and verify cancel inserts nothing, invalid rows are identified before confirm, and reversal removes the batch from spending totals while keeping audit history

## 4. Holdings interface

- [x] 4.1 Implement securities and position observations with aggregate cost basis and optional notes, and verify a position saves without tax lots
- [x] 4.2 Build the assets screen for a selected date with desktop inline editing and a compact mobile sheet posting to the same endpoint, and verify a system test marks the saved quantity verified and leaves an untouched holding carried forward
- [x] 4.3 Record a corporate action as a position observation with that reason and an effective date, and verify the new quantity applies from that date and no price path writes a quantity

## 5. Market prices

- [x] 5.1 Store provider and manual prices with market date, retrieval time, and source, and verify valuation uses the latest price on or before the date and treats a missing price as unknown rather than zero
- [x] 5.2 Select one market-data provider behind `MarketData::Adapter`, request each distinct security once, and record the provider name and credential variable in the deployment notes, and verify a failing adapter keeps cached prices, reports the failure, and does not mark quantities verified
- [x] 5.3 Implement market value, unrealized gain, and brokerage value as cash plus derived position values, and verify a brokerage fixture that also has a statement-style total is not double-counted

## 6. Cash flow

- [x] 6.1 Implement recurring income and obligations with amount, frequency, effective dates, and the included-or-additional treatment, and verify an included item is not added on top of tracked spending
- [x] 6.2 Implement the monthly surplus estimate, and verify it uses recurring income, the spending baseline, and additional obligations, and that the result is labeled an estimate
- [x] 6.3 Implement savings goals with effective periods, reasons, optional review dates, and history, and verify an overlapping period is rejected and a later period preserves the earlier goal
- [x] 6.4 Implement the alert when estimated surplus is below the applicable goal for two consecutive completed months, and verify the alert is informational and creates no required task

## 7. Dashboard and comparisons

- [x] 7.1 Implement shared reporting for net worth, liquid assets, allocation, and estimated or incomplete labels, and verify carried-forward components stay in an estimated total, unknown components are not coerced to zero, and an unconverted non-USD amount makes the USD total incomplete
- [x] 7.2 Add ECharts series that plot each observation on its `observed_on` date, and monthly summaries that use the latest current observation in the month, and verify observations on 28 August and 4 September stay on those dates
- [x] 7.3 Build the homepage with net worth, liquid assets, current tracked spending, the three-month average, estimated surplus, allocation, net worth history, and room for insights, and verify an authenticated home request shows each summary with its estimate or incomplete label
- [x] 7.4 Implement drill-down from a spending month, an asset category, and a holding, and verify each opens the underlying expenses, assets, or holding history
- [x] 7.5 Implement comparisons against a prior observation, prior month, and prior year, plus age and source text, and verify missing and estimated values are identified and no single accuracy score is shown

## 8. Decisions, reviews, and insights

- [x] 8.1 Implement decision records with date, description, rationale, alternatives, expected effect, optional review date, and optional outcome, and verify editing the rationale keeps the decision date and stores the previous text
- [x] 8.2 Implement optional reviews that store commentary, record references, report inputs, and calculation version `household-finance-1`, and verify browsing history creates no review and a later correction does not change the stored snapshot
- [x] 8.3 Open a saved review from its dashboard or history link, and verify the page shows the frozen financial context
- [x] 8.4 Implement spending, carried-holding, and upcoming-obligation insights locally, and verify an incomplete month is called month-to-date, a carried quantity includes its observation date, and no insight creates a required task

## 9. VOO benchmark

- [x] 9.1 Show portfolio value change between two dates from recorded quantities and prices, and verify the result is labeled as a change in portfolio value
- [x] 9.2 Compare performance with VOO using external cash flows only when those flows are recorded, and verify incomplete flows produce no precise outperformance figure while complete flows are labeled as adjusted for the recorded flows

## 10. Backup and deployment

- [x] 10.1 Add a daily backup command that uses the SQLite backup API, copies the attachment root, and prunes to a configurable retention of 30 backups, and verify a fixture backup contains the database snapshot and a receipt file
- [x] 10.2 Add a restore command for one backup set, and verify the restored fixture includes both the expense and its receipt
- [x] 10.3 Document the serverlite service, port 8090, hosts, Cloudflare Tunnel, Cloudflare Access, backup schedule, and restore drill in `docs/deployment.md`, and verify the documented backup command runs against the test fixture

## 11. Cross-cutting check

- [x] 11.1 Run the full test suite and one system test covering authentication, a second user editing the same expense, quick expense, carried-forward presentation, and a price refresh that leaves quantity unverified, and verify that system test and the suite pass

## Workflow follow-up

- Archive the change after implementation and review are complete.
- Sync the delta specs into `openspec/specs/` as part of archive.
