#!/bin/bash
# Restore script for SimpleCP data

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -1t backups/simplecp_backup_*.tar.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "=== SimpleCP Restore Script ==="
echo ""
echo "WARNING: This will overwrite current data!"
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

# Create backup of current data
if [ -d "data" ]; then
    echo "Backing up current data..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    tar -czf "backups/pre_restore_${TIMESTAMP}.tar.gz" data/ logs/ 2>/dev/null || true
fi

# Extract backup
echo "Restoring from: $BACKUP_FILE"
tar -xzf "$BACKUP_FILE"

echo ""
echo "Restore complete!"
echo "Pre-restore backup saved to: backups/pre_restore_${TIMESTAMP}.tar.gz"
