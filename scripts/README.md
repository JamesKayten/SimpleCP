# SimpleCP Utility Scripts

This directory contains utility scripts for development, deployment, and maintenance.

## Installation Scripts

### `install.sh`
Install SimpleCP with all dependencies.

```bash
./scripts/install.sh
```

### `setup_dev.sh`
Setup complete development environment.

```bash
./scripts/setup_dev.sh
```

## Operations Scripts

### `backup.sh`
Create backup of data and configuration.

```bash
./scripts/backup.sh
```

### `restore.sh`
Restore from a backup file.

```bash
./scripts/restore.sh backups/simplecp_backup_20240101_120000.tar.gz
```

### `healthcheck.sh`
Check if the API is healthy.

```bash
./scripts/healthcheck.sh

# Custom URL
API_URL=http://localhost:8080 ./scripts/healthcheck.sh
```

### `clean.sh`
Clean build artifacts and cache files.

```bash
./scripts/clean.sh
```

## Usage

Make scripts executable:

```bash
chmod +x scripts/*.sh
```

Run any script:

```bash
./scripts/<script_name>.sh
```

## Integration

These scripts can be integrated into:

- **Cron jobs** for automated backups
- **CI/CD pipelines** for automated testing
- **Systemd services** for service management

## Examples

### Automated Daily Backups

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/SimpleCP && ./scripts/backup.sh
```

### Health Monitoring

Check health every minute:

```bash
# Add to crontab
* * * * * /path/to/SimpleCP/scripts/healthcheck.sh || echo "SimpleCP is down!"
```
