# Tasks

## 1. Quieter overview

- [x] 1.1 Stop printing carried-forward lines on Assets account and holding rows. Keep verified, unknown, and incomplete signals, and the reporting date. Verify an integration test that a carried-forward holding card has no "Carried forward from" line and an unknown holding still says Unknown.

## 2. Editor metadata

- [x] 2.1 Show source observation date and carried-forward or verified status at the bottom of the holding editor and the balance editor, available to assistive tech. Leave account-details status lines in place. Verify the opened editor contains the date and status.

## 3. Reveal and focus

- [x] 3.1 After the in-flow holding or balance editor renders, scroll that panel into view and focus its heading or first field. Skip route changes, the fixed mobile sheet, and reduced-motion animation. Verify a system or Stimulus test for the offscreen editor and that Add Holding still navigates away.

## 4. Action layout and contrast

- [x] 4.1 Change the shared brokerage actions partial to a 2×2 (Add Holding, Update Holdings via CSV, Record Cash, Update prices) plus a full-width Remove Account footer, equal gaps, and no empty cell. Apply the same inset to Update balance cards. Verify `brokerage_actions_partial_test` and `brokerage_actions_test` for order at the card and on account details.
- [x] 4.2 Style those routine card actions with a dark surface, light border, and light text in dark mode, including Add Holding. Keep Remove Account distinct and confirmed. Do not restyle primary buttons outside these cards. Verify a view assertion that Add Holding on the card does not use the bright `ui-button` fill.

## 5. Visual check

- [x] 5.1 Walk Assets at 375, 390, 768, and 1440 in light and dark: no repeated carried-forward lines, even 2×2, footer archive button, no horizontal overflow, and an offscreen editor scrolls into view.

## Workflow follow-up

- Archive after review so main specs drop the 2×3 empty-cell layout.
