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
├── status.json          # Main status file
├── README.md           # This file
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
```
https://[username].github.io/coffi-status/status.json
```

Note: It may take a few minutes for GitHub Pages to deploy initially.

## Updating Status

### Manual Update

1. Edit `status.json` with the new values
2. Update the `updated` timestamp
3. Commit and push to main branch:
```bash
git add status.json
git commit -m "Update status: [description]"
git push
```

### Automated Update via GitHub Actions

The repository includes a GitHub Actions workflow that can be triggered manually to update the status.

## Integration with Flutter App

In your Flutter app, fetch the status on startup:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> checkAppStatus() async {
  try {
    final response = await http.get(
      Uri.parse('https://[username].github.io/coffi-status/status.json'),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    // Handle error - default to allowing app to run
    print('Could not fetch status: $e');
  }
  
  return {
    'maintenance': false,
    'message': null,
    'minimumVersion': '1.0.0',
  };
}
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