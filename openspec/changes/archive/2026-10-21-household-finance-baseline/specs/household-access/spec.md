# Spec Delta

## Purpose

Require an authenticated session for household finances and give every signed-in user the same shared records through the local address and the remote HTTPS hostname.

## ADDED Requirements

### Requirement: Protected financial routes
The system SHALL require an authenticated session before showing or changing household financial records or attachments.

#### Scenario: Unauthenticated request
- **WHEN** an unauthenticated request opens a protected route
- **THEN** the system requires authentication and does not reveal household financial data

#### Scenario: Authenticated request
- **WHEN** an authenticated user opens a protected route
- **THEN** the system shows the requested household data

### Requirement: Equal shared access
The system SHALL give every authenticated user the same administrative access to the same household records, with no per-person ownership and no separate permission roles.

#### Scenario: Shared expense
- **WHEN** one authenticated user creates an expense
- **THEN** every other authenticated user can view and edit that expense

#### Scenario: No private partition
- **WHEN** an authenticated user views accounts, expenses, or holdings
- **THEN** the system shows the shared household records

### Requirement: Edit attribution
The system SHALL record the authenticated user who creates or modifies a financial record, together with the modification time.

#### Scenario: Modification is attributed
- **WHEN** an authenticated user modifies a financial record
- **THEN** the record's history identifies that user and the modification time

### Requirement: Local and remote entry
The system SHALL serve the same application at `http://serverlite:8090` and at the configured Cloudflare HTTPS hostname.

#### Scenario: Local visit
- **WHEN** a user visits `http://serverlite:8090` while the application is running
- **THEN** the application loads

#### Scenario: Remote visit
- **WHEN** an authorized remote user visits the configured HTTPS hostname
- **THEN** the application loads with working stylesheets, scripts, forms, and charts

### Requirement: Tunnel preserves application security
The system SHALL enforce session authentication and cross-site request protection on requests that arrive through the HTTPS tunnel.

#### Scenario: Remote form submission
- **WHEN** an authenticated user submits a state-changing form through the HTTPS hostname
- **THEN** the system accepts the request only when both the session and the request token are valid

#### Scenario: Unapproved host
- **WHEN** a request arrives for a host the application is not configured to serve
- **THEN** the system rejects the request
