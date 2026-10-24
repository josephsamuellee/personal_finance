# Design

## Context

Assets cards in `holdings/index.html.erb` print `observation_label` on the account and again under every holding. Carried-forward text is `Carried forward from <date>`. The holding editor (`holdings/_editor.html.erb`) and balance editor render after the card grid. Below `lg` the holding editor is a fixed bottom sheet; at `lg` and above it is an in-flow card, so it can sit below the fold. `_brokerage_actions.html.erb` is a `grid-cols-2` of five controls plus an empty cell, shared by Assets cards and `accounts#show`. `ui-button` is a light fill in `.dark`; link buttons also get a 4px margin that `button_to` forms do not, so the grid looks uneven.

## Goals / Non-Goals

**Goals:**
- Hide carried-forward lines on Assets cards only.
- Scroll and focus in-page editors after render.
- 2×2 routine actions plus a Remove Account footer.
- Dark card actions that are not a white fill.

**Non-Goals:**
- Changing valuation, observation writes, routes, CSV import, archive confirmation, or auth.
- Restyling primary buttons on Home, Expenses, Review, or Quick Expense.
- Removing status lines from account details or revision history.

## Decisions

### D1. Overview vs editor
Pass a compact mode into `observation_label` for Assets cards: `:carried_forward` renders nothing; `:verified` and `:unknown` stay. Move the full label to a footer inside `_editor` and `_balance_editor`, after the form, with a heading such as "Observation". Account details keep the current per-holding line.

### D2. Reveal
Add a Stimulus controller on the in-flow editor and balance editor. On connect, if the panel is not a fixed sheet, `scrollIntoView({ block: "nearest", behavior })` and focus the heading (`tabindex="-1"`) or the first field. `behavior` is `auto` when `prefers-reduced-motion: reduce`. Do not attach it to Add Holding or CSV links. Update prices stays a redirect with a flash. If render fails, do not scroll.

### D3. Grid and footer
Drop the empty cell. Routine four stay in `grid-cols-2` with `gap-2` on both axes and `w-full` forms. Remove Account is a sibling footer, full width, outside the grid. Checking/savings/debt/property stay a single Update balance control, using the same horizontal inset as the brokerage grid. Remove the link-only 4px margin inside this partial so links and buttons share a cell.

### D4. Dark variant
Add a card-scoped class (for example `ui-button-quiet`) used by all four routine card actions and by Update balance on non-brokerage cards. In dark mode: dark background, light border, light text, visible focus ring. In light mode: keep the current secondary contrast. Remove Account keeps red text/border and `turbo_confirm`. Do not change `.ui-button` globally.

### D5. Details page
The shared partial is the only brokerage action markup, so account details get the same 2×2 and footer. This replaces the archived 2×3 requirement.

## Risks / Trade-offs

- [Tests assert "Carried forward from 2026-03-15" on Assets] → Move those assertions to the opened editor.
- [System test expects five labels inside one grid including an empty cell] → Expect four grid labels and a footer Remove Account.
- [Focus on a heading can be missed by some browsers] → Set `tabindex="-1"` before `focus()`.

## Migration Plan

View, CSS, and Stimulus only. No schema. Rollback is reverting the partial and label calls.

## Open Questions

None. Details follow the card layout because they share the partial. The visible price action stays "Update prices".
