#!/bin/bash

# Define paths
SCRIPT_DIR="/home/scripts"
IMMICH_DIR="/mnt/configs/immich"
BACKUP_DIR="/mnt/backups/immich"

# Navigate to Immich directory
cd "$IMMICH_DIR" || { echo "Failed to cd to $IMMICH_DIR"; exit 1; }

# List available backups with numbers
echo "Available database backups:"
mapfile -t DB_FILES < <(ls "$BACKUP_DIR"/*.sql.gz 2>/dev/null)
if [ ${#DB_FILES[@]} -eq 0 ]; then
    echo "No database backups found in $BACKUP_DIR"
    exit 1
else
    for i in "${!DB_FILES[@]}"; do
        echo "$((i+1)). ${DB_FILES[$i]##*/}"
    done
fi

# Select database backup
read -p "Enter the number of the database backup to restore: " DB_NUM
if [[ ! "$DB_NUM" =~ ^[0-9]+$ ]] || [ "$DB_NUM" -lt 1 ] || [ "$DB_NUM" -gt ${#DB_FILES[@]} ]; then
    echo "Invalid selection"
    exit 1
fi
DB_DUMP="${DB_FILES[$((DB_NUM-1))]}"

# List available upload backups
echo -e "\nAvailable upload backups:"
mapfile -t UPLOAD_FILES < <(ls "$BACKUP_DIR"/*upload*.tar.gz 2>/dev/null)
if [ ${#UPLOAD_FILES[@]} -eq 0 ]; then
    echo "No upload backups found in $BACKUP_DIR"
    exit 1
else
    for i in "${!UPLOAD_FILES[@]}"; do
        echo "$((i+1)). ${UPLOAD_FILES[$i]##*/}"
    done
fi

# Select upload backup
read -p "Enter the number of the upload backup to restore: " UPLOAD_NUM
if [[ ! "$UPLOAD_NUM" =~ ^[0-9]+$ ]] || [ "$UPLOAD_NUM" -lt 1 ] || [ "$UPLOAD_NUM" -gt ${#UPLOAD_FILES[@]} ]; then
    echo "Invalid selection"
    exit 1
fi
UPLOAD_ARCHIVE="${UPLOAD_FILES[$((UPLOAD_NUM-1))]}"

# Restore process
echo -e "\nStarting restore process..."
echo "Using database backup: $DB_DUMP"
echo "Using upload backup: $UPLOAD_ARCHIVE"

# Update containers
echo -e "\nUpdating containers..."
sudo docker compose pull
sudo docker compose create

# Start PostgreSQL
echo -e "\nStarting PostgreSQL..."
docker start immich_postgres
sleep 20

# Restore database
echo -e "\nRestoring database..."
gunzip --stdout "$DB_DUMP" \
    | sed 's/\r\r$//g' \
    | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', false);/" \
    | docker exec -i immich_postgres psql --dbname=postgres --username=postgres

# Shutdown containers
echo -e "\nStopping containers..."
sudo docker compose down

# Restore uploads
echo -e "\nRestoring uploads..."
sudo mkdir -p "$IMMICH_DIR/upload"
sudo tar -xzvf "$UPLOAD_ARCHIVE" -C "$IMMICH_DIR/upload"

# Start containers
echo -e "\nStarting Immich..."
sudo docker compose up -d

echo -e "\nRestore completed successfully!"