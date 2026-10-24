# operational-recovery Specification

## Purpose

Keep household records and receipt files recoverable together after a restart or a restore.

## Requirements

### Requirement: Durable records and attachments
The system SHALL keep the database and uploaded attachments available after the application process restarts.

#### Scenario: Restart preserves receipts
- **WHEN** the application service starts after a restart
- **THEN** previously stored financial records and uploaded attachments are available

### Requirement: Combined backup
A backup SHALL include both the database and the attachment files required to restore receipts.
The system SHALL produce a backup every day and SHALL retain backups for a configurable period.

#### Scenario: Backup contains receipts
- **WHEN** a daily backup is created for a household that has receipt attachments
- **THEN** the backup includes the database and those attachment files

### Requirement: Consistent restore
Restoring a backup SHALL return the financial records and receipt attachments from that same backup.

#### Scenario: Restored expense still has its receipt
- **WHEN** an operator restores a backup that contains an expense and its receipt
- **THEN** the restored expense and that receipt are both present
