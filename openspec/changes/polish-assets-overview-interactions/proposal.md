# Proposal

## Why

The Assets overview repeats "Carried forward from &lt;date&gt;" on every account and holding, opens editors below the fold with no scroll or focus, and draws brokerage actions as an uneven 2×3 whose first button is a bright fill in dark mode.

## What Changes

- **Quieter cards**: omit carried-forward subtitles from `/assets` account cards. Keep values, the reporting date, and incomplete/unknown signals. Show the source date and carried-forward or verified state at the bottom of the opened holding or balance editor.
- **Reveal the result**: after an in-page editor renders, scroll that panel into view and move focus to its heading or first field. Skip this for route changes, the mobile bottom sheet already on screen, and in-place updates. Honor reduced motion.
- **Even actions**: four routine brokerage actions form a 2×2 with equal cells and one shared gap. Remove Account moves to a full-width footer. Checking, savings, debt, and property keep Update balance only.
- **Dark card actions**: routine card actions use a dark surface, light border, and light text in dark mode, including Add Holding. Remove Account stays a distinct archive control with the existing confirm. Other pages keep the current primary button.

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `household-interface`: replace the 2×3 brokerage grid (including the empty cell) with a 2×2 plus footer on Assets cards and account details; add reveal/focus and dark card-action contrast.
- `investment-positions`: Assets cards stop repeating carried-forward lines; editors still disclose observation date and status.

## Impact

`holdings/index`, `accounts/_brokerage_actions`, `holdings/_editor`, `holdings/_balance_editor`, `observation_label` call sites, Tailwind `ui-button` usage on those cards, and a small Stimulus reveal controller. No change to valuation, observation writes, routes, import, archive, or auth.

**Conflict:** main `household-interface` still requires a 2×3 with an empty cell and Remove Account bottom-left. This change replaces that layout. Account details share the same partial, so they follow the 2×2 plus footer rather than keeping the old grid.
