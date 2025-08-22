#!/bin/bash

# Neo4j backup script that handles the case when database doesn't exist
# Usage: ./backup-neo4j.sh [backup_directory]

set -e

# Default backup directory
BACKUP_DIR=${NEO4J_BACKUP_DIR:-${1:-"/backups"}}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${BACKUP_DIR}/neo4j_backup_${TIMESTAMP}"

# Neo4j credentials
NEO4J_USER=${NEO4J_USER:-"neo4j"}
NEO4J_PASSWORD=${NEO4J_PASSWORD:-"neo4j123"}

echo "Starting Neo4j backup process..."

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to be ready..."
until curl -s http://localhost:7474 > /dev/null; do
    echo "Neo4j not ready yet, waiting..."
    sleep 5
done

# Check if the neo4j database exists
echo "Checking if neo4j database exists..."
DB_EXISTS=$(cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system \
    "SHOW DATABASES YIELD name WHERE name = 'neo4j' RETURN count(*) as count;" \
    --format plain | tail -n 1 | tr -d ' ')

if [ "$DB_EXISTS" = "0" ]; then
    echo "Database 'neo4j' does not exist. Creating it first..."
    cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system \
        "CREATE DATABASE neo4j;"
    echo "Database 'neo4j' created successfully."
    
    # Wait a moment for the database to be fully created
    sleep 10
else
    echo "Database 'neo4j' already exists."
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_PATH"

# Perform the backup
echo "Starting database dump..."
neo4j-admin database dump neo4j --to-path="$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully!"
    echo "Backup location: $BACKUP_PATH"
    
    # Create a compressed archive
    cd "$BACKUP_DIR"
    tar -czf "neo4j_backup_${TIMESTAMP}.tar.gz" "neo4j_backup_${TIMESTAMP}"
    rm -rf "neo4j_backup_${TIMESTAMP}"
    
    echo "Compressed backup created: neo4j_backup_${TIMESTAMP}.tar.gz"
else
    echo "Backup failed!"
    exit 1
fi
