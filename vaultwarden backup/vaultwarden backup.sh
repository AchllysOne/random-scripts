#!/bin/bash

# Set the script to exit immediately if any command fails
set -e

DATE=$(date +%Y-%m-%d)
BACKUP_DIR=/path/to/file/vaultwarden/vaultwarden  # Corrected path
BACKUP_FILE=backup_vaultwarden-$DATE.tar.gz  # Renamed backup file
CONTAINER=vaultwarden
CONTAINER_DATA_DIR=/path/to/file/vaultwarden/bitwarden  # Updated path

# Discord Webhook URL (replace with your own)
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_URL"

# Create backups directory if it does not exist
mkdir -p $BACKUP_DIR

# Stop the container
/usr/bin/docker stop $CONTAINER

# Backup the vaultwarden data directory to the backup directory
tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C "$CONTAINER_DATA_DIR" .

# Restart the container
/usr/bin/docker restart $CONTAINER

# To delete files older than 30 days
find $BACKUP_DIR/* -mtime +30 -exec rm {} \;

# Send a success notification to Discord
curl -X POST -H "Content-Type: application/json" \
  -d '{"content": "Vaultwarden backup completed successfully! Backup file: '"$BACKUP_FILE"'"}' \
  $DISCORD_WEBHOOK_URL
