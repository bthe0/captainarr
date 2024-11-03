#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Exit on any error
set -e

# Create logs directory
mkdir -p logs

# Logging function
log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${!level}[${level}]${NC} ${timestamp} - $msg" >&2 | tee -a logs/config-gen.log
}

# Function to safely create directory
create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "BLUE" "Created directory: $dir" >&2
    fi
}

# Function to safely create file with content
create_file() {
    local file="$1"
    local content="$2"
    create_dir "$(dirname "$file")" >&2
    echo "$content" > "$file"
    log "BLUE" "Created file: $file" >&2
}

# Function to update env file
update_env_var() {
    local key=$1
    local value=$2
    local env_file=".env"

    if [ ! -f "$env_file" ]; then
        echo "${key}=${value}" > "$env_file"
        return
    fi

    local temp_file="${env_file}.tmp"
    : > "$temp_file"

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ $line =~ ^$key= ]]; then
            echo "${key}=${value}" >> "$temp_file"
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$env_file"

    mv "$temp_file" "$env_file"
}

generate_calibre_config() {
    create_dir "$CONFIG_ROOT/calibre"
    
    # Check if source metadata.db exists
    if [ -f "./misc/metadata.db" ]; then
        cp "./misc/metadata.db" "$CONFIG_ROOT/calibre/metadata.db"
        log "BLUE" "Copied Calibre metadata database"
    else
        log "YELLOW" "Warning: metadata.db not found in ./misc directory"
    fi
}

generate_qbittorrent_categories() {
    local categories_json="$CONFIG_ROOT/qbittorrent/qBittorrent/categories.json"
    create_file "$categories_json" "$(cat << EOF
{
    "${QB_CATEGORY_TV}": {
        "save_path": "${DOWNLOADS_PATH}/complete/${QB_CATEGORY_TV}"
    },
    "${QB_CATEGORY_MOVIES}": {
        "save_path": "${DOWNLOADS_PATH}/complete/${QB_CATEGORY_MOVIES}"
    },
    "${QB_CATEGORY_MUSIC}": {
        "save_path": "${DOWNLOADS_PATH}/complete/${QB_CATEGORY_MUSIC}"
    },
    "${QB_CATEGORY_BOOKS}": {
        "save_path": "${DOWNLOADS_PATH}/complete/${QB_CATEGORY_BOOKS}"
    }
}
EOF
)"
}

generate_qbittorrent_config() {
    create_dir "$CONFIG_ROOT/qbittorrent/qBittorrent"
    create_file "$CONFIG_ROOT/qbittorrent/qBittorrent/qBittorrent.conf" "$(cat << EOF
[AutoRun]
enabled=true
program=unzip "%F" -d "%D"

[BitTorrent]
Session\DefaultSavePath=${DOWNLOADS_PATH}/complete
Session\TempPath=${DOWNLOADS_PATH}/incomplete
Session\Port=6881
Session\MaxRatioAction=0
Session\GlobalMaxRatio=1.0
Session\GlobalMaxSeedingMinutes=-1
Session\MaxRatioAction=PauseIfSeedingTimeReached
Session\GlobalMaxInactiveSeedingTime=0
Session\MaxInactiveSeedingTime=0
Session\ShareLimitAction=0

[Preferences]
WebUI\Port=8080
WebUI\Username=admin
WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"
WebUI\Address=*
WebUI\ServerDomains=*
WebUI\UseUPnP=false
WebUI\RootFolder=${BASE_PATH:-}/qbittorrent
Connection\UPnP=false
Downloads\SavePath=${DOWNLOADS_PATH}/complete
Downloads\TempPath=${DOWNLOADS_PATH}/incomplete
Downloads\PreAllocation=true
Downloads\UseIncompleteExtension=true
Queueing\QueueingEnabled=false

[LegalNotice]
Accepted=true

[General]
Configuration\Backup\DeleteOld=false
EOF
)"

generate_qbittorrent_categories
}

generate_arr_base_config() {
    local service=$1
    local port=$2
    local api_key=$(openssl rand -hex 32)
    
    create_dir "$CONFIG_ROOT/$service"
    create_file "$CONFIG_ROOT/$service/config.xml" "$(cat << EOF
<?xml version="1.0" encoding="utf-8"?>
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>Docker</UpdateMechanism>
  <UrlBase>${BASE_PATH:-}/${service}</UrlBase>
  <Branch>main</Branch>
  <Port>${port}</Port>
  <BindAddress>*</BindAddress>
  <ApiKey>${api_key}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <AnalyticsEnabled>False</AnalyticsEnabled>
  <SslPort>0</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
</Config>
EOF
)"
    printf "%s" "$api_key"  # Use printf to avoid newline
}

