#!/bin/sh

# Delay to ensure the network is ready
sleep 20

# Start all Docker containers
docker start $(docker ps -a -q)

# Discord webhook URL
webhook_url="<Put it here>"

# Your Discord user ID
user_id="<Put Discord ID here>"

# Get the list of all running Docker containers
docker_containers=$(docker ps --format "{{.Names}}" | sed 's/^/• /')

# Prepare the message
message=":satellite: **Server Status:**\n\n:green_circle: The server is back online!\n\n:card_file_box: **Loaded Docker Containers:**\n\`\`\`\n${docker_containers}\n\`\`\`"

# Escape newlines in the message for JSON
message=$(echo "$message" | sed ':a;N;$!ba;s/\n/\\n/g')

# Send the notification to Discord
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"<@${user_id}> $message\"}" "$webhook_url"