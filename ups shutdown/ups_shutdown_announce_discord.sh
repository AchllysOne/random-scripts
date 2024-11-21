#!/bin/bash

# Set PATH to ensure Docker commands are found
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Log file path
LOGFILE="/var/log/pwrstatd-powerfail.log"

# Redirect all output to the log file
exec > >(tee -a $LOGFILE) 2>&1

start_time=$(date +%s)

# Discord Webhook URL and User ID for notifications
WEBHOOK_URL="<put it here>"
USER_ID="<Discord ID>"

# Function to send a Discord notification
send_discord_notification() {
    local message="$1"
    echo "Sending Discord notification: $message"
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"<@${USER_ID}> $message\"}" \
         "$WEBHOOK_URL"
}

# Function to stop Docker containers and list them
stop_docker_containers() {
    local running_containers=$(docker ps --format "{{.Names}}")

    if [ -n "$running_containers" ]; then
        echo "Stopping the following Docker containers:"
        echo "$running_containers"

        send_discord_notification "Warning: The system is shutting down. Stopping the following Docker containers:\n$running_containers"

        echo "Stopping Docker containers..."
        # Stop the Docker containers and capture the output
        stop_output=$(docker stop $(docker ps -q))

        echo "Docker stop command output:"
        echo "$stop_output"

        send_discord_notification "Docker containers have been stopped:\n$running_containers"
        echo "Docker containers have been stopped."
    else
        echo "No running Docker containers to stop."
        send_discord_notification "Warning: The system is shutting down. No running Docker containers to stop."
    fi
}

# Main script execution
echo "Starting shutdown sequence..."
echo "Sending shutdown warning notification to Discord..."
send_discord_notification "Warning: The system is shutting down soon."

echo "Initiating Docker container shutdown..."
stop_docker_containers

end_time=$(date +%s)
execution_time=$((end_time - start_time))

echo "Shutdown sequence completed in $execution_time seconds."

# Optionally, you can initiate the system shutdown here:
# sudo shutdown -h now