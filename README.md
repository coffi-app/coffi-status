# Coffi Status Page

This module hosts a simple JSON status file for the Coffi app, served via GitHub Pages.

## Purpose

The status page provides:
- Maintenance mode flag for the app
- Important messages to display to users
- Minimum required app version
- Last update timestamp

## File Structure

```
coffi-status/
├── status.json          # Production status file
├── dev-status.json      # Development environment status file
├── README.md           # This file
├── update-status.sh    # Script to update status files
└── .github/
    └── workflows/
        └── deploy.yml  # GitHub Actions deployment workflow
```

## Status JSON Schema

```json
{
  "maintenance": false,              // Boolean: true if app is in maintenance mode
  "message": null,                   // String or null: Message for maintenance mode
  "minimumVersion": "1.0.0",         // String: Minimum required app version
  "updateMessage": null,             // String or null: Custom message when update is required
  "updated": "2025-01-24T12:00:00Z"  // ISO 8601 timestamp of last update
}
```

### How the Flutter App Interprets Status

1. **Check Maintenance**: If `maintenance: true` → Show maintenance screen with `message`
2. **Check Version**: If app version < `minimumVersion` → Show update screen with `updateMessage`
3. **Normal Operation**: If neither condition is met → App operates normally

### Status Types
- **`operational`**: Normal operation (no maintenance, version is OK)
- **`maintenance`**: When `maintenance: true` - shows maintenance screen
- **`versionOutdated`**: When current app version < `minimumVersion` - shows update required screen

## Repository Information

- **Repository**: https://github.com/coffi-app/coffi-status
- **GitHub Pages**: Enabled on main branch, root folder
- **Purpose**: Centralized status management for Coffi mobile app

## Status URLs

**Production:**
```
https://coffi-app.github.io/coffi-status/status.json
```

**Development:**
```
https://coffi-app.github.io/coffi-status/dev-status.json
```

## Flutter App Configuration

The Flutter app determines which URL to use based on the `MAINTENANCE_URL` environment variable:

```dart
// In config files:
// config.dev.json:  "MAINTENANCE_URL": "https://coffi-app.github.io/coffi-status/dev-status.json"
// config.prod.json: "MAINTENANCE_URL": "https://coffi-app.github.io/coffi-status/status.json"
```

## Updating Status

### 🔐 Important: Audit Trail Requirements

**All status updates MUST be done through Git commits** to maintain a complete audit history. This allows us to track:
- Who made changes
- When changes were made
- What was changed
- Why changes were made (via commit messages)

### Recommended Update Process

#### Option 1: Using the Helper Script (Preferred)
The script helps format the JSON correctly but still requires manual commit:

```bash
# Update status file
./update-status.sh prod --maintenance true --message "Scheduled maintenance 2PM-4PM EST"

# When prompted "Do you want to commit and push these changes?", answer 'y'
# The script will create a commit with a descriptive message
```

#### Option 2: Manual Update
1. Edit `status.json` or `dev-status.json` directly
2. Update the `updated` timestamp to current UTC time
3. Commit with a descriptive message:
```bash
git add status.json  # or dev-status.json
git commit -m "Enable maintenance: Database migration 2PM-4PM EST"
git push
```

### Commit Message Guidelines

Use clear, descriptive commit messages:
- ✅ `"Enable maintenance: Database migration 2PM-4PM EST"`
- ✅ `"Disable maintenance: Migration complete"`
- ✅ `"Force update: Critical security patch v2.1.0"`
- ❌ `"Update status"`
- ❌ `"Changes"`

### Viewing Audit History

```bash
# View all status changes
git log --oneline -- status.json dev-status.json

# View detailed change history
git log -p -- status.json dev-status.json

# See who made specific changes
git blame status.json
```

## Integration with Flutter App

The Flutter app uses the `MAINTENANCE_URL` environment variable to determine which status file to check.

### Configuration

Set in your environment config files:

**config.dev.json:**
```json
"MAINTENANCE_URL": "https://coffi-app.github.io/coffi-status/dev-status.json"
```

**config.prod.json:**
```json
"MAINTENANCE_URL": "https://coffi-app.github.io/coffi-status/status.json"
```

