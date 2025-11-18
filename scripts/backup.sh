#!/bin/bash
# Backup script for SimpleCP data

set -e

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="simplecp_backup_${TIMESTAMP}"

echo "=== SimpleCP Backup Script ==="
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup archive
echo "Creating backup: ${BACKUP_NAME}.tar.gz"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
    data/ \
    logs/ \
    .env \
    2>/dev/null || true

echo "Backup created: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

# Keep only last 7 backups
echo "Cleaning old backups (keeping last 7)..."
cd "$BACKUP_DIR"
ls -t simplecp_backup_*.tar.gz | tail -n +8 | xargs -r rm --

echo ""
echo "Backup complete!"
echo "Location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
