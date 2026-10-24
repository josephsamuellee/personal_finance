# Proposal

## Why

Daily brokerage work happens on Assets cards, which still stack only Add holding and Record cash. CSV, archive, and account-scoped price refresh already exist, but they live on account details (or the household header). Users should see the same five actions in one 2×3 grid on both Assets and account details, with room for a sixth action later.

## What Changes

- **Shared 2×3 brokerage grid** on every active brokerage Assets card and on that account's details page, in this order: Add Holding, Update Holdings via CSV, Record Cash, Update prices, Remove Account, empty cell.
- **Update prices** is the existing account-scoped refresh for that account's open holdings on the reporting date, not a new provider.
- **Remove Account** remains confirm-and-archive.
- **BREAKING (details layout):** account details drop the separate header Refresh Prices control; Update prices in the grid replaces it. Household Refresh Prices stays on the Assets header.
- Checking, savings, debt, and property cards keep a single Update balance action.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `household-interface`: replace the details-only 2×2 with a 2×3 grid on Assets cards and account details, including an empty sixth cell.
- `investment-positions`: brokerage Assets cards expose CSV, account-scoped Update prices, and archive; cash-type cards keep Update balance.

## Impact

Views for `holdings#index` and `accounts#show`, a shared brokerage-actions partial, existing `refresh_prices` / holdings-import / archive routes, and tests (`account_type_behavior_test`, `brokerage_actions_test`). No schema or provider changes. Unarchived `brokerage-csv-import-and-account-management` still specifies a 2×2 on details; archive it so main specs do not keep that grid.
