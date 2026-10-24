# Design

## Context

See proposal.md for why this change exists. The signed-in shell is `app/views/layouts/application.html.erb`: a sidebar from `lg` (1024px), fixed bottom navigation below that, and `max-w-7xl` content with bottom padding for the bar. Primary links in `app/views/shared/_navigation.html.erb` are text-colored flex links. The sidebar has a hover fill; the bottom bar does not, and neither marks the current route.

`UiFormBuilder` adds `ui-field` and `ui-button`. `.ui-field` uses a dark fill that matches the page background, so an unfocused field is hard to see. Expense, user, and session forms also pass `border` and `bg-slate-900` classes that fight those shared styles. Tailwind v4 `dark:` follows `prefers-color-scheme`. `User` stores only email and password. The net-worth chart uses ECharts defaults, which stay light-on-white.

The completed change `application-ui-ux` is not archived. This design supersedes its "no in-app theme switch" decision. Do not edit that change's artifacts. Sync or archive it before this change so its device-dark wording is not the later text.

## Goals / Non-Goals

**Goals:**

- One button treatment for task and destination controls, with links and buttons kept semantically distinct.
- Route-based active state for the four primary destinations.
- A per-user appearance of light, dark, or system, painted before the first frame and applied without a manual reload.
- Shared field styles that stay visible unfocused, including a currency example that is never submitted.

**Non-Goals:**

- A component framework, a downloaded font, or a second navigation model.
- Changing amount parsing, validation rules, observation gestures, or who may open Quick Expense.
- Putting Settings into the four primary destinations.

## Decisions

1. **Keep navigation as links and mutations as buttons.** Task and destination controls that only open a page use `link_to` with `ui-button` or `ui-button-secondary`, so the padding box is the hit target. `button_to` and `<button>` stay for saves, refresh, archive, and sign-out. Record names, expense rows, decision titles, review dates, allocation labels, and receipt files stay `ui-link`. The holding ticker becomes a secondary button link because it opens the editor. Cancel becomes a secondary button link and still closes the sheet without a write.
   - Alternative: make every former blue link a `<button>`. Rejected because those controls navigate and the spec requires links for navigation.

2. **Mark the active destination from the path prefix.** A helper sets `aria-current="page"` and `ui-nav-current` from `request.path`. Home matches only `/`. Expenses matches `/expenses`, `/expense_imports`, and `/quick-expense`. Assets matches `/assets`, `/accounts`, and `/holdings`. Review matches `/reviews`, `/decisions`, `/compare`, `/benchmark`, `/recurring_items`, and `/savings_goals`. `/settings` matches none of the four. Both the bottom bar and the sidebar render the same partial.
   - Alternative: `current_page?` on the index path only. Rejected because a nested account or expense page would clear the highlight.

3. **Draw primary items as separated buttons.** Add `ui-nav` with a border, fill, minimum 44px height and width, full-width flex layout, and visible hover, focus-visible, and pressed styles. `ui-nav-current` uses the stronger fill in both themes and does not depend on color alone: the current item also sets `aria-current`. Inactive items keep a border so they still look tappable. The bottom bar keeps `position: fixed`, `pb-[env(safe-area-inset-bottom)]`, and a gap between the four items. Increase the main column's bottom padding so the taller bar does not cover the last control. At 375px the labels stay on one line.
   - Alternative: icons without text. Rejected because the current labels are the destinations users already know.

4. **Store appearance on the user and mirror it in a cookie.** Add `users.appearance`, a non-null string limited to `system`, `light`, and `dark`, defaulting to `system` for existing and new users. Settings is an authenticated `GET/PATCH /settings` page with a labeled radio group. Saving updates the user and a long-lived `appearance` cookie. Authenticated responses refresh that cookie from the user so a later signed-out Quick Expense page on the same browser matches. Anonymous pages read the cookie and otherwise use `system`. Settings shows no financial amounts. The anonymous layout does not gain Home, Expenses, Assets, Review, or Settings.
   - Alternative: local storage only. Rejected because the first paint would happen before the script could read it reliably, and it would not follow the user to another browser.
   - Alternative: cookie only. Rejected because a signed-in user should keep the choice after switching browsers.

5. **Apply the theme before stylesheets, then update it in place.** The layout sets `data-appearance` on `<html>` from the user or the cookie. A blocking script in `<head>`, before the stylesheets, adds or removes `html.dark`. `system` follows `prefers-color-scheme` and listens for changes; `light` and `dark` ignore the device. Override Tailwind's `dark` variant so `.dark` is the only switch, not the media query. The Appearance radios use a Stimulus controller that sets `data-appearance`, reruns that script's apply function, and submits the form. The page does not ask for a reload or sign-out.
   - Alternative: keep the media-query variant and add a second set of `light:` utilities. Rejected because every existing `dark:` class would need a parallel override.

6. **Make fields visible by strengthening the shared class, not by styling each form.** `.ui-field` gets a fill that differs from the page in both themes, a border that is visible unfocused, muted placeholder color, and a focus ring. Minimum height stays 44px. Remove the extra `border` and `bg-slate-900` classes on the expense, user, and session forms so they inherit `ui-field` and `ui-button`. Disabled submits use a muted fill and `cursor: not-allowed`, not opacity alone. Currency fields that are empty use `type="text"`, `inputmode="decimal"`, and placeholder `$1,000`. A number input will not reliably show a dollar placeholder. The placeholder is not a value attribute. Saved amounts stay in `value`. Quantity fields stay numeric and do not use the dollar example. Field errors render beside the input with `aria-invalid` and `aria-describedby`. Validation rules and parameter names stay the same.
   - Alternative: a third-party form library. Rejected because the form builder and field partial already exist.

7. **Restyle the chart from the active text color.** When the chart connects, and when `html` appearance changes, set ECharts axis, label, and split-line colors from the computed body color so labels stay readable on the dark page.
   - Alternative: leave the chart on the default light theme. Rejected because its labels fail the dark-mode scenario.

8. **Settings sits at the end of Home and in the shell.** Home's primary action remains Record an expense. After the last Home section, render a secondary Settings link. Repeat it in the signed-in header and at the bottom of the sidebar. It uses `ui-button-secondary`.

## Risks / Trade-offs

- [Tailwind `dark:` stops following the device unless `html.dark` is set] → The head script runs before CSS, and the default appearance is `system`, so current visitors keep the device scheme until they choose otherwise.
- [A number input drops the "$1,000" placeholder] → Currency examples use a decimal text input and the same server parameter. Quantity stays `type="number"`.
- [Archiving `application-ui-ux` after this change would restore "device dark only"] → Sync or archive that change first, then this one.
- [Bottom-bar buttons get taller and cover the last field] → Increase content bottom padding and check 375px and 390px in the browser.
- [Rack tests cannot see contrast, hit area, or overflow] → Browser checks at the four viewports are required before the visual tasks are marked done.
- [The appearance cookie and the user column drift] → Authenticated responses rewrite the cookie from the user column.

## Migration Plan

Add `users.appearance` with default `system`. No financial rows change. Deploy the migration with the views and the head script. Rollback drops the column and restores the media-query dark variant; stored finances stay valid.

## Open Questions

None. The preference lives on the user, with a cookie only so the first paint and signed-out pages match.
