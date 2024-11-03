# Configuration Guide

## Environment Configuration

### Core Settings

```env
# System
TZ=UTC                     # Your timezone
DOMAIN=localhost           # Your domain name
BASE_PATH=/               # Base URL path

# Paths
CONFIG_ROOT=./config      # Configuration storage
STORAGE_ROOT=/path/to/storage  # Media storage

# Ports
TRAEFIK_PORT=80           # Main web port
```

### Media Paths

```env
# Internal container paths (don't change)
MOVIES_PATH=/movies
SERIES_PATH=/tv
BOOKS_PATH=/books
MUSIC_PATH=/music
DOWNLOADS_PATH=/downloads

# Download Categories
QB_CATEGORY_TV=tv-sonarr
QB_CATEGORY_MOVIES=movies-radarr
QB_CATEGORY_MUSIC=music-lidarr
QB_CATEGORY_BOOKS=books-readarr
```

### Service Configuration

```env
# Plex
PLEX_CLAIM=claim-xxxxx    # From plex.tv/claim

# Deletion Settings
DELETE_AFTER_SEED=false   # Auto-delete after ratio met
```

## Service Configurations

### Traefik Configuration

Location: `config/traefik/traefik.yml`

```yaml
api:
  dashboard: true
  insecure: true # Change in production

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
```

### qBittorrent Configuration

Location: `config/qbittorrent/qBittorrent.conf`

```ini
[Preferences]
Downloads\SavePath=/downloads/complete
Downloads\TempPath=/downloads/incomplete
WebUI\Port=8080
```

### Media Managers Configuration

Common settings for Sonarr, Radarr, Lidarr, Readarr:

```xml
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>Docker</UpdateMechanism>
  <Branch>main</Branch>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <SslPort>0</SslPort>
</Config>
```

## Network Configuration

### Internal Network

- Network Name: `media_network`
- All services communicate internally
- Only necessary ports exposed

### External Access

1. Domain Setup:

```env
DOMAIN=your.domain.com
```

2. SSL Configuration (optional):

```yaml
# traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your@email.com
      storage: acme.json
      httpChallenge:
        entryPoint: web
```

## Storage Configuration

### Directory Structure

```bash
storage/
├── MOVIES/
├── SERIES/
├── AUDIO/
├── BOOKS/
└── TORRENTS/
    ├── COMPLETE/
    │   ├── movies-radarr/
    │   ├── tv-sonarr/
    │   ├── music-lidarr/
    │   └── books-readarr/
    └── INCOMPLETE/
```

### Permissions

```bash
# Set correct permissions
chmod -R 755 config/
chmod -R 755 storage/
chown -R $USER:$USER config/ storage/
```

## Backup Configuration

### Backup Locations

- Configurations: `backups/`
- Created by: `./captainarr.sh backup`
- Naming: `backup_YYYYMMDD_HHMMSS.tar.gz`

### Backup Settings

```bash
# Included in backups:
- Service configurations
- API keys
- Custom scripts
- User settings

# Excluded:
- Media files
- Download files
- Temporary data
```

## Advanced Configuration

### Custom Scripts

Location: `config/scripts/`

```bash
# Example: Post-processing script
#!/bin/bash
# custom-script.sh
# Add your custom logic here
```

### Resource Limits

In `docker-compose.yml`:

```yaml
services:
  plex:
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: 4G
```

### Notification Setup

```env
# Notification Options:
- Discord
- Telegram
- Email
- Slack
- Custom webhook

# Example Discord setup:
NOTIFICATION_URL=discord://webhook-url
```

## Security Configuration

### Authentication

```yaml
# Basic Auth Example
traefik:
  labels:
    - "traefik.http.middlewares.auth.basicauth.users=user:$$apr1$$xyz..."
```

### API Keys

Generated automatically for:

- Sonarr
- Radarr
- Lidarr
- Readarr
- Prowlarr

### Network Security

```yaml
# Restrict external access
services:
  service-name:
    networks:
      - media_network
    expose:
      - "internal_port"
```

## Monitoring Configuration

### Health Checks

```yaml
# Docker health checks
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:port"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Logging

```yaml
# Docker logging
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## Troubleshooting Configuration

### Debug Mode

```env
# Enable debug logging
LOG_LEVEL=debug
```

### Service Logs

```bash
# View specific service logs
./captainarr.sh logs service-name

# View all logs
./captainarr.sh logs
```

Remember to restart services after configuration changes:

```bash
./captainarr.sh restart
```