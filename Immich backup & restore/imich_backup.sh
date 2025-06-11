#!/bin/bash

# Get start time for duration calculation
START_TIME=$(date +%s)

# Configuration
BACKUP_DIR="/mnt/configs/immich/taz"
UPLOAD_DIR="/mnt/configs/immich/upload"
MAX_BACKUPS=3
TIMESTAMP=$(date +"%B_%d_%Y_%I-%M%p")  # e.g. "June_11_2025_02-30PM"

# 1. Backup the database
DB_BACKUP_FILE="$BACKUP_DIR/immich_db_$TIMESTAMP.sql.gz"
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres | gzip > "$DB_BACKUP_FILE"
DB_BACKUP_STATUS=$?

# 2. Shutdown Immich
sudo docker compose down
DOWN_STATUS=$?

# 3. Backup upload directory
UPLOAD_BACKUP_FILE="$BACKUP_DIR/immich_uploads_$TIMESTAMP.tar.gz"
tar -czf "$UPLOAD_BACKUP_FILE" -C "$UPLOAD_DIR" .
UPLOAD_BACKUP_STATUS=$?

# 4. Start Immich back up
sudo docker compose up -d
UP_STATUS=$?

# Cleanup old backups - keep only MAX_BACKUPS
# Database backups cleanup
ls -t "$BACKUP_DIR"/immich_db_*.sql.gz | tail -n +$(($MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null

# Upload backups cleanup
ls -t "$BACKUP_DIR"/immich_uploads_*.tar.gz | tail -n +$(($MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

# Get backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | awk '{print $1}')

# Prepare status message
if [ $DB_BACKUP_STATUS -eq 0 ] && [ $DOWN_STATUS -eq 0 ] && [ $UPLOAD_BACKUP_STATUS -eq 0 ] && [ $UP_STATUS -eq 0 ]; then
    STATUS="✅ SUCCESS"
else
    STATUS="⚠️ COMPLETED WITH WARNINGS"
fi

# Current date for version (already in readable format)
CURRENT_DATE=$(date +'%I:%M%p %A %d %B %Y')

# Discord webhook URL (replace with your actual webhook URL)
WEBHOOK_URL=""

# Send notification to Discord
curl -H "Content-Type: application/json" -d '{
    "embeds": [{
        "title": "Immich Backup Completed",
        "fields": [
            {
                "name": "Backup Status",
                "value": "'"$STATUS"'",
                "inline": true
            },
            {
                "name": "Duration",
                "value": "'"$DURATION_MIN"'m '"$DURATION_SEC"'s",
                "inline": true
            },
            {
                "name": "Size",
                "value": "'"$BACKUP_SIZE"'",
                "inline": true
            },
            {
                "name": "Backup Version",
                "value": "'"$CURRENT_DATE"'",
                "inline": false
            }
        ],
        "color": 16763904
    }]
}' "$WEBHOOK_URL"