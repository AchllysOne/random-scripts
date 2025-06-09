#!/bin/bash
BACKUP_DIR="/path/to/immich/backup"
UPLOAD_LOCATION="/path/to/immich/upload"
DOCKER_USER="node"  # The user that runs Immich in containers (typically node or abc)

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_timestamp>"
    echo "Available backups:"
    ls -lt "$BACKUP_DIR" | grep '^d'
    exit 1
fi

BACKUP_PATH="$BACKUP_DIR/$1"

if [ ! -d "$BACKUP_PATH" ]; then
    echo "Error: Backup $1 not found!"
    exit 1
fi

echo "=== IMMICH RESTORE PROCEDURE ==="
echo "WARNING: This will delete all current Immich data!"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "[1/6] Stopping Immich services..."
docker compose down -v

echo "[2/6] Setting proper permissions on upload directory..."
sudo chown -R $DOCKER_USER:$DOCKER_USER "$UPLOAD_LOCATION"
sudo chmod -R 775 "$UPLOAD_LOCATION"

echo "[3/6] Starting Postgres..."
docker compose create
docker start immich_postgres

echo "[4/6] Waiting for Postgres to be ready..."
sleep 10

echo "[5/6] Restoring database..."
gunzip --stdout "$BACKUP_PATH/dump.sql.gz" \
| sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" \
| docker exec -i immich_postgres psql --dbname=postgres --username=postgres

echo "[6/6] Restoring upload locations..."
sudo -u $DOCKER_USER rsync -a --no-perms --no-owner --no-group "$BACKUP_PATH/library/" "$UPLOAD_LOCATION/library/"
sudo -u $DOCKER_USER rsync -a --no-perms --no-owner --no-group "$BACKUP_PATH/upload/" "$UPLOAD_LOCATION/upload/"
sudo -u $DOCKER_USER rsync -a --no-perms --no-owner --no-group "$BACKUP_PATH/profile/" "$UPLOAD_LOCATION/profile/"

echo "[7/6] Starting Immich services..."
docker compose up -d

echo "Restore completed from backup $1