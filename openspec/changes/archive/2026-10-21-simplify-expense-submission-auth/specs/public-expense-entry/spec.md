# Spec Delta

## Purpose

Let someone record a spending expense from the Quick Expense page without a Rails session, while every other financial view and change stays behind that session.

## ADDED Requirements

### Requirement: Quick Expense opens without a session
The system SHALL show the Quick Expense form to a visitor who has no Rails session.
The form SHALL NOT include household totals, existing expenses, accounts, holdings, or revision history.

#### Scenario: Anonymous visitor opens the form
- **WHEN** a visitor with no Rails session opens Quick Expense
- **THEN** the form is shown and the response contains no existing expense, account, holding, or spending total

### Requirement: Spending entry fields
A public expense SHALL require an amount and a category name.
The date SHALL default to the current date in the household timezone and SHALL remain editable.
Merchant, notes, and image or PDF receipts SHALL be optional.

#### Scenario: Amount and category are enough
- **WHEN** a visitor submits an amount and a category name and omits merchant, notes, and receipts
- **THEN** a spending expense is stored for that amount, category, and the default date

#### Scenario: Date can be changed
- **WHEN** a visitor changes the date before saving
- **THEN** the stored expense uses the date the visitor entered

### Requirement: Generic repeat entry
After a successful public save, the system SHALL show a generic confirmation and a blank Quick Expense form.
The confirmation SHALL NOT include spending totals, earlier expenses, or the amount just saved.

#### Scenario: Another entry is offered
- **WHEN** a public expense saves successfully
- **THEN** the response confirms that an expense was saved, offers another entry, and does not show a spending total or an earlier expense

### Requirement: Public submissions are new spending records
The public path SHALL create a new spending expense.
The system MUST NOT accept a refund, a transfer, an account link, or a link to an existing expense on that path.

#### Scenario: Refund and transfer fields are ignored
- **WHEN** a public submission includes a refund or transfer kind, an original-expense id, or account ids
- **THEN** the stored record is a spending expense with no refund link and no account link

### Requirement: Public submission cannot change existing expenses
A public submission MUST NOT update, discard, or delete an existing expense, including when the request carries that expense's id.

#### Scenario: Existing expense id is submitted
- **WHEN** a public submission includes the id of an existing expense and different field values
- **THEN** the existing expense is unchanged and a separate spending expense is created only from the allowed new-entry fields

### Requirement: Client identity is ignored
The system MUST NOT record a user from a client-supplied identity field.
When the request has no Rails session, the new expense SHALL have no creating user.
When the request already has a valid Rails session, the system SHALL attribute the expense to that session user.

#### Scenario: Anonymous create has no user
- **WHEN** a visitor with no Rails session submits a valid expense and includes a user id in the request
- **THEN** the expense is stored with no creating user

#### Scenario: Existing session is attributed
- **WHEN** a visitor who already has a valid Rails session submits through Quick Expense
- **THEN** the expense records that session user and does not record a different user id supplied in the request

### Requirement: Existing records stay intact
Creating a public expense MUST NOT change the values or revision history of expenses that already existed.

#### Scenario: Prior expense is untouched
- **WHEN** a public expense is saved while another expense already exists
- **THEN** the earlier expense and its revision history remain unchanged

### Requirement: Other financial actions stay authenticated
The system SHALL require a Rails session before showing or changing expense lists, expense detail, expense edits, imports, accounts, holdings, prices, reports, reviews, decisions, recurring items, savings goals, or receipt files.

#### Scenario: Expense list requires a session
- **WHEN** a visitor with no Rails session requests the expense list, an expense's detail, or an expense edit
- **THEN** the system requires authentication and does not reveal that expense data

#### Scenario: Dashboard and assets require a session
- **WHEN** a visitor with no Rails session requests the home dashboard or the assets page
- **THEN** the system requires authentication and does not reveal financial amounts

#### Scenario: Receipt remains private
- **WHEN** a visitor with no Rails session requests a receipt attached to an expense
- **THEN** the system refuses the request and does not return the file

### Requirement: Public writes keep request protection
A public expense submission SHALL be rejected when the cross-site request token is missing or invalid.
The system MUST NOT treat reachability of the local address, or passage through the remote hostname, as a Rails session.

#### Scenario: Missing request token
- **WHEN** a public expense submission omits the request token
- **THEN** no expense is stored

#### Scenario: Local visit is not a session
- **WHEN** a visitor reaches Quick Expense on the local address without a Rails session
- **THEN** the visitor can submit a spending expense and still cannot open protected financial pages

### Requirement: Repeated public submissions are limited
The system SHALL refuse a public expense submission when the same client address has already made 10 public expense submissions in the preceding 60 seconds.
The refusal SHALL NOT include household financial data, and it MUST NOT store another expense.

#### Scenario: Eleventh submission is refused
- **WHEN** the same client address submits an eleventh public expense within 60 seconds
- **THEN** that submission is refused, no additional expense is stored, and the response contains no household financial data

### Requirement: Invalid public input is rejected in place
The system SHALL reject a public submission with a missing amount, a missing category, a non-numeric amount, a zero amount, an unparseable date, or a receipt that is not an image or PDF.
The error response SHALL keep the visitor's entered values and SHALL NOT include other household records.

#### Scenario: Validation failure
- **WHEN** a public submission has no category
- **THEN** no expense is stored and the form shows the entered amount without other household records
