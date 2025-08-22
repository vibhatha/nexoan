# Neo4j Backup Solutions

This directory contains backup solutions for Neo4j that handle the "Database does not exist" error.

## Problem
The error occurs because Neo4j 5.x doesn't automatically create the default "neo4j" database when the container starts. When you try to backup a non-existent database, you get:
```
Database does not exist: neo4j
```

## Solutions

### Solution 1: Manual Backup Script (Recommended)
Use the standalone backup script that automatically creates the database if it doesn't exist:

```bash
# Make the script executable
chmod +x scripts/backup-neo4j.sh

# Run the backup
./scripts/backup-neo4j.sh
```

This script will:
1. Check if Neo4j container is running
2. Wait for Neo4j to be ready
3. Check if the "neo4j" database exists
4. Create the database if it doesn't exist
5. Perform the backup
6. Create a compressed archive

### Solution 2: Docker Compose Backup Service
Use the separate docker-compose file for backup operations:

```bash
# Start your main services
docker-compose up -d

# Run backup using the backup profile
docker-compose -f docker-compose.backup.yml --profile backup up neo4j-backup
```

### Solution 3: Direct Container Commands
You can also run backup commands directly in the container:

```bash
# Connect to the Neo4j container
docker exec -it neo4j bash

# Create the database if it doesn't exist
cypher-shell -u neo4j -p neo4j123 -d system "CREATE DATABASE neo4j IF NOT EXISTS;"

# Perform the backup
neo4j-admin database dump neo4j --to-path="/tmp/backup"
```

## Backup Location
Backups are stored in the `./backups/` directory with timestamps:
- `neo4j_backup_YYYYMMDD_HHMMSS.tar.gz`

## Prerequisites
- Neo4j container must be running
- Docker must be installed and running
- The scripts assume default Neo4j credentials (neo4j/neo4j123)

## Environment Variables

You can customize the backup behavior using environment variables:

- `NEO4J_BACKUP_DIR`: Path where backups will be stored (default: `./backups` for manual script, `/backups` for docker-compose)
- `NEO4J_USER`: Neo4j username (default: `neo4j`)
- `NEO4J_PASSWORD`: Neo4j password (default: `neo4j123`)

### Examples:

```bash
# Set custom backup directory
export NEO4J_BACKUP_DIR="/path/to/your/backups"
./scripts/backup-neo4j.sh

# Or inline
NEO4J_BACKUP_DIR="/path/to/your/backups" ./scripts/backup-neo4j.sh

# For docker-compose backup
NEO4J_BACKUP_DIR="/custom/backup/path" docker-compose -f docker-compose.backup.yml --profile backup up neo4j-backup
```

## Troubleshooting

### If backup still fails:
1. Check if Neo4j container is running: `docker ps | grep neo4j`
2. Check Neo4j logs: `docker logs neo4j`
3. Verify connectivity: `docker exec neo4j curl http://localhost:7474`
4. Check database existence: `docker exec neo4j cypher-shell -u neo4j -p neo4j123 -d system "SHOW DATABASES;"`

### Common Issues:
- **Container not running**: Start with `docker-compose up -d`
- **Wrong credentials**: Update the script with your actual Neo4j credentials
- **Permission issues**: Make sure the backup script is executable
- **Network issues**: Ensure the container can reach Neo4j on localhost
