#!/bin/bash

# Get arguments
CHANGED_FILES="$1"
REPOSITORY="$2"

# Get git information
AUTHOR_NAME="$(git log -1 --pretty="%aN")"
COMMITTER_NAME="$(git log -1 --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 --pretty="%b")"
COMMIT_SHA="$(git rev-parse --short HEAD)"
BRANCH="${GITHUB_REF#refs/heads/}"

# Format credits
if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
    CREDITS="$AUTHOR_NAME authored & committed"
else
    CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

# Get current timestamp
TIMESTAMP=$(date --utc +%FT%TZ)

# Prepare webhook data
WEBHOOK_DATA='{
    "embeds": [{
        "color": 16737095,
        "author": {
            "name": "⚠️ AWS Account Permissions Changed - '"$REPOSITORY"'"
        },
        "title": "'"$COMMIT_SUBJECT"'",
        "description": "🔐 AWS Account permissions have been modified\n\n**Modified Infrastructure Files:**\n```\n'"$CHANGED_FILES"'\n```\n\n**Modified By:**\n'"$CREDITS"'",
        "fields": [
            {
                "name": "Commit",
                "value": "'"$COMMIT_SHA"'",
                "inline": true
            },
            {
                "name": "Branch",
                "value": "'"$BRANCH"'",
                "inline": true
            }
        ],
        "timestamp": "'"$TIMESTAMP"'"
    }]
}'

# Send webhook
curl --fail --progress-bar \
    -A "GitHub-Actions-Webhook" \
    -H "Content-Type: application/json" \
    -d "$WEBHOOK_DATA" \
    "$DISCORD_WEBHOOK" \
    && echo -e "\n[Webhook]: Successfully sent the webhook." \
    || echo -e "\n[Webhook]: Unable to send webhook."