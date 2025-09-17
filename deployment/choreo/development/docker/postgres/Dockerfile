# PostgreSQL Server Dockerfile with GitHub backup restore
FROM postgres:16

# Install additional tools for backup restore
RUN apt-get update && apt-get install -y \
    wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Create choreo user and group (required for Choreo platform)
RUN groupadd -g 10014 choreo && \
    useradd -u 10014 -g choreo -s /bin/bash -m choreouser && \
    mkdir -p /home/choreouser/.cache && \
    chown -R choreouser:choreo /home/choreouser && \
    chmod -R 755 /home/choreouser

# Set environment variables
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=nexoan

# GitHub backup restore configuration
ENV GITHUB_BACKUP_REPO=${NEXOAN_GITHUB_BACKUP_REPO:-LDFLK/data-backups} \
    BACKUP_VERSION=${NEXOAN_DB_BACKUP_VERSION:-0.0.1} \
    BACKUP_ENVIRONMENT=${NEXOAN_CHOREO_ENVIRONMENT:-development} \
    RESTORE_FROM_GITHUB=true

# Create additional directories for backups and set permissions for both postgres and choreo users
RUN mkdir -p /var/lib/postgresql/backup /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql/backup /var/lib/postgresql/data && \
    chmod -R 755 /var/lib/postgresql/backup /var/lib/postgresql/data && \
    chown -R 10014:10014 /var/lib/postgresql/backup /var/lib/postgresql/data && \
    chmod -R 755 /var/lib/postgresql/backup /var/lib/postgresql/data

# Copy custom entrypoint script
COPY custom-entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

# Keep running as root for PostgreSQL to work properly
# PostgreSQL needs to run as postgres user, not choreo user

# Define volumes for data persistence
VOLUME ["/var/lib/postgresql/data", "/var/lib/postgresql/backup"]

# Expose ports
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD pg_isready -U postgres || exit 1

# Use custom entrypoint
CMD ["/custom-entrypoint.sh"]