generate_arr_configs() {
    local service=$1
    local port=$2
    local category=$3
    local root_folder=$4
    
    create_dir "$CONFIG_ROOT/$service/config"
    local api_key
    api_key=$(generate_arr_base_config "$service" "$port")
    
    create_file "$CONFIG_ROOT/$service/config/mediamanagement.json" "$(cat << EOF
{
  "autoUnmonitorPreviouslyDownloadedEpisodes": false,
  "recycleBin": "",
  "recycleBinCleanupDays": 7,
  "downloadPropersAndRepacks": "preferAndUpgrade",
  "createEmptySeriesFolders": false,
  "deleteEmptyFolders": true,
  "fileDate": "none",
  "rescanAfterRefresh": "always",
  "setPermissionsLinux": true,
  "chmodFolder": "755",
  "skipFreeSpaceCheckWhenImporting": false,
  "minimumFreeSpaceWhenImporting": 100,
  "copyUsingHardlinks": true,
  "importExtraFiles": true,
  "extraFileExtensions": "srt,sub,idx,nfo",
  "enableMediaInfo": true,
  "defaultRootFolderPath": "${root_folder}"
}
EOF
)"

    create_file "$CONFIG_ROOT/$service/config/downloadclient.json" "$(cat << EOF
{
  "downloadClientConfigs": [
    {
      "enable": true,
      "protocol": "torrent",
      "priority": 1,
      "name": "qBittorrent",
      "implementation": "QBittorrent",
      "configContract": "QBittorrentSettings",
      "host": "qbittorrent",
      "port": 8080,
      "username": "admin",
      "password": "adminadmin",
      "category": "${category}",
      "removeCompletedDownloads": ${DELETE_AFTER_SEED},
      "removeFailedDownloads": true
    }
  ]
}
EOF
)"
    printf "%s" "$api_key"  # Use printf to avoid newline
}

generate_traefik_config() {
    create_file "$CONFIG_ROOT/traefik/traefik.yml" "$(cat << EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    
providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    watch: true
    network: media_network

log:
  level: "DEBUG"

accessLog: {}
EOF
)"
    create_file "$CONFIG_ROOT/traefik/acme.json" ""
    chmod 600 "$CONFIG_ROOT/traefik/acme.json"
}

generate_deleterr_config() {
    create_file "$CONFIG_ROOT/deleterr/settings.yaml" "$(cat << EOF
plex:
  url: "http://plex:32400"
  token: "${PLEX_CLAIM}"

radarr:
  - name: "Radarr"
    url: "http://radarr:7878"
    api_key: "${RADARR_API_KEY}"

sonarr:
  - name: "Sonarr"
    url: "http://sonarr:8989"
    api_key: "${SONARR_API_KEY}"

dry_run: true
plex_library_scan_after_actions: false
tautulli_library_scan_after_actions: false
action_delay: 25

libraries:
  - name: "Movies"
    radarr: "Radarr"
    action_mode: "delete"
    add_list_exclusion_on_delete: True
    last_watched_threshold: 30
    watch_status: watched
    apply_last_watch_threshold_to_collections: true
    added_at_threshold: 90
    max_actions_per_run: 10
    disk_size_threshold:
      - path: "${MOVIES_PATH}"
        threshold: 1TB
      - path: "${DOWNLOADS_PATH}/complete/movies-radarr"
        threshold: 1TB
    sort:
      field: release_year
      order: asc
    exclude:
      titles: []
      tags: ["favorite"]
      genres: []
      collections: []
      actors: []
      producers: []
      directors: []
      writers: []
      studios: []
      release_years: 5

  - name: "TV Shows"
    action_mode: delete
    last_watched_threshold: 365
    added_at_threshold: 180
    apply_last_watch_threshold_to_collections: false
    max_actions_per_run: 10
    disk_size_threshold:
      - path: "${MOVIES_PATH}"
        threshold: 1TB
      - path: "${DOWNLOADS_PATH}/complete/movies-radarr"
        threshold: 1TB
    sonarr: Sonarr
    series_type: standard
    sort:
      field: seasons
      order: desc
    exclude:
      titles: []
      tags: []
      genres: []
      collections: []
      actors: []
      producers: []
      directors: []
      writers: []
      studios: []
      release_years: 2
EOF
)"
}

