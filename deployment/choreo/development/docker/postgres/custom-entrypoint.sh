#!/bin/bash
set -e

# Logging function
log() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1: $2"
}

# Function to restore PostgreSQL from backup file (based on init.sh)
restore_postgres() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    log "INFO" "Using backup file: $(basename "$backup_file")"
    
    # Extract backup file
    local temp_dir=$(mktemp -d)
    local backup_name="nexoan.sql"
    
    log "INFO" "Extracting backup file..."
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Copy backup to PostgreSQL backup directory
    log "INFO" "Copying backup to container..."
    cp "$temp_dir/$backup_name" "/var/lib/postgresql/backup/"
    chown postgres:postgres "/var/lib/postgresql/backup/$backup_name"
    
    # Check what was actually created
    log "INFO" "Checking backup structure in container..."
    ls -la "/var/lib/postgresql/backup/"
    
    # Restore database
    log "INFO" "Restoring PostgreSQL database..."
    if psql -U postgres -d nexoan -f "/var/lib/postgresql/backup/$backup_name"; then
        log "SUCCESS" "PostgreSQL restore completed successfully"
        
        # Verify what was restored
        log "INFO" "Verifying restored database..."
        psql -U postgres -d nexoan -c "\dt"
        
        # Clean up
        rm -f "/var/lib/postgresql/backup/$backup_name"
        rm -rf "$temp_dir"
        
    else
        log "ERROR" "PostgreSQL restore failed"
        rm -f "/var/lib/postgresql/backup/$backup_name"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to download and extract files from GitHub archive (based on init.sh)
download_github_archive() {
    local version="$1"
    local extract_dir="$2"
    local github_repo="${GITHUB_BACKUP_REPO:-LDFLK/data-backups}"
    
    log "INFO" "Downloading GitHub archive for version $version..."
    
    # Download the archive
    local archive_url="https://github.com/$github_repo/archive/refs/tags/$version.zip"
    local archive_file="$extract_dir/archive.zip"
    
    if wget -q "$archive_url" -O "$archive_file"; then
        log "SUCCESS" "Downloaded archive for version $version"
        
        # Extract the archive
        if unzip -q "$archive_file" -d "$extract_dir"; then
            log "SUCCESS" "Extracted archive"
            rm -f "$archive_file"  # Clean up archive file
            return 0
        else
            log "ERROR" "Failed to extract archive"
            return 1
        fi
    else
        log "ERROR" "Failed to download archive for version $version"
        return 1
    fi
}

# Function to restore from GitHub backup (based on init.sh)
restore_from_github() {
    local version="${BACKUP_VERSION:-0.0.1}"
    local environment="${BACKUP_ENVIRONMENT:-development}"
    
    log "INFO" "Restoring from GitHub version: $version"
    
    # Create temporary directory for downloads
    local temp_dir=$(mktemp -d)
    
    # Download the entire archive
    if ! download_github_archive "$version" "$temp_dir"; then
        log "ERROR" "Failed to download GitHub archive for version $version"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Set the extracted directory path
    local archive_dir="$temp_dir/data-backups-$version"
    
    # Download and restore PostgreSQL
    log "INFO" "Processing PostgreSQL backup..."
    local postgres_file="$archive_dir/nexoan/version/$version/$environment/postgres/nexoan.tar.gz"
    if [ -f "$postgres_file" ]; then
        if restore_postgres "$postgres_file"; then
            log "SUCCESS" "PostgreSQL restored successfully"
            rm -rf "$temp_dir"
            return 0
        else
            log "ERROR" "PostgreSQL restore failed"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log "ERROR" "PostgreSQL backup not found: $postgres_file"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Initialize PostgreSQL data directory if it's empty
if [ ! -d "/var/lib/postgresql/data" ] || [ -z "$(ls -A /var/lib/postgresql/data 2>/dev/null)" ]; then
    log "INFO" "Initializing PostgreSQL data directory..."
    docker-entrypoint.sh postgres --initdb
fi

# Start PostgreSQL in background first
log "INFO" "Starting PostgreSQL in background..."
docker-entrypoint.sh postgres &
POSTGRES_PID=$!

# Wait for PostgreSQL to be ready
log "INFO" "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if pg_isready -U postgres -q; then
        log "INFO" "PostgreSQL is ready!"
        break
    fi
    log "INFO" "Waiting for PostgreSQL... attempt $i/30"
    sleep 2
done

# Create nexoan database if it doesn't exist
log "INFO" "Creating nexoan database if it doesn't exist..."
createdb -U postgres nexoan 2>/dev/null || true

# Check if restore is needed
if [ "${RESTORE_FROM_GITHUB:-false}" = "true" ]; then
    # Check if nexoan database has any tables
    table_count=$(psql -U postgres -d nexoan -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' \n' || echo "0")
    
    if [ "$table_count" -eq 0 ]; then
        log "INFO" "nexoan database is empty, starting GitHub restore..."
        restore_from_github || log "WARNING" "GitHub restore failed, continuing with empty database"
    else
        log "INFO" "nexoan database already has $table_count tables, skipping restore"
    fi
fi

# Stop the background PostgreSQL gracefully
log "INFO" "Stopping background PostgreSQL..."
su - postgres -c "pg_ctl stop -D /var/lib/postgresql/data -m smart" || kill $POSTGRES_PID 2>/dev/null || true
sleep 3

# Start PostgreSQL in foreground
log "INFO" "Starting PostgreSQL in foreground mode..."
exec docker-entrypoint.sh postgres
