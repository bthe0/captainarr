#!/bin/bash

# First, source the environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    exit 1
fi
source .env

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Now enable error handling after sourcing .env
set -euo pipefail
trap 'log "RED" "Error on line $LINENO: Command failed with exit code $?"' ERR

log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${!level}[${level}]${NC} ${timestamp} - $msg" | tee -a logs/install.log
}

# Create logs directory
mkdir -p logs

# Check for root
if [ "$EUID" -eq 0 ]; then
    log "RED" "Please do not run as root"
    exit 1
fi

log "BLUE" "Starting CaptainArr installation..."

# Check Docker
if ! command -v docker &> /dev/null; then
    log "YELLOW" "Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log "YELLOW" "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Make scripts executable
chmod +x captainarr.sh init.sh reset.sh generate-configs.sh

# Initialize
log "BLUE" "Running initialization..."
./init.sh

# Generate configurations
log "BLUE" "Generating configurations..."
./generate-configs.sh

# Start services
log "BLUE" "Starting services..."
./captainarr.sh start

log "GREEN" "Installation complete!"
log "BLUE" "Access your services at http://localhost:${TRAEFIK_PORT}${BASE_PATH:-}"
log "BLUE" "Run './captainarr.sh help' for available commands"