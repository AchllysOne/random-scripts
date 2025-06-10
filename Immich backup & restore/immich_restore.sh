#!/bin/bash

# Pull and create containers
docker compose pull
docker compose create

# Start PostgreSQL and wait for it to be ready
docker start immich_postgres
sleep 15

# 1. Restore the database with proper line ending handling
gunzip --stdout "/mnt/configs/immich/taz/dump.sql.gz" \
    | sed 's/\r\r$//g' \
    | sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_c>    | docker exec -i immich_postgres psql --dbname=postgres --username=postgres

# 2. Shutdown Immich containers
docker compose down

# 3. Restore uploads and start containers
sudo mkdir -p /mnt/configs/immich/upload
sudo tar -xzvf /mnt/configs/immich/taz/upload.tar.gz -C /mnt/configs/immich/upload
sudo docker compose up -d

echo "Database restore completed. You can now start Immich with 'docker compose up -d'"