The status check is implemented in:
```
modules/flutter/lib/src/features/maintenance/presentation/controllers/maintenance_controller.dart
```

## Status Field Descriptions

### Field Descriptions

#### `maintenance`
- **Type**: Boolean
- **Purpose**: When `true`, displays a maintenance screen in the app
- **Use case**: During backend updates, migrations, or critical fixes

#### `message`
- **Type**: String or null
- **Purpose**: Message displayed during maintenance mode
- **Examples**:
  - "Scheduled maintenance on Jan 25, 2PM-4PM EST"
  - "We're upgrading our servers. Back in 30 minutes!"
  - "Service disruption: We're working on a fix"

#### `minimumVersion`
- **Type**: String (semantic version)
- **Purpose**: Minimum required app version - app compares its version against this
- **Format**: "MAJOR.MINOR.PATCH" (e.g., "1.2.3")
- **Behavior**: If current app version < minimumVersion, update screen is shown

#### `updateMessage`
- **Type**: String or null
- **Purpose**: Custom message shown when app version is below minimum
- **Default**: App will use a default message if null
- **Examples**:
  - "Critical security update required. Please update to version 2.0.0 or higher."
  - "This version is no longer supported. Please update from the App Store."

#### `updated`
- **Type**: ISO 8601 timestamp
- **Purpose**: Track when the status was last modified
- **Format**: "YYYY-MM-DDTHH:MM:SSZ"
- **Required**: Must be updated with every change

## Testing in Development

### 1. Test Maintenance Mode
```bash
# Enable maintenance in dev environment
./update-status.sh dev --maintenance true --message "Testing maintenance mode"

# Run your Flutter app in dev mode
cd ../../flutter
fvm flutter run --dart-define=ENV=dev
```

### 2. Test Version Enforcement
```bash
# Set minimum version higher than current
./update-status.sh dev --version "99.0.0" --update-message "Please update to continue"
```

### 3. Test Normal Operation
```bash
# Clear all restrictions
./update-status.sh dev --maintenance false --version "1.0.0"
```

## Example Scenarios

### Maintenance Mode
```json
{
  "maintenance": true,
  "message": "We're upgrading our servers. Back in 30 minutes!",
  "minimumVersion": "1.0.0",
  "updateMessage": null,
  "updated": "2025-01-24T14:30:00Z"
}
```

### Force Update (Version-Based)
```json
{
  "maintenance": false,
  "message": null,
  "minimumVersion": "2.0.0",
  "updateMessage": "Critical security update required. Please update to version 2.0.0 or higher.",
  "updated": "2025-01-24T10:00:00Z"
}
```
*App will compare its version against minimumVersion and show update screen if needed*

### Normal Operation
```json
{
  "maintenance": false,
  "message": null,
  "minimumVersion": "1.0.0",
  "updateMessage": null,
  "updated": "2025-01-24T12:00:00Z"
}
```

### Both Maintenance and Update Required
```json
{
  "maintenance": true,
  "message": "System maintenance in progress",
  "minimumVersion": "2.0.0",
  "updateMessage": "Update required after maintenance completes",
  "updated": "2025-01-24T14:30:00Z"
}
```
*Note: Maintenance takes precedence - users see maintenance screen first*

## Security & Best Practices

### Security Considerations
- This repository is **public** for GitHub Pages to work
- **NEVER** include sensitive information in status files
- **NEVER** include API keys, passwords, or internal URLs
- Consider implementing signature verification for production

### Best Practices
- **Always commit changes** - Never edit files directly on GitHub
- **Use descriptive commit messages** for audit trail
- **Test in dev-status.json first** before updating production
- **Update the timestamp** with every change
- **Coordinate with team** before enabling maintenance mode
- **Document reason** for maintenance in commit message

### Response Time
- GitHub Pages typically updates within 1-2 minutes
- App checks status with 10-second timeout
- Status is checked on app launch and resume

## Monitoring

Consider setting up:
- GitHub Actions to validate JSON format on push
- Uptime monitoring for the GitHub Pages URL
- Alerts for when maintenance mode is enabled

## Support

For issues or questions about the status page, please open an issue in the main Coffi repository.