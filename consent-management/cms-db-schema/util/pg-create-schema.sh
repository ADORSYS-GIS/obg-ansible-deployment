#!/usr/bin/env bash

# create consent schema and give permissions to cms user. Needed for
# docker-compose so  that we can start the DB with the schema already being
# present (rat)
set -e

echo "Creating role 'cms' if it does not exist..."
psql -U postgres -d consent -tc "SELECT 1 FROM pg_roles WHERE rolname='cms'" | grep -q 1 || \
    psql -U postgres -d consent -c "CREATE ROLE cms WITH LOGIN PASSWORD 'cms';"

echo "Creating schema='consent' authorized to cms..."
psql -U postgres -d consent -c "CREATE SCHEMA IF NOT EXISTS consent AUTHORIZATION cms;"

echo "Dropping existing Liquibase changelog tables in schema 'consent' if they exist..."
psql -U postgres -d consent -c "DROP TABLE IF EXISTS consent.databasechangelog CASCADE;"
psql -U postgres -d consent -c "DROP TABLE IF EXISTS consent.databasechangeloglock CASCADE;"

echo "✅ Schema 'consent' is ready and clean for Liquibase migration!"