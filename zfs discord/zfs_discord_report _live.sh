#!/bin/bash

POOL_NAME="pool"
DISCORD_WEBHOOK_URL="Put here"
USER_ID="ID Here"

# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    local ping="$2"
    local payload=$(jq -n --arg content "$message $ping" '{content: $content}')
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "$payload" \
         "$DISCORD_WEBHOOK_URL"
}

# Function to format the pool status output for better readability
format_pool_status() {
    echo "$1" | sed 's/^[[:space:]]*/    /g'
}

# Function to check pool status and send appropriate message
check_pool_status() {
    local pool_status="$1"
    local formatted_status=$(format_pool_status "$pool_status")

    if echo "$pool_status" | grep -E "DEGRADED|OFFLINE"; then
        send_discord_message "🚨 **CRITICAL: ZFS pool $POOL_NAME has one or more DEGRADED or OFFLINE drives** 🚨\`\`\`$formatted_status\`\`\`" "<@$USER_ID>"
    else
        send_discord_message "✅ **INFO: ZFS pool $POOL_NAME is healthy**\`\`\`$formatted_status\`\`\`" ""
    fi
}

# Regular check
pool_status=$(zpool status $POOL_NAME)
check_pool_status "$pool_status"