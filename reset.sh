# File: reset.sh
#!/bin/bash

# Enable error handling
set -euo pipefail
trap 'log "RED" "Error on line $LINENO: Command failed with exit code $?"' ERR

# Source environment variables
source .env

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${!level}[${level}]${NC} ${timestamp} - $msg" | tee -a logs/reset.log
}

confirm_reset() {
    log "RED" "WARNING: This will delete all configuration data!"
    log "YELLOW" "Media files in STORAGE_ROOT will not be touched."
    read -p "Are you sure you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "BLUE" "Operation cancelled."
        exit 0
    fi
}

# Create logs directory if it doesn't exist
mkdir -p logs

confirm_reset

log "BLUE" "Stopping all containers..."
docker-compose down

log "BLUE" "Removing docker network..."
docker network rm media_network 2>/dev/null || true

log "BLUE" "Creating backup of current configuration..."
backup_date=$(date +%Y%m%d_%H%M%S)
mkdir -p backups
tar -czf "backups/config_backup_${backup_date}.tar.gz" "$CONFIG_ROOT" 2>/dev/null || true

log "BLUE" "Removing configuration directories..."
rm -rf "${CONFIG_ROOT:?}"/*

log "BLUE" "Creating fresh directory structure..."
./init.sh

log "GREEN" "Reset complete!"
log "BLUE" "Your original configuration has been backed up to: backups/config_backup_${backup_date}.tar.gz"
log "BLUE" "Run './captainarr.sh start' to start fresh"