generate_recyclarr_config() {
    create_file "$CONFIG_ROOT/recyclarr/recyclarr.yml" "$(cat << EOF
# Recyclarr Configuration File
# Get Trash IDs from: https://trash-guides.info/
# - Movies (Radarr): https://trash-guides.info/Radarr/
# - Series (Sonarr): https://trash-guides.info/Sonarr/
# - Music (Lidarr): https://trash-guides.info/Lidarr/
# - Books (Readarr): https://trash-guides.info/Readarr/

# Sonarr Configuration
sonarr:
  - base_url: http://sonarr:8989
    api_key: ${SONARR_API_KEY}
    delete_old_custom_formats: true
    replace_existing_custom_formats: true
    quality_definition:
      type: series
      preferred_ratio: 0.5
    quality_profiles:
      - name: HD-1080p
        reset_unmatched_scores: true
        upgrade_until_quality: Bluray-1080p
        min_score: 0
        qualities:
          - name: Bluray-1080p
            score: 200
          - name: WEB 1080p
            score: 180
          - name: HDTV-1080p
            score: 90
    custom_formats:
      # Language Formats
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100
      # Audio Formats
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100
      # HDR Formats
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100

# Radarr Configuration
radarr:
  - base_url: http://radarr:7878
    api_key: ${RADARR_API_KEY}
    delete_old_custom_formats: true
    replace_existing_custom_formats: true
    quality_definition:
      type: movie
      preferred_ratio: 0.5
    quality_profiles:
      - name: HD-1080p
        reset_unmatched_scores: true
        upgrade_until_quality: Bluray-1080p
        min_score: 0
        qualities:
          - name: Bluray-1080p
            score: 200
          - name: WEB 1080p
            score: 180
          - name: HDTV-1080p
            score: 90
    custom_formats:
      # Movie Versions
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100
      # Audio Formats
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100
      # HDR Formats
      - trash_ids: []
        quality_profiles:
          - name: HD-1080p
            score: 100

# Lidarr Configuration
lidarr:
  - base_url: http://lidarr:8686
    api_key: ${LIDARR_API_KEY}
    delete_old_custom_formats: true
    replace_existing_custom_formats: true
    quality_definition:
      type: music
      preferred_ratio: 0.5
    quality_profiles:
      - name: Music-Standard
        reset_unmatched_scores: true
        qualities:
          - name: FLAC
            score: 200
          - name: MP3
            score: 100
    custom_formats:
      # Audio Quality
      - trash_ids: []
        quality_profiles:
          - name: Music-Standard
            score: 100
      # Release Types
      - trash_ids: []
        quality_profiles:
          - name: Music-Standard
            score: 100

# Readarr Configuration
readarr:
  - base_url: http://readarr:8787
    api_key: ${READARR_API_KEY}
    delete_old_custom_formats: true
    replace_existing_custom_formats: true
    quality_definition:
      type: book
      preferred_ratio: 0.5
    quality_profiles:
      - name: Ebook-Standard
        reset_unmatched_scores: true
        qualities:
          - name: EPUB
            score: 200
          - name: PDF
            score: 100
    custom_formats:
      # Book Formats
      - trash_ids: []
        quality_profiles:
          - name: Ebook-Standard
            score: 100
      # Release Types
      - trash_ids: []
        quality_profiles:
          - name: Ebook-Standard
            score: 100

# Schedule Configuration
schedule:
  - name: sync-hourly
    schedule: "0 * * * *"  # Every hour
    custom_formats: true
    quality_profiles: true
    quality_definitions: true
    delete_old_custom_formats: true
EOF
)"
}

generate_other_configs() {
    create_dir "$CONFIG_ROOT/deleterr"
    create_dir "$CONFIG_ROOT/deleterr/logs"
    create_dir "$CONFIG_ROOT/plex/transcode"
    log "BLUE" "Created Deleterr directories and logs folder"
    generate_deleterr_config
    generate_recyclarr_config
    generate_calibre_config
    log "BLUE" "Generated Recyclarr configuration"
}

# Main script execution
if [ ! -f .env ]; then
    log "RED" "Environment file .env not found!"
    exit 1
fi

source .env

log "BLUE" "Creating required directories..."
create_dir "$CONFIG_ROOT"
create_dir "$STORAGE_ROOT"

log "BLUE" "Generating configurations..."

# Generate configurations and store API keys using command substitution with proper output handling
SONARR_API_KEY=$(generate_arr_configs "sonarr" "8989" "${QB_CATEGORY_TV}" "${SERIES_PATH}")
log "BLUE" "Generated Sonarr API key"

RADARR_API_KEY=$(generate_arr_configs "radarr" "7878" "${QB_CATEGORY_MOVIES}" "${MOVIES_PATH}")
log "BLUE" "Generated Radarr API key"

LIDARR_API_KEY=$(generate_arr_configs "lidarr" "8686" "${QB_CATEGORY_MUSIC}" "${MUSIC_PATH}")
log "BLUE" "Generated Lidarr API key"

READARR_API_KEY=$(generate_arr_configs "readarr" "8787" "${QB_CATEGORY_BOOKS}" "${BOOKS_PATH}")
log "BLUE" "Generated Readarr API key"

PROWLARR_API_KEY=$(generate_arr_base_config "prowlarr" "9696")
log "BLUE" "Generated Prowlarr API key"

# Generate other configurations
generate_qbittorrent_config
generate_traefik_config
generate_other_configs

# Update API keys in .env
log "BLUE" "Updating API keys in .env file..."
update_env_var "SONARR_API_KEY" "$SONARR_API_KEY"
update_env_var "RADARR_API_KEY" "$RADARR_API_KEY"
update_env_var "LIDARR_API_KEY" "$LIDARR_API_KEY"
update_env_var "READARR_API_KEY" "$READARR_API_KEY"
update_env_var "PROWLARR_API_KEY" "$PROWLARR_API_KEY"

log "GREEN" "Configuration generation complete!"