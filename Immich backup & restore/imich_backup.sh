#!/bin/bash
BACKUP_DIR="path/to/"
UPLOAD_LOCATION="/path/to/immich/upload" # Change this to your actual path
RETENTION_DAYS=3  # Number of days to keep backups

# Create backup directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR/$TIMESTAMP"

# Backup database
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up PostgreSQL database..."
docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres | gzip > "$BACKUP_DIR/$TIMESTAMP/dump.sql.gz"

# Backup upload locations
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up library files..."
rsync -av "$UPLOAD_LOCATION/library" "$BACKUP_DIR/$TIMESTAMP/"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up upload files..."
rsync -av "$UPLOAD_LOCATION/upload" "$BACKUP_DIR/$TIMESTAMP/"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up profile files..."
rsync -av "$UPLOAD_LOCATION/profile" "$BACKUP_DIR/$TIMESTAMP/"

# Delete backups older than RETENTION_DAYS
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "Backup completed to $BACKUP_DIR/$TIMESTAMP"
echo "Current backups:"
ls -lt "$BACKUP_DIR"