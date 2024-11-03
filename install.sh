#!/bin/bash

# First, handle command line arguments
USE_DEFAULTS=false
for arg in "$@"; do
    case $arg in
        --defaults)
            USE_DEFAULTS=true
            shift
            ;;
        *)
            log "RED" "Unknown argument: $1"
            exit 1
            ;;
    esac
done

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check if running in Docker container
in_container() {
    if [ -f /.dockerenv ]; then
        return 0
    fi
    return 1
}

# Logging function
log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${!level}[${level}]${NC} ${timestamp} - $msg" | tee -a logs/install.log
}

# Function to print login information
print_login_info() {
    echo -e "\n${GREEN}=== Default Login Information ===${NC}"
    echo -e "${BLUE}Arr Services (Radarr/Sonarr/etc):${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: admin"
    echo -e "\n${BLUE}qBitTorrent:${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: adminadmin"
    echo -e "\n${BLUE}Homarr:${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: Admin123!"
    echo -e "\n${BLUE}Calibre:${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: admin123"
    echo -e "\n${YELLOW}IMPORTANT: Please change these default passwords immediately!${NC}\n"
}

# Error handling
set -euo pipefail
trap 'log "RED" "Error on line $LINENO: Command failed with exit code $?"' ERR

# Create logs directory
mkdir -p logs

# Check for root
if [ "$EUID" -eq 0 ]; then
    log "RED" "Please do not run as root"
    exit 1
fi

log "BLUE" "Starting CaptainArr installation..."

# Check system requirements
if in_container; then
    log "RED" "This script cannot be run inside a Docker container"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    log "YELLOW" "Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    DOCKER_GROUP_ADDED=1
    log "YELLOW" "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Check Docker version
DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
log "BLUE" "Docker version: $DOCKER_VERSION"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log "YELLOW" "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Check Docker Compose version
COMPOSE_VERSION=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
log "BLUE" "Docker Compose version: $COMPOSE_VERSION"

# Make scripts executable
log "BLUE" "Making scripts executable..."
chmod +x captainarr.sh init.sh reset.sh generate-configs.sh

# Check for required files
check_required_files() {
    local missing_files=false
    
    if [ ! -f "captainarr.sh" ]; then
        log "RED" "Missing captainarr.sh"
        missing_files=true
    fi
    if [ ! -f "init.sh" ]; then
        log "RED" "Missing init.sh"
        missing_files=true
    fi
    if [ ! -f "reset.sh" ]; then
        log "RED" "Missing reset.sh"
        missing_files=true
    fi
    if [ ! -f "generate-configs.sh" ]; then
        log "RED" "Missing generate-configs.sh"
        missing_files=true
    fi
    
    if [ "$missing_files" = true ]; then
        log "RED" "Required files are missing. Please ensure all required files are present."
        exit 1
    fi
}

check_required_files

if [ "$USE_DEFAULTS" = true ]; then
    # Check if __defaults__ folder exists
    if [ ! -d "__defaults__" ]; then
        log "RED" "Error: __defaults__ folder not found!"
        exit 1
    fi

    log "BLUE" "Using default configuration..."
    
    # Create backup of existing files if they exist
    if [ -f ".env" ] || [ -d "configs" ] || [ -d "storage" ]; then
        backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
        log "YELLOW" "Creating backup of existing files in $backup_dir"
        mkdir -p "$backup_dir"
        [ -f ".env" ] && cp .env "$backup_dir/"
        [ -d "configs" ] && cp -r configs "$backup_dir/"
        [ -d "storage" ] && cp -r storage "$backup_dir/"
    fi
    
    # Copy files from __defaults__ folder
    log "BLUE" "Copying default configuration..."
    cp -rf __defaults__/* .
    
    # Remove any macOS-specific files if they exist
    find . -name ".DS_Store" -delete
    
    # Print login information
    print_login_info
    
    # Print next steps
    echo -e "\n${GREEN}=== Next Steps ===${NC}"
    echo -e "1. Edit the .env file to set your Plex claim token:"
    echo -e "   Get your token from: ${BLUE}https://www.plex.tv/claim${NC}"
    echo -e "   Then edit the .env file:"
    echo -e "   ${YELLOW}nano .env${NC}"
    echo -e "\n2. After setting your Plex claim token, start the services with:"
    echo -e "   ${YELLOW}./captainarr.sh start${NC}"
    echo -e "\n3. If you want to use a different storage location:"
    echo -e "   a. Copy the entire folder structure to your desired location:"
    echo -e "      ${YELLOW}cp -r . /path/to/new/location${NC}"
    echo -e "   b. Create a symbolic link to the new location:"
    echo -e "      ${YELLOW}ln -s /path/to/new/location/storage ./storage${NC}"
    
else
    # Regular installation flow
    # Source the environment variables
    if [ ! -f ".env" ]; then
        log "RED" "Error: .env file not found!"
        exit 1
    fi
    source .env

    # Initialize
    log "BLUE" "Running initialization..."
    ./init.sh

    # Generate configurations
    log "BLUE" "Generating configurations..."
    ./generate-configs.sh

    # Start services
    log "BLUE" "Starting services..."
    ./captainarr.sh start

    # Check if services are running
    sleep 5
    if ! docker-compose ps | grep -q "Up"; then
        log "RED" "Warning: Some services failed to start. Check the logs for more information."
        exit 1
    fi

    log "GREEN" "Installation complete!"
    log "BLUE" "Access your services at http://localhost:${TRAEFIK_PORT}${BASE_PATH:-}"
    log "BLUE" "Run './captainarr.sh help' for available commands"
fi

# If Docker group was just added, remind user to log out
if [ -n "${DOCKER_GROUP_ADDED:-}" ]; then
    log "YELLOW" "Remember to log out and back in for Docker group changes to take effect."
fi