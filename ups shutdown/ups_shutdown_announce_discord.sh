#!/bin/bash

# Set PATH to ensure Docker commands are found
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Log file path
LOGFILE="/var/log/pwrstatd-powerfail.log"

# Redirect all output to the log file
exec > >(tee -a $LOGFILE) 2>&1

# Capture the start time of the script
start_time=$(date +%s)

# Discord Webhook URL and User ID for notifications
WEBHOOK_URL="https://discord.com/api/webhooks/1312520227623276675/L0vNDnfy_RdFRcb-hEb8ivNoBBEbJWnpCZLzBMbPVCCjhZxTJOqefAEoQJriI-L7485T"
USER_ID="1010584431427325993"

# Function to specifically ping and the shutdown attempt warning :O
send_shutdown_warning(){
    echo "Sending Discord notification: Warning: The system is shutting down."

    # Prepare the JSON payload
    local payload="{\"content\": \"<@${USER_ID}> :red_circle: **Warning: The system is shutting down soon.**\"}"

    # Send the request to Discord
    curl -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL"
}

# Function to send a Discord notification with shutdown details o:
send_shutdown_info() {
    local message="$1"
    echo "Sending Discord notification: $message"

    # Escape characters that could break JSON formatting
    message=$(echo "$message" | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\r//g')

    # Prepare the JSON payload
    local payload="{\"content\": \"$message\"}"

    # Send the request to Discord
    curl -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL"
}

# Function to send a Discord notification with shutdown details but this one is for anytime it needs a list of containers :O
send_shutdown_info_C() {
    local message="$1"
    local running_containers="$2"
    running_containers=${running_containers//$'\n'/\\n}

    # Escape characters that could break JSON formatting
    message=$(echo "$message" | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\r//g')

    # Hopefully working loop that concatenates each container onto a list
    message+="\n\`\`\`\n${running_containers}\n\`\`\`"

    echo "Sending Discord notification: $message"

    # Prepare the JSON payload
    local payload="{\"content\": \"$message\"}"

    # Send the request to Discord
    curl -H "Content-Type: application/json" -X POST -d "$payload" "$WEBHOOK_URL"
}

# Function to stop Docker containers and list them
stop_docker_containers() {
    # Get the names of all running containers, separated by newlines and replacing the newlines with "\n" o:
    local running_containers=$(docker ps --format "{{.Names}}")
    running_containers=$(echo "$running_containers" | sort)

    # Check if there are running containers
    if [ -n "$running_containers" ]; then
        echo "Stopping the following Docker containers:"
        echo "$running_containers"

        # Send notification to Discord (only once), with italics for container names
        send_shutdown_info_C ":card_box: **Stopping the following Docker containers:**" "$running_containers"

        # Stop all containers I think :o
        docker stop $(docker ps -q)

        # Get the names of all running containers after the attempted stop o:
        local new_running_containers=$(docker ps --format "{{.Names}}")

        # Find the common substring (The containers that failed to stop) :o

        # Remove the common substring :o
        local stopped_containers=$(comm -23 <(echo "$running_containers" | sort) <(echo "$new_running_containers" | sort))


        # Send notification to Discord only once, with italics for container names
        send_shutdown_info_C ":satellite_orbital: **Docker containers have been stopped:**" "$stopped_containers"
        echo "Docker containers have been stopped."
    else
        echo "No running Docker containers to stop."
        send_shutdown_info ":rotating_light:***No running Docker containers to stop.***"
    fi
}

# Main script execution
echo "Starting shutdown sequence..."
send_shutdown_warning

# Initiating Docker container shutdown
echo "Initiating Docker container shutdown..."
stop_docker_containers

# Capture the end time of the script and calculate execution time
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Output execution time and send final notification to Discord (only once)
echo "Shutdown sequence completed in $execution_time seconds."
send_shutdown_info ":stopwatch: Shutdown sequence completed in *$execution_time seconds*."