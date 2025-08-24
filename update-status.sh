#!/bin/bash

# Coffi Status Update Script
# Usage: ./update-status.sh [prod|dev] [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
MAINTENANCE=""
MESSAGE=""
FORCE_UPDATE=""
UPDATE_MESSAGE=""
VERSION=""
CONFIG=""

# Function to display usage
usage() {
    echo "Usage: $0 [prod|dev] [options]"
    echo ""
    echo "Options:"
    echo "  --maintenance [true|false]  Set maintenance mode"
    echo "  --message \"text\"            Set maintenance message (use \"\" for null)"
    echo "  --force-update [true|false] Set force update flag"
    echo "  --update-message \"text\"     Set update message (use \"\" for null)"
    echo "  --version \"x.y.z\"           Set minimum version"
    echo "  --config \"json\"             Set config object (JSON format)"
    echo "  --help                      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 prod --maintenance true --message \"Scheduled maintenance\""
    echo "  $0 dev --maintenance false"
    echo "  $0 prod --force-update true --update-message \"Critical update required\""
    echo "  $0 dev --config '{\"testMode\":\"true\"}'"
    exit 1
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    usage
fi

ENVIRONMENT=$1
shift

if [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "dev" ]; then
    echo -e "${RED}Error: First argument must be 'prod' or 'dev'${NC}"
    usage
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --maintenance)
            MAINTENANCE="$2"
            if [ "$MAINTENANCE" != "true" ] && [ "$MAINTENANCE" != "false" ]; then
                echo -e "${RED}Error: --maintenance must be 'true' or 'false'${NC}"
                exit 1
            fi
            shift 2
            ;;
        --message)
            MESSAGE="$2"
            shift 2
            ;;
        --force-update)
            FORCE_UPDATE="$2"
            if [ "$FORCE_UPDATE" != "true" ] && [ "$FORCE_UPDATE" != "false" ]; then
                echo -e "${RED}Error: --force-update must be 'true' or 'false'${NC}"
                exit 1
            fi
            shift 2
            ;;
        --update-message)
            UPDATE_MESSAGE="$2"
            shift 2
            ;;
        --config)
            CONFIG="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Determine which file to update
if [ "$ENVIRONMENT" = "prod" ]; then
    STATUS_FILE="status.json"
else
    STATUS_FILE="dev-status.json"
fi

# Read current status
if [ ! -f "$STATUS_FILE" ]; then
    echo -e "${RED}Error: $STATUS_FILE not found${NC}"
    exit 1
fi

# Get current values
CURRENT_MAINTENANCE=$(python3 -c "import json; print(json.load(open('$STATUS_FILE'))['maintenance'])" | tr '[:upper:]' '[:lower:]')
CURRENT_MESSAGE=$(python3 -c "import json; m=json.load(open('$STATUS_FILE')).get('message'); print(m if m else '')")
CURRENT_FORCE_UPDATE=$(python3 -c "import json; print(json.load(open('$STATUS_FILE')).get('forceUpdate', False))" | tr '[:upper:]' '[:lower:]')
CURRENT_UPDATE_MESSAGE=$(python3 -c "import json; m=json.load(open('$STATUS_FILE')).get('updateMessage'); print(m if m else '')")
CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('$STATUS_FILE'))['minimumVersion'])")
CURRENT_CONFIG=$(python3 -c "import json; print(json.dumps(json.load(open('$STATUS_FILE')).get('config', {})))")

# Use current values if not specified
if [ -z "$MAINTENANCE" ]; then
    MAINTENANCE=$CURRENT_MAINTENANCE
fi

if [ -z "$FORCE_UPDATE" ]; then
    FORCE_UPDATE=$CURRENT_FORCE_UPDATE
fi

if [ -z "$VERSION" ]; then
    VERSION=$CURRENT_VERSION
fi

if [ -z "$CONFIG" ]; then
    CONFIG=$CURRENT_CONFIG
fi

# Handle message (empty string means keep current, but we can explicitly set to null)
if [ -z "$MESSAGE" ] && [ $# -eq 0 ]; then
    MESSAGE="$CURRENT_MESSAGE"
fi

if [ -z "$UPDATE_MESSAGE" ] && [ $# -eq 0 ]; then
    UPDATE_MESSAGE="$CURRENT_UPDATE_MESSAGE"
fi

# Convert messages to JSON format
if [ -z "$MESSAGE" ] || [ "$MESSAGE" = "null" ]; then
    MESSAGE_JSON="null"
else
    # Escape quotes in message
    MESSAGE_ESCAPED=$(echo "$MESSAGE" | sed 's/"/\\"/g')
    MESSAGE_JSON="\"$MESSAGE_ESCAPED\""
fi

if [ -z "$UPDATE_MESSAGE" ] || [ "$UPDATE_MESSAGE" = "null" ]; then
    UPDATE_MESSAGE_JSON="null"
else
    # Escape quotes in update message
    UPDATE_MESSAGE_ESCAPED=$(echo "$UPDATE_MESSAGE" | sed 's/"/\\"/g')
    UPDATE_MESSAGE_JSON="\"$UPDATE_MESSAGE_ESCAPED\""
fi

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create the new JSON
cat > "$STATUS_FILE" << EOF
{
  "maintenance": $MAINTENANCE,
  "message": $MESSAGE_JSON,
  "forceUpdate": $FORCE_UPDATE,
  "updateMessage": $UPDATE_MESSAGE_JSON,
  "minimumVersion": "$VERSION",
  "config": $CONFIG,
  "updated": "$TIMESTAMP"
}
EOF

# Display the update
echo -e "${GREEN}✓ Updated $STATUS_FILE${NC}"
echo ""
echo "New status:"
echo -e "${YELLOW}Environment:${NC} $ENVIRONMENT"
echo -e "${YELLOW}Maintenance:${NC} $MAINTENANCE"
echo -e "${YELLOW}Message:${NC} $MESSAGE_JSON"
echo -e "${YELLOW}Force Update:${NC} $FORCE_UPDATE"
echo -e "${YELLOW}Update Message:${NC} $UPDATE_MESSAGE_JSON"
echo -e "${YELLOW}Min Version:${NC} $VERSION"
echo -e "${YELLOW}Config:${NC} $CONFIG"
echo -e "${YELLOW}Updated:${NC} $TIMESTAMP"
echo ""

# Ask if user wants to commit and push
read -p "Do you want to commit and push these changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Build a descriptive commit message
    COMMIT_MSG="Update $ENVIRONMENT status:"
    
    if [ "$MAINTENANCE" = "true" ]; then
        COMMIT_MSG="$COMMIT_MSG Enable maintenance"
        if [ "$MESSAGE_JSON" != "null" ]; then
            COMMIT_MSG="$COMMIT_MSG - $MESSAGE"
        fi
    elif [ "$FORCE_UPDATE" = "true" ]; then
        COMMIT_MSG="$COMMIT_MSG Force update required"
        if [ "$UPDATE_MESSAGE_JSON" != "null" ]; then
            COMMIT_MSG="$COMMIT_MSG - $UPDATE_MESSAGE"
        fi
    else
        COMMIT_MSG="$COMMIT_MSG Normal operation"
    fi
    
    git add "$STATUS_FILE"
    git commit -m "$COMMIT_MSG"
    git push
    echo -e "${GREEN}✓ Changes pushed to GitHub${NC}"
    echo ""
    echo "Status will be available at:"
    if [ "$ENVIRONMENT" = "prod" ]; then
        echo "https://coffi-app.github.io/coffi-status/status.json"
    else
        echo "https://coffi-app.github.io/coffi-status/dev-status.json"
    fi
else
    echo -e "${YELLOW}Changes saved locally but not pushed${NC}"
fi