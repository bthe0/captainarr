#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Enable error handling
set -euo pipefail
trap 'handle_error $? $LINENO' ERR

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN";;
esac

# Error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    log "ERROR" "Error on line $line_number: Command failed with exit code $exit_code"
    exit $exit_code
}

# Create logs directory if it doesn't exist
mkdir -p logs

# Logging function
log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} ${timestamp} - $msg" | tee -a logs/init.log
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $msg" | tee -a logs/init.log
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $msg" | tee -a logs/init.log
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $msg" | tee -a logs/init.log
            ;;
    esac
}

# Function to safely create directory and handle errors
create_dir_safe() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            log "ERROR" "Failed to create directory: $dir"
            return 1
        }
        log "SUCCESS" "Created directory: $dir"
    fi
}

# Function to check and set permissions
check_and_set_permissions() {
    local dir=$1
    local user=${2:-$(id -un)}
    local group=${3:-$(id -gn)}
    
    create_dir_safe "$dir" || return 1

    if [ "$MACHINE" = "Mac" ]; then
        if ! chown "$user":"$group" "$dir" 2>/dev/null; then
            log "WARNING" "Permission issues detected on macOS"
            log "INFO" "You may need to grant Full Disk Access to Terminal in System Preferences"
            log "INFO" "System Preferences > Security & Privacy > Privacy > Full Disk Access"
            return 0
        fi
    else
        if ! chown "$user":"$group" "$dir" 2>/dev/null; then
            log "WARNING" "Attempting to set permissions with sudo for: $dir"
            if ! sudo chown "$user":"$group" "$dir"; then
                log "ERROR" "Failed to set ownership for: $dir"
                return 1
            fi
        fi
    fi
    
    if [ "$MACHINE" = "Mac" ]; then
        chmod 755 "$dir" 2>/dev/null || true
    else
        if ! chmod 755 "$dir" 2>/dev/null; then
            if ! sudo chmod 755 "$dir"; then
                log "ERROR" "Failed to set mode for: $dir"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Function to check disk space
check_disk_space() {
    local dir=$1
    local min_space_gb=10
    
    create_dir_safe "$dir" || return 1
    
    if [ "$MACHINE" = "Mac" ]; then
        local available_space_kb=$(df -k "$dir" | awk 'NR==2 {print $4}')
    else
        local available_space_kb=$(df -P "$dir" | awk 'NR==2 {print $4}')
    fi
    local available_space_gb=$((available_space_kb / 1024 / 1024))
    
    if [ "$available_space_gb" -lt "$min_space_gb" ]; then
        log "ERROR" "Insufficient disk space. Required: ${min_space_gb}GB, Available: ${available_space_gb}GB"
        return 1
    fi
    
    log "INFO" "Available space in $dir: ${available_space_gb}GB"
    return 0
}

# Function to check and validate environment variables
check_env_variables() {
    local required_vars=(
        "CONFIG_ROOT"
        "STORAGE_ROOT"
        "TZ"
    )

    local missing_vars=0
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log "ERROR" "$var is not set in .env file"
            missing_vars=1
        fi
    done

    if [ $missing_vars -eq 1 ]; then
        return 1
    fi
}

# Function to check Docker installation
check_docker_installation() {
    log "INFO" "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed. Please install Docker first."
        if [ "$MACHINE" = "Mac" ]; then
            log "INFO" "Visit https://docs.docker.com/desktop/mac/install/ to install Docker Desktop for Mac"
        else
            log "INFO" "You can install Docker using: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
        fi
        return 1
    fi

    docker_version=$(docker --version | awk '{print $3}' | cut -d'.' -f1)
    if [ "$docker_version" -lt "20" ]; then
        log "WARNING" "Docker version is older than recommended. Please consider upgrading."
    fi

    if ! command -v docker-compose &> /dev/null; then
        log "ERROR" "Docker Compose is not installed. Please install Docker Compose first."
        if [ "$MACHINE" = "Mac" ]; then
            log "INFO" "Docker Compose comes with Docker Desktop for Mac"
        else
            log "INFO" "You can install Docker Compose using your package manager or manually"
        fi
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        if command -v systemctl >/dev/null 2>&1; then
            log "WARNING" "Docker daemon is not running. Attempting to start..."
            sudo systemctl start docker
            sleep 2
            if ! docker info >/dev/null 2>&1; then
                log "ERROR" "Failed to start Docker daemon"
                return 1
            fi
        else
            log "ERROR" "Docker daemon is not running and could not be started automatically"
            return 1
        fi
    fi

    return 0
}

if [ "$EUID" -eq 0 ]; then
    log "ERROR" "Please do not run this script as root"
    exit 1
fi

if [ -f .env ]; then
    source .env
else
    if [ ! -f .env.example ]; then
        log "ERROR" ".env.example file not found!"
        exit 1
    fi
    log "INFO" "Creating .env file from example..."
    cp .env.example .env
    log "WARNING" "Please edit .env file with your settings"
    exit 1
fi

source .env

check_env_variables || exit 1

check_docker_installation || exit 1

if [ "$MACHINE" = "Linux" ]; then
    if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
        log "WARNING" "Current user is not in the docker group. Adding user to docker group..."
        if ! sudo usermod -aG docker $USER; then
            log "ERROR" "Failed to add user to docker group"
            exit 1
        fi
        log "WARNING" "Please log out and back in for docker group changes to take effect"
    fi
fi

log "INFO" "Creating base directories..."
create_dir_safe "$CONFIG_ROOT" || exit 1
create_dir_safe "$STORAGE_ROOT" || exit 1

log "INFO" "Checking available disk space..."
check_disk_space "$STORAGE_ROOT" || exit 1

log "INFO" "Creating directory structure..."

directories=(
    "$CONFIG_ROOT"
    "$CONFIG_ROOT/plex"
    "$CONFIG_ROOT/sonarr"
    "$CONFIG_ROOT/radarr"
    "$CONFIG_ROOT/lidarr"
    "$CONFIG_ROOT/readarr"
    "$CONFIG_ROOT/prowlarr"
    "$CONFIG_ROOT/overseerr"
    "$CONFIG_ROOT/bazarr"
    "$CONFIG_ROOT/qbittorrent"
    "$CONFIG_ROOT/homarr"
    "$CONFIG_ROOT/deleterr"
    "$CONFIG_ROOT/organizr"
    "$CONFIG_ROOT/recyclarr"
    "$CONFIG_ROOT/traefik"
    "$STORAGE_ROOT"
    "$STORAGE_ROOT/TORRENTS/COMPLETE"
    "$STORAGE_ROOT/TORRENTS/INCOMPLETE"
    "$STORAGE_ROOT/MOVIES"
    "$STORAGE_ROOT/SERIES"
    "$STORAGE_ROOT/BOOKS"
    "$STORAGE_ROOT/AUDIO"
)

for dir in "${directories[@]}"; do
    if ! check_and_set_permissions "$dir"; then
        if [ "$MACHINE" = "Mac" ]; then
            log "WARNING" "Continuing despite permission issues with $dir"
        else
            log "ERROR" "Failed to set permissions for $dir"
            exit 1
        fi
    fi
done

echo "1.0.0" > VERSION
chmod 644 VERSION

log "INFO" "Checking network connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    log "WARNING" "Network connectivity issues detected"
fi

log "INFO" "Running final checks..."

log "INFO" "Generating configurations..."
if [ -f ./generate-configs.sh ]; then
    chmod +x ./generate-configs.sh
    ./generate-configs.sh
else
    log "WARNING" "generate-configs.sh not found, skipping configuration generation"
fi

log "SUCCESS" "Initialization complete!"
log "INFO" "You can now run './captainarr.sh start' to start the services"

if [ "$MACHINE" = "Mac" ]; then
    log "INFO" "macOS detected: If you experience permission issues, grant Full Disk Access to Terminal"
    log "INFO" "System Preferences > Security & Privacy > Privacy > Full Disk Access"
else
    log "INFO" "Linux detected: Make sure your user has appropriate permissions"
    if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
        log "WARNING" "Remember to log out and back in for docker group changes to take effect"
    fi
fi