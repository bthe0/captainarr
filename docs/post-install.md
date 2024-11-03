# Post-Installation Setup Guide

This guide will walk you through the complete setup of your media server stack after running `./install.sh`.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Media Server Configuration](#media-server-configuration)
- [Indexer Setup](#indexer-setup)
- [Download Client Configuration](#download-client-configuration)
- [Media Management Setup](#media-management-setup)
- [Subtitle Management](#subtitle-management)
- [Request Management](#request-management)
- [System Integration](#system-integration)

## Initial Setup

1. **Verify Installation**

```bash
./captainarr.sh status
```

Ensure all containers are running properly.

2. **Access Traefik Dashboard**

- Visit `http://localhost/dashboard/`
- Verify all services are properly registered

## Media Server Configuration

### Plex Setup

1. Access Plex:
   - !!note: Make sure you have set the claim in .env file from https://plex.tv/claim before everything else!!
   - Visit `http://plex.<domain>/web`
   - Sign in with your Plex account

2. Configure Libraries:

   - Add Movie Library:

     - Name: "Movies"
     - Type: Movies
     - Path: `/movies`
     - Enable auto-update

   - Add TV Library:

     - Name: "TV Shows"
     - Type: TV Shows
     - Path: `/tv`
     - Enable auto-update

   - Add Music Library:
     - Name: "Music"
     - Type: Music
     - Path: `/music`
     - Enable auto-update

3. Configure Settings:
   - Enable Remote Access
   - Set up library scanning preferences
   - Configure transcoding settings

## Indexer Setup

### Prowlarr Configuration

1. Access Prowlarr:

   - Visit `http://prowlarr.<domain>`
   - Set up authentication

2. Add Indexers:

   - Go to Settings > Indexers
   - Add your preferred indexers
   - Configure each indexer's settings

3. Configure Applications:

   - Go to Settings > Apps
   - Add Sonarr:

     - Name: Sonarr
     - Sync Level: Full Sync
     - URL: `http://sonarr:8989`
     - API Key: [From Sonarr]

   - Repeat for Radarr, Lidarr, and Readarr

## Download Client Configuration

### qBittorrent Setup

1. Access qBittorrent:

   - Visit `http://qbittorrent.<domain>`
   - Login with default credentials:
     - Username: `admin`
     - Password: `adminadmin`

2. Change default password:

   - Tools > Options > Web UI
   - Set new password

3. Configure Download Settings:

   - Tools > Options > Downloads
   - Default Save Path: `/downloads/complete`
   - Keep incomplete torrents in: `/downloads/incomplete`
   - Run external program on torrent completion: Enable

4. Configure Categories:
   - Create categories matching your \*arr services:
     - tv-sonarr
     - movies-radarr
     - music-lidarr
     - books-readarr

## Media Management Setup

### Sonarr Configuration

1. Access Sonarr:

   - Visit `http://sonarr.<domain>`
   - Set up authentication

2. Configure Download Client:

   - Settings > Download Clients > Add
   - Select qBittorrent
   - Host: qbittorrent
   - Port: 8080
   - Category: tv-sonarr
   - Test and save

3. Configure Media Management:

   - Settings > Media Management
   - Enable "Rename Episodes"
   - Configure naming scheme
   - Set up quality profiles

4. Add Root Folder:
   - Settings > Media Management
   - Add Root Folder: `/tv`

### Radarr Configuration

1. Access Radarr:

   - Visit `http://radarr.<domain>`
   - Set up authentication

2. Configure similarly to Sonarr:
   - Download client category: movies-radarr
   - Root folder: `/movies`
   - Configure quality profiles

### Lidarr Configuration

1. Access Lidarr:

   - Visit `http://lidarr.<domain>`
   - Set up authentication

2. Configure similarly to Sonarr:
   - Download client category: music-lidarr
   - Root folder: `/music`
   - Configure quality profiles

### Readarr Configuration

1. Access Readarr:

   - Visit `http://readarr.<domain>`
   - Set up authentication

2. Configure similarly to Sonarr:
   - Download client category: books-readarr
   - Root folder: `/books`
   - Configure quality profiles

## Subtitle Management

### Bazarr Setup

1. Access Bazarr:

   - Visit `http://bazarr.<domain>`
   - Set up authentication

2. Configure Providers:

   - Settings > Providers
   - Add and configure subtitle providers

3. Connect to Media Servers:

   - Settings > Sonarr
   - Settings > Radarr
   - Add credentials and test connection

4. Configure Languages:
   - Settings > Language
   - Set default languages
   - Configure subtitle preferences

## Request Management

### Overseerr Setup

1. Access Overseerr:

   - Visit `http://overseerr.<domain>`
   - Sign in with Plex

2. Configure Media Servers:

   - Settings > Plex
   - Connect to your Plex server

3. Configure \*arr Integration:

   - Settings > Services
   - Add Radarr and Sonarr
   - Configure default settings

4. Set Up Request Rules:
   - Settings > Users
   - Configure request limits
   - Set up approval rules

## System Integration

### Homarr Dashboard

1. Access Homarr:

   - Visit `http://homarr.<domain>`

2. Add Services:
   - Add all configured services
   - Configure widgets
   - Set up monitoring

### Organizr Setup (Optional)

1. Access Organizr:

   - Visit `http://organizr.<domain>`
   - Complete initial setup

2. Add Services:
   - Configure tabs for each service
   - Set up access levels
   - Customize theme

## Verify Integration

1. **Test Download Flow**

   - Add a movie/show in Radarr/Sonarr
   - Verify it's picked up by qBittorrent
   - Confirm proper categorization
   - Check final media placement

2. **Test Plex Integration**

   - Verify media appears in Plex
   - Test playback
   - Check metadata fetching

3. **Test Request System**
   - Make test request in Overseerr
   - Verify it appears in Radarr/Sonarr
   - Confirm notification system

## Final Steps

1. **Security Check**

   - Verify all passwords changed
   - Confirm authentication enabled
   - Test external access if needed

2. **Backup Configuration**

```bash
./captainarr.sh backup
```

3. **Monitor Logs**

```bash
./captainarr.sh logs
```

Your media server stack should now be fully configured and ready to use!
