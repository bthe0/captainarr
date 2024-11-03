# Installation Guide

## Prerequisites

### System Requirements

- Operating System: Linux/macOS
- Minimum RAM: 4GB (8GB+ recommended)
- Storage:
  - 10GB for Docker images and configs
  - Sufficient space for media (500GB+ recommended)
- Processor: x86_64 with 2+ cores
- Internet connection

### Required Software

- Git
- Docker
- Docker Compose
- curl
- bash

### Port Requirements

- Port 80 (Traefik)
- Additional ports based on external access needs

## Pre-Installation Steps

1. **Install Docker** (if not installed)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh
# Log out and back in for group changes to take effect
```

2. **Install Docker Compose** (if not installed)

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

3. **Prepare Directory Structure**

```bash
# Create base directory
mkdir -p ~/mediaserver
cd ~/mediaserver

# Create media directories
mkdir -p {config,storage}/{MOVIES,SERIES,AUDIO,BOOKS,TORRENTS/COMPLETE,TORRENTS/INCOMPLETE}
```

## Installation

1. **Clone Repository**

```bash
git clone https://github.com/bthe0/captainarr.git .
```

2. **Configure Environment**

```bash
cp .env.example .env
nano .env
```

Required `.env` configurations:

```bash
# System Settings
TZ=Your/Timezone  # e.g., America/New_York

# Paths Configuration
CONFIG_ROOT=./config
STORAGE_ROOT=/absolute/path/to/storage

# Domain Settings
DOMAIN=localhost  # or your domain

# Plex Configuration
PLEX_CLAIM=claim-xxxxxxxx  # from plex.tv/claim !important
```

3. **Run Installation**

```bash
chmod +x install.sh
./install.sh
```

4. **Verify Installation**

```bash
./captainarr.sh status
```

## Post-Installation

1. **Check Service Access**

```bash
./captainarr.sh check
```

2. **View Logs**

```bash
./captainarr.sh logs
```

3. **Create Initial Backup**

```bash
./captainarr.sh backup
```

## Directory Structure

After installation, your directory structure should look like this:

```
mediaserver/
├── config/
│   ├── plex/
│   ├── sonarr/
│   ├── radarr/
│   └── ...
├── storage/
│   ├── MOVIES/
│   ├── SERIES/
│   ├── AUDIO/
│   ├── BOOKS/
│   └── TORRENTS/
│       ├── COMPLETE/
│       └── INCOMPLETE/
├── .env
├── docker-compose.yml
├── install.sh
└── captainarr.sh
```

## Network Configuration

### Basic Setup (localhost)

No additional configuration needed.

### External Access

1. Forward port 80 to your server
2. Configure domain DNS if using a custom domain
3. Update `.env` with your domain

## Next Steps

1. Follow the [Post-Installation Guide](post-install.md)
2. Configure [Security Settings](security.md)
3. Set up [Automatic Updates](maintenance.md)

## Troubleshooting Installation

### Common Issues

1. **Docker Permission Issues**

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

2. **Port Conflicts**

```bash
# Check for port usage
sudo lsof -i :80
# Modify TRAEFIK_PORT in .env if needed
```

3. **Storage Permission Issues**

```bash
# Fix permissions
sudo chown -R $USER:$USER config/
sudo chown -R $USER:$USER storage/
```

### Installation Logs

- Check `logs/install.log` for detailed installation logs
- Use `./captainarr.sh logs` for service-specific logs

## Updating Installation

To update all containers:

```bash
./captainarr.sh update
```

## Uninstalling

To completely remove the installation:

```bash
./captainarr.sh stop
docker-compose down -v
rm -rf config/ storage/ .env
```

⚠️ Warning: This will delete all configuration and data. Back up first!
