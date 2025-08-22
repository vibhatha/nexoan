#!/bin/bash

# Standalone Neo4j backup script
# This script can be run manually to backup Neo4j without modifying docker-compose.yml

set -e

# Configuration
NEO4J_CONTAINER="${NEO4J_CONTAINER:-"neo4j"}"
NEO4J_USER="${NEO4J_USER:-"neo4j"}"
NEO4J_PASSWORD="${NEO4J_PASSWORD:-"neo4j123"}"
BACKUP_DIR="${NEO4J_BACKUP_DIR:-"./backups"}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Starting Neo4j backup process..."

# Check if Neo4j container is running
if ! docker ps | grep -q "$NEO4J_CONTAINER"; then
    echo "Error: Neo4j container is not running!"
    echo "Please start your services with: docker-compose up -d"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Wait for Neo4j to be ready
echo "Waiting for Neo4j to be ready..."
until docker exec "$NEO4J_CONTAINER" curl -s http://localhost:7474 > /dev/null 2>&1; do
    echo "Neo4j not ready yet, waiting..."
    sleep 5
done

# Check if the neo4j database exists and create it if it doesn't
echo "Checking if neo4j database exists..."
DB_EXISTS=$(docker exec "$NEO4J_CONTAINER" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system \
    "SHOW DATABASES YIELD name WHERE name = 'neo4j' RETURN count(*) as count;" \
    --format plain 2>/dev/null | tail -n 1 | tr -d ' ' || echo "0")

if [ "$DB_EXISTS" = "0" ]; then
    echo "Database 'neo4j' does not exist. Creating it first..."
    docker exec "$NEO4J_CONTAINER" cypher-shell -u "$NEO4J_USER" -p "$NEO4J_PASSWORD" -d system \
        "CREATE DATABASE neo4j;"
    echo "Database 'neo4j' created successfully."
    
    # Wait a moment for the database to be fully created
    sleep 10
else
    echo "Database 'neo4j' already exists."
fi

# Perform the backup
echo "Starting database dump..."
docker exec "$NEO4J_CONTAINER" neo4j-admin database dump neo4j --to-path="/tmp/neo4j_backup_${TIMESTAMP}"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully!"
    
    # Copy backup from container to host
    docker cp "$NEO4J_CONTAINER:/tmp/neo4j_backup_${TIMESTAMP}" "$BACKUP_DIR/"
    
    # Create a compressed archive
    cd "$BACKUP_DIR"
    tar -czf "neo4j_backup_${TIMESTAMP}.tar.gz" "neo4j_backup_${TIMESTAMP}"
    rm -rf "neo4j_backup_${TIMESTAMP}"
    
    # Clean up temporary backup in container
    docker exec "$NEO4J_CONTAINER" rm -rf "/tmp/neo4j_backup_${TIMESTAMP}"
    
    echo "Compressed backup created: $BACKUP_DIR/neo4j_backup_${TIMESTAMP}.tar.gz"
else
    echo "Backup failed!"
    exit 1
fi
