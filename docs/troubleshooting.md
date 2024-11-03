# Troubleshooting Guide

## Common Issues

### Container Issues

#### Container Won't Start

```bash
# Check container status
docker ps -a

# View container logs
./captainarr.sh logs service-name

# Common solutions:
1. Check port conflicts
2. Verify permissions
3. Check disk space
4. Review configuration
```

#### Container Keeps Restarting

```bash
# Check container health
docker inspect service-name

# View recent logs
docker logs --tail 100 service-name

# Solutions:
1. Check memory limits
2. Verify configuration
3. Check dependencies
```

### Network Issues

#### Service Not Accessible

1. Check Traefik dashboard
2. Verify DNS resolution
3. Check port forwarding
4. Review service logs

```bash
# Test internal network
docker network inspect media_network

# Check port availability
netstat -tulpn | grep PORT
```

#### Proxy Errors

```bash
# Check Traefik logs
./captainarr.sh logs traefik

# Verify labels
docker inspect service-name | grep -A 10 Labels
```

### Storage Issues

#### Disk Space

```bash
# Check disk usage
df -h

# Find large files
du -h --max-depth=1 ${STORAGE_ROOT}

# Solutions:
1. Clean unused images
2. Remove old backups
3. Clean download cache
```

#### Permission Issues

```bash
# Fix permissions
sudo chown -R $USER:$USER config/
sudo chown -R $USER:$USER storage/
chmod -R 755 config/
chmod -R 755 storage/
```

### Media Management Issues

#### Download Problems

1. Check indexer status
2. Verify category settings
3. Check disk space
4. Review quality settings

```bash
# Check download client
./captainarr.sh logs qbittorrent

# Verify paths
ls -la ${STORAGE_ROOT}/TORRENTS/COMPLETE
```

#### Import Failures

```bash
# Check media permissions
ls -la ${STORAGE_ROOT}/MOVIES
ls -la ${STORAGE_ROOT}/SERIES

# Review *arr logs
./captainarr.sh logs sonarr
./captainarr.sh logs radarr
```

## Diagnostic Tools

### Log Analysis

```bash
# Full stack logs
./captainarr.sh logs > full_logs.txt

# Service-specific logs
./captainarr.sh logs service-name > service_logs.txt

# Search logs
grep -i "error" logs/*.log
```

### Network Diagnostics

```bash
# Check connectivity
ping service-name

# Trace routes
traceroute domain.com

# Check DNS
nslookup domain.com
```

### Health Checks

```bash
# System health
./captainarr.sh check

# Docker health
docker system df
docker system info
```

## Recovery Procedures

### Basic Recovery

```bash
# Restart service
./captainarr.sh restart service-name

# Rebuild service
docker-compose up -d --force-recreate service-name
```

### Full Stack Recovery

```bash
# Stop all services
./captainarr.sh stop

# Remove containers
docker-compose down

# Rebuild stack
docker-compose up -d
```

### Database Recovery

1. Stop affected service
2. Backup current database
3. Restore from backup
4. Verify integrity
5. Restart service

### Configuration Recovery

```bash
# Restore from backup
./captainarr.sh restore backup_file.tar.gz

# Verify configuration
./captainarr.sh check
```

## Prevention Measures

### Monitoring

```bash
# Set up monitoring
# monitoring.sh
#!/bin/bash
./captainarr.sh check
./captainarr.sh logs | grep -i error
df -h ${STORAGE_ROOT}
```

### Automated Backups

```bash
# Daily backup cron
0 4 * * * /path/to/captainarr.sh backup
```

### Resource Alerts

```yaml
# Docker compose alerts
services:
  service-name:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 1m
      timeout: 10s
      retries: 3
```

## Service-Specific Issues

### Plex

1. Transcoding issues
2. Library scan problems
3. Authentication failures
4. Database corruption

### Sonarr/Radarr

1. Failed downloads
2. Import errors
3. Indexer issues
4. Path problems

### qBittorrent

1. Connection issues
2. Category problems
3. Space limitations
4. Permission errors

## Advanced Troubleshooting

### Docker Debugging

```bash
# Container details
docker inspect container_name

# Network debugging
docker network inspect media_network

# Process information
docker top container_name
```

### Database Debugging

```bash
# Backup database
cp config/service/database.db database.backup.db

# Check integrity
sqlite3 database.db "PRAGMA integrity_check;"
```

### Log Level Adjustment

```yaml
# Increase log detail
environment:
  - LOG_LEVEL=Debug
```

## Getting Help

### Support Resources

1. Project documentation
2. Community forums
3. GitHub issues
4. Reddit communities

### Reporting Issues

1. Gather logs
2. Document steps to reproduce
3. Include configuration
4. Provide system details

### Debug Information

```bash
# Generate debug package
./captainarr.sh logs > debug_logs.txt
docker inspect $(docker ps -q) > docker_info.txt
./captainarr.sh check > system_check.txt
```

Remember to always backup before making changes and document any modifications for future reference.
