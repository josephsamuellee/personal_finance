# Holdings CSV write path

Holdings CSV import must not use expense import routes (`/expense_imports`) or `ExpenseCsv`.

Confirmed reuse for persistence:

- `HoldingForm` (`app/forms/holding_form.rb`) records dated quantity/cost-basis observations (`revise_current!`) and optional prices.
- `Security.find_or_create_by_identity!` reuses a unique ticker (and optional exchange) instead of duplicating securities.
- `MarketPrice.effective_on` supplies an exact-date price; `MarketPrice.upsert_effective!` writes a shared security/date price.

Draft files may reuse `ExpenseImportDraft`'s tmp JSON helper. `ImportBatch` with `kind: "holdings"` is only a traceable batch identifier.
