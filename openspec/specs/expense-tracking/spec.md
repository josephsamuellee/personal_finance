# expense-tracking Specification

## Purpose

Record household expenses quickly, keep receipts optional, and summarize tracked spending without treating the books as reconciled.

## Requirements

### Requirement: Quick expense fields
An expense SHALL require an amount and a category before it can be saved.
The expense date SHALL default to the current date in the household timezone and SHALL remain editable.
Merchant, notes, and attachments SHALL be optional.

#### Scenario: Amount and category are enough
- **WHEN** the user enters an amount and a category and saves
- **THEN** the expense is stored without merchant, notes, or attachments

#### Scenario: Date can be changed
- **WHEN** the user changes the expense date before saving
- **THEN** the expense keeps the date the user entered

### Requirement: Repeat quick entry
After a successful quick-expense save, the system SHALL confirm the save and SHALL offer another entry.

#### Scenario: Another entry is offered
- **WHEN** a quick expense saves successfully
- **THEN** the system confirms the save and offers another expense entry

### Requirement: Expense belongs to its date
A saved spending expense SHALL be included in tracked spending for the calendar month of its expense date.

#### Scenario: Backdated expense
- **WHEN** the user saves a spending expense dated in an earlier month
- **THEN** the expense appears in that earlier month's tracked spending

### Requirement: Expense detail
The system SHALL keep each expense as its own record.
The user SHALL be able to view the expense, edit it, inspect its revision history, and see its attachments.

#### Scenario: Detail shows history and receipts
- **WHEN** the user opens an expense that has been edited and has an attachment
- **THEN** the detail view shows the current values, the revision history, and the attachment

### Requirement: Optional receipts
The system SHALL accept image and PDF attachments on an expense.
An authorized user SHALL be able to view an attached image and open an attached PDF.
The system MUST NOT require a receipt to save an expense.
The system MUST NOT prompt for a receipt or send a missing-receipt reminder.

#### Scenario: Expense without a receipt
- **WHEN** the user saves an expense with no attachment
- **THEN** the save succeeds

#### Scenario: Image and PDF can be viewed
- **WHEN** an authorized user opens an expense with an image attachment and a PDF attachment
- **THEN** the image can be viewed and the PDF can be opened

### Requirement: Monthly tracked spending
The system SHALL total tracked spending by calendar month and by category.
The system MUST NOT require credit-card statement reconciliation.

#### Scenario: Category total
- **WHEN** a month contains spending expenses in several categories
- **THEN** the system shows a total for each category and a total for the month

### Requirement: Three-month spending baseline
The spending baseline SHALL be the average tracked spending of the previous three completed calendar months.
The system SHALL show those three monthly totals with the baseline.
The system SHALL describe the figures as tracked spending.

#### Scenario: Baseline uses completed months
- **WHEN** the user views the baseline during the current month
- **THEN** the baseline averages the previous three completed months and those monthly totals are visible

### Requirement: Spending refunds
A refund SHALL reduce tracked spending on the refund's date.
The user SHALL be able to link a refund to an original expense.
An unlinked refund SHALL still reduce tracked spending.

#### Scenario: Linked refund
- **WHEN** the user records a refund linked to an earlier expense
- **THEN** tracked spending on the refund date is reduced by the refund amount
- **AND** the refund remains linked to that expense

### Requirement: Transfers excluded from spending
A transfer SHALL record an amount, a date, and the source and destination accounts.
Transfer amounts MUST NOT be included in tracked spending or in income totals.

#### Scenario: Account transfer
- **WHEN** the user records a transfer between two accounts
- **THEN** tracked spending and income totals exclude that amount
