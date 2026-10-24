# Design

## Context

See proposal.md for why Quick Expense should not require a Rails session. `ApplicationController` includes `Authentication`, which requires a session before every action. `ExpensesController` creates expenses only after that filter, copies `current_user` onto the record, and permits kind, refund, and account ids. The shared layout renders Home, Expenses, Assets, and Review around the form. `Expense.created_by` is already optional. Revisions are written on update, not on create. Active Storage controllers include the same authentication filter. CSRF is on, and there is no rate limiter. The app is one Puma process on port 8090. Cloudflare Access sits in front of the tunnel only.

## Goals / Non-Goals

**Goals:**

- One public GET and one public POST for a new spending expense.
- The same confirmation and blank form for the next entry, with no household figures.
- Session checks, CSRF, host checks, and receipt privacy stay in place everywhere else.

**Non-Goals:**

- Public refunds, transfers, imports, edits, or lists.
- Treating Cloudflare Access, the tunnel, or the local address as a Rails user.
- A schema change or a synthetic user for anonymous creates.
- Editing the unarchived `household-finance-baseline` specs.

## Decisions

### Dedicated controller, not a hole in the expense resource

Add `QuickExpensesController` with `allow_unauthenticated_access` on `new` and `create` only. Route `GET /quick-expense` and `POST /quick-expense`. Point the header Quick Expense link there.

`ExpensesController` keeps the session filter for index, show, new, create, edit, update, and destroy. Signed-in refunds and transfers stay on that form, which still lists accounts. The public form does not.

Alternative considered: `skip_before_action` on `ExpensesController#new` and `#create`. That keeps refund, transfer, and id parameters on the same action that would become public. A separate controller makes the allowed parameters obvious.

### Permitted fields and forced spending

Permit `amount`, `category_name`, `spent_on`, `merchant`, `notes`, and `receipts`. Set `kind` to `spending` in the controller. Do not permit `id`, `kind`, `refund_of_id`, `source_account_id`, `destination_account_id`, `created_by_id`, `updated_by_id`, or `import_batch_id`.

Assign `created_by` and `updated_by` from `current_user`. With no session that is `nil`. Never read a user id from the request. `find_or_create` the category from the typed name. Do not render existing categories, expenses, or accounts.

Validation on this path: amount present, numeric, and greater than zero; category name present and at most 80 characters; merchant at most 120 characters; notes at most 2,000 characters; date parseable and inside 2000-01-01 through 2100-12-31; receipts limited to the existing image and PDF types. A failure re-renders the form with the entered values and no other household records.

### Minimal page for anonymous visitors

If no session is present, render a layout that contains the form, the generic flash, and a sign-in link. Omit the sidebar, bottom navigation, and the signed-in email. A signed-in visitor may use the normal chrome; the page body is still only the form.

Success redirects back to `GET /quick-expense` with the notice "Expense saved. You can enter another." Do not put the amount, category, or a spending total in the notice. The next form starts blank except for today's date.

### Throttle the public POST only

Add `rack-attack`. Throttle `POST /quick-expense` to 10 requests per client address per 60 seconds, using an in-memory cache store. Key the throttle on `request.remote_ip`. Return 429 and the text "Too many expense submissions. Try again shortly." Do not throttle other routes. Do not authorize from `Cf-Access-Jwt-Assertion` or any client identity header.

Alternative considered: `Rails.cache` in a `before_action`. The test cache is a null store, so the limiter would not run in tests. Rack::Attack can use its own memory store in every environment, which matches the single-process deployment.

### Request protection stays global

Do not call `skip_forgery_protection` and do not change `allow_unauthenticated_access` on any existing controller. A POST without the CSRF token continues to be rejected before an expense is saved. Receipt URLs keep the Active Storage authentication filter.

## Risks / Trade-offs

- [Anyone who can open port 8090 can add spending] → The public action cannot read or edit existing records, and the per-address throttle caps repetition. Local access is trusted as the household network; Rails does not pretend Cloudflare Access covered it.
- [Remote visitors may share the tunnel's address, so the throttle is coarse] → The limiter is abuse reduction, not authentication. One Puma process means the in-memory counter is the process counter and resets on restart.
- [Typed categories can create new category names] → Names are not amounts or history. The public form does not list the categories that already exist.
- [Anonymous expenses have a null creator] → Later edits still go through the authenticated expense actions, which record the editing user on the revision. No backfill.

## Migration Plan

No database migration. Deploy the route, controller, layout, and throttle together. Rollback by removing the public route and the header link target, then removing the throttle. Expenses created without a user remain valid records.

## Open Questions

None. The spending-only public form, the 10-per-60-seconds limit, and the typed category field are the choices this design implements.
