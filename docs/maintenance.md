# Maintenance Guide

## Routine Maintenance

### Daily Tasks

```bash
# Check system status
./captainarr.sh status

# View important logs
./captainarr.sh logs | grep -i "error\|warning"

# Monitor disk space
./captainarr.sh check
```

### Weekly Tasks

```bash
# Update containers
./captainarr.sh update

# Create backup
./captainarr.sh backup

# Clean unused Docker resources
./captainarr.sh prune
```

### Monthly Tasks

1. Review and clean media libraries
2. Check and update API keys
3. Verify backup integrity
4. Review security settings
5. Clean metadata/cache

## Backup Management

### Creating Backups

```bash
# Manual backup
./captainarr.sh backup

# Automated backup (cron)
0 4 * * * /path/to/captainarr.sh backup
```

### Backup Contents

- Service configurations
- API keys and settings
- Custom scripts
- Database files

### Backup Location

```
backups/
├── backup_20240101_120000.tar.gz
├── backup_20240108_120000.tar.gz
└── ...
```

### Restore from Backup

```bash
# List available backups
ls -l backups/

# Restore specific backup
./captainarr.sh restore backups/backup_20240101_120000.tar.gz
```

## Update Management

### Automatic Updates

Managed by Watchtower:

```yaml
environment:
  - WATCHTOWER_SCHEDULE=0 0 4 * * *
  - WATCHTOWER_CLEANUP=true
  - WATCHTOWER_NOTIFICATIONS=true
```

### Manual Updates

```bash
# Update all containers
./captainarr.sh update

# Update specific service
docker-compose pull service-name
docker-compose up -d service-name
```

### Update Verification

```bash
# Check container versions
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# View update logs
./captainarr.sh logs watchtower
```

## Storage Management

### Disk Space Monitoring

```bash
# Check disk usage
df -h ${STORAGE_ROOT}

# Find large files
find ${STORAGE_ROOT} -type f -size +1G -exec ls -lh {} \;
```

### Clean Up Operations

```bash
# Remove unused Docker resources
docker system prune -a

# Clean download cache
rm -rf ${STORAGE_ROOT}/TORRENTS/INCOMPLETE/*
```

### Storage Optimization

1. Enable hardlinks in \*arr services
2. Configure appropriate retention rules
3. Use quality size limits
4. Enable duplicate detection

## Database Maintenance

### Sonarr/Radarr/Lidarr

1. Backup database
2. Perform database maintenance
3. Remove orphaned files
4. Optimize indexes

### Plex

1. Empty trash
2. Clean bundles
3. Optimize database
4. Remove unused media

## Performance Optimization

### Docker Optimization

```yaml
# Resource limits
services:
  plex:
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: 4G
```

### Network Optimization

1. Enable hardware acceleration
2. Configure appropriate transcoding settings
3. Optimize network paths
4. Monitor bandwidth usage

## Health Monitoring

### System Health Check

```bash
# Full system check
./captainarr.sh check

# Components checked:
- Container status
- Disk space
- Network connectivity
- Service response
- Database status
```

### Automated Monitoring

```bash
# Set up monitoring cron
*/15 * * * * /path/to/captainarr.sh check > /var/log/health.log 2>&1
```

### Alert Configuration

```yaml
environment:
  - NOTIFICATION_URL=discord://webhook-url
```

## Log Management

### Log Rotation

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Log Analysis

```bash
# View service logs
./captainarr.sh logs service-name

# Search logs for errors
./captainarr.sh logs | grep -i error

# Export logs
./captainarr.sh logs > service_logs.txt
```

## Recovery Procedures

### Service Recovery

```bash
# Restart failed service
./captainarr.sh restart service-name

# Full stack restart
./captainarr.sh restart
```

### Data Recovery

1. Stop affected services
2. Restore from backup
3. Verify data integrity
4. Restart services
5. Update configurations if needed

## Maintenance Scripts

### Cleanup Script

```bash
#!/bin/bash
# cleanup.sh
./captainarr.sh stop
docker system prune -af
./captainarr.sh start
```

### Backup Script

```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d)
./captainarr.sh backup
find backups/ -mtime +30 -delete
```

## Documentation Maintenance

### Update Documentation

1. Record configuration changes
2. Document troubleshooting steps
3. Update network diagrams
4. Maintain change log

### Version Control

```bash
# Track configuration changes
git init
git add .
git commit -m "Update configuration"
```
