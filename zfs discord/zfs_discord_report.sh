#!/bin/bash

POOL_NAME="<pool name>"
DISCORD_WEBHOOK_URL="<Put it here>"
USER_ID="<User ID to ping>"

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

# Test condition for normal status
if [ "$1" == "test" ]; then
    pool_status=$(zpool status $POOL_NAME)
    check_pool_status "$pool_status"
    exit 0
fi

# Test condition for degraded status
if [ "$1" == "test-degraded" ]; then
    pool_status="  pool: $POOL_NAME
    state: DEGRADED
    status: One or more devices has been taken offline by the administrator.
            Sufficient replicas exist for the pool to continue functioning in a
            degraded state.
      scan: resilvered 548K in 00:00:01 with 0 errors on Mon Aug  5 18:44:50 2024
    config:

        NAME        STATE     READ WRITE CKSUM
        $POOL_NAME  DEGRADED     0     0     0
          raidz3-0  DEGRADED     0     0     0
            sda     ONLINE       0     0     0
            sdh     ONLINE       0     0     0
            sdi     ONLINE       0     0     0
            sdc     ONLINE       0     0     0
            sdb     ONLINE       0     0     0
            sdd     ONLINE       0     0     0
            sde     ONLINE       0     0     0
            sdf     ONLINE       0     0     0
            sdm     ONLINE       0     0     0
            sdn     ONLINE       0     0     0
            sdg     OFFLINE      0     0     0
        cache
          nvme1n1   ONLINE       0     0     0

    errors: No known data errors"
    check_pool_status "$pool_status"
    exit 0
fi

# Regular check
pool_status=$(zpool status $POOL_NAME)
check_pool_status "$pool_status"
