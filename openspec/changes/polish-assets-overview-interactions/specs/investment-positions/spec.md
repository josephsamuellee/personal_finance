# Spec Delta

## ADDED Requirements

### Requirement: Editor discloses carried-forward status
A holding or balance editor opened from Assets SHALL show the source observation date and whether the value is carried forward or verified in a secondary region at the bottom of that panel. That text SHALL remain available to assistive technology. Account details and other pages that are not the Assets overview card SHALL keep their existing status lines.

#### Scenario: Opened holding shows its source date
- **WHEN** the user opens a carried-forward holding from Assets
- **THEN** the editor's secondary section names the observation date and the carried-forward status

#### Scenario: Account details keep the status line
- **WHEN** the user views holdings on an account's details page
- **THEN** each holding can still show its carried-forward or verified status
