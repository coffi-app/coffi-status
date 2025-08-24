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
  "maintenance": false,           // Boolean: true if app is in maintenance mode
  "message": null,               // String or null: Message to display to users
  "minimumVersion": "1.0.0",     // String: Minimum required app version
  "updated": "2025-01-24T12:00:00Z"  // ISO 8601 timestamp of last update
}
```

## Setup Instructions

### 1. Create GitHub Repository

1. Create a new public repository named `coffi-status` on GitHub
2. Initialize it as an empty repository (no README, .gitignore, or license)

### 2. Push This Module

From the root of the mono-repo:

```bash
cd modules/coffi-status
git init
git add .
git commit -m "Initial status page setup"
git branch -M main
git remote add origin https://github.com/[username]/coffi-status.git
git push -u origin main
```

### 3. Enable GitHub Pages

1. Go to the repository settings on GitHub
2. Navigate to **Settings → Pages**
3. Under **Source**, select **Deploy from a branch**
4. Choose **Branch: main** and **Folder: / (root)**
5. Click **Save**

### 4. Access Your Status Page

After GitHub Pages is enabled, your status will be available at:

**Production:**
```
https://coffi-app.github.io/coffi-status/status.json
```

**Development:**
```
https://coffi-app.github.io/coffi-status/dev-status.json
```

Note: It may take a few minutes for GitHub Pages to deploy initially.

## Updating Status

### Quick Update Script

Use the provided script to update status files:

```bash
# Update production status
./update-status.sh prod --maintenance true --message "Scheduled maintenance"

# Update development status
./update-status.sh dev --maintenance false --message "Testing new features"

# Clear maintenance mode
./update-status.sh prod --maintenance false
```

### Manual Update

1. Edit `status.json` or `dev-status.json` with the new values
2. Update the `updated` timestamp
3. Commit and push to main branch:
```bash
git add status.json dev-status.json
git commit -m "Update status: [description]"
git push
```

### Automated Update via GitHub Actions

The repository includes a GitHub Actions workflow that can be triggered manually to update the status.

## Integration with Flutter App

The Flutter app automatically checks the status based on the environment:

- **Development builds** (`flutter run --dart-define=ENV=dev`): Uses `dev-status.json`
- **Production builds**: Uses `status.json`

The status check is implemented in:
```
modules/flutter/lib/src/features/maintenance/presentation/controllers/maintenance_controller.dart
```

### Environment-Specific URLs

```dart
// The controller automatically selects the correct URL based on environment
const String _cdnStatusUrlProd = 'https://coffi-app.github.io/coffi-status/status.json';
const String _cdnStatusUrlDev = 'https://coffi-app.github.io/coffi-status/dev-status.json';
```

## Status Field Descriptions

### `maintenance`
- **Type**: Boolean
- **Purpose**: When `true`, displays a maintenance screen in the app
- **Use case**: During backend updates, migrations, or critical fixes

### `message`
- **Type**: String or null
- **Purpose**: Display important announcements to users
- **Examples**:
  - "Scheduled maintenance on Jan 25, 2PM-4PM EST"
  - "New features available! Update to version 2.0.0"
  - "Service disruption: We're working on a fix"

### `minimumVersion`
- **Type**: String (semantic version)
- **Purpose**: Force users to update if their app version is below this
- **Format**: "MAJOR.MINOR.PATCH" (e.g., "1.2.3")

### `updated`
- **Type**: ISO 8601 timestamp
- **Purpose**: Track when the status was last modified
- **Format**: "YYYY-MM-DDTHH:MM:SSZ"

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
./update-status.sh dev --version "99.0.0" --message "Please update to continue"
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
  "updated": "2025-01-24T14:30:00Z"
}
```

### Force Update
```json
{
  "maintenance": false,
  "message": "Critical security update required. Please update your app.",
  "minimumVersion": "2.0.0",
  "updated": "2025-01-24T10:00:00Z"
}
```

### Normal Operation
```json
{
  "maintenance": false,
  "message": null,
  "minimumVersion": "1.0.0",
  "updated": "2025-01-24T12:00:00Z"
}
```

## Security Considerations

- This repository should be **public** for GitHub Pages to work with the free tier
- Do not include any sensitive information in the status.json
- Consider implementing signature verification in your app for production use
- Rate limit status checks in your app to avoid excessive requests

## Monitoring

Consider setting up:
- GitHub Actions to validate JSON format on push
- Uptime monitoring for the GitHub Pages URL
- Alerts for when maintenance mode is enabled

## Support

For issues or questions about the status page, please open an issue in the main Coffi repository.