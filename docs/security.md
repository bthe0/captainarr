# Security Guide

## Authentication

### Default Credentials

| Service        | Username | Default Password    | Change Method   |
| -------------- | -------- | ------------------- | --------------- |
| qBittorrent    | admin    | adminadmin          | WebUI Settings  |
| Portainer      | N/A      | Set on first launch | First Login     |
| Other Services | N/A      | No default auth     | Settings > Auth |

### Setting Up Authentication

#### Media Managers (Sonarr/Radarr/Lidarr/Readarr)

1. Navigate to Settings > General
2. Enable Authentication
3. Select Authentication Method
4. Set username and password
5. Save and restart service

#### Traefik Basic Auth

```yaml
# Generate hash: htpasswd -nb user password
labels:
  - "traefik.http.middlewares.auth.basicauth.users=user:$$apr1$$xyz..."
```

## Network Security

### Docker Network Isolation

```yaml
networks:
  media_network:
    name: media_network
    driver: bridge
```

### Port Exposure

- Only expose necessary ports
- Use internal Docker network when possible
- Configure host firewall

### HTTPS Configuration

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

## API Security

### API Key Management

- Generate strong API keys
- Rotate keys regularly
- Use encrypted communication
- Limit API access scope

### Secure Communication

```yaml
# Example secure service configuration
services:
  service-name:
    environment:
      - API_KEY=${SERVICE_API_KEY}
    labels:
      - "traefik.http.routers.service.middlewares=secure@file"
```

## File Permissions

### Container Permissions

```bash
# Set correct permissions
chmod -R 755 config/
chmod -R 755 storage/
chown -R $USER:$USER config/ storage/
```

### Media File Access

```yaml
# Read-only where possible
volumes:
  - ${STORAGE_ROOT}/MOVIES:${MOVIES_PATH}:ro
```

## Security Best Practices

### General Guidelines

1. Change default passwords
2. Enable authentication
3. Use HTTPS
4. Regular updates
5. Monitor logs
6. Backup configurations
7. Limit access scope

### Container Security

```yaml
security_opt:
  - no-new-privileges:true
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE
```

### Update Security

```yaml
# Watchtower configuration
environment:
  - WATCHTOWER_NOTIFICATIONS=true
  - WATCHTOWER_NOTIFICATION_URL=${NOTIFICATION_URL}
```

## Monitoring & Logging

### Log Management

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Security Monitoring

```bash
# View security-related logs
./captainarr.sh logs | grep -i "error\|warning\|failed"
```

## Backup Security

### Secure Backups

```bash
# Encrypted backup
tar czf - config/ | gpg -c > backup.tar.gz.gpg
```

### Backup Storage

- Store backups securely
- Encrypt sensitive data
- Regular backup testing
- Off-site backup copies

## Remote Access Security

### VPN Configuration

- Use VPN for remote access
- Configure split tunneling
- Implement kill switch
- Regular connection monitoring

### Reverse Proxy Security

```yaml
# Additional security headers
headers:
  FrameDeny: true
  BrowserXssFilter: true
  ContentTypeNosniff: true
  ReferrerPolicy: "same-origin"
  HSTSPreload: true
```

## Recovery Procedures

### Security Breach Response

1. Isolate affected services
2. Reset credentials
3. Review logs
4. Restore from clean backup
5. Document incident
6. Implement preventive measures

### Emergency Shutdown

```bash
# Immediate shutdown
./captainarr.sh stop
docker-compose down
```

Remember to regularly review and update security measures based on best practices and emerging threats.
