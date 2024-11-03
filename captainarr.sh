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

# Version
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")

# Create logs directory if it doesn't exist
mkdir -p logs

# Error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    log "ERROR" "Error on line $line_number: Command failed with exit code $exit_code"
    exit $exit_code
}

# Logging function
log() {
    local level=$1
    shift
    local msg="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} ${timestamp} - $msg" | tee -a logs/captainarr.log
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $msg" | tee -a logs/captainarr.log
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $msg" | tee -a logs/captainarr.log
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $msg" | tee -a logs/captainarr.log
            ;;
    esac
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        if command -v systemctl >/dev/null 2>&1; then
            log "WARNING" "Docker daemon is not running. Attempting to start..."
            sudo systemctl start docker
            sleep 2
            if ! docker info >/dev/null 2>&1; then
                log "ERROR" "Failed to start Docker daemon"
                exit 1
            fi
            log "SUCCESS" "Docker daemon started successfully"
        else
            log "ERROR" "Docker daemon is not running and could not be started automatically"
            exit 1
        fi
    fi
}

# Function to check environment
check_environment() {
    if [ ! -f .env ]; then
        log "ERROR" ".env file not found. Please run ./init.sh first"
        exit 1
    fi
    set -a
    source .env
    set +a
    
    # Verify essential variables
    local required_vars=("CONFIG_ROOT" "STORAGE_ROOT")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log "ERROR" "Required variable $var is not set in .env"
            exit 1
        fi
    done
}

# Function to check initialized
check_initialized() {
    if [ ! -f VERSION ]; then
        log "ERROR" "System not initialized. Please run ./init.sh first"
        exit 1
    fi
}

# Function to check disk space
check_disk_space() {
    local warning_threshold=80
    local critical_threshold=90
    local disk_usage=$(df -h "$STORAGE_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$critical_threshold" ]; then
        log "ERROR" "Critical: Storage space is almost full ($disk_usage% used)"
        return 1
    elif [ "$disk_usage" -gt "$warning_threshold" ]; then
        log "WARNING" "Storage space is running low ($disk_usage% used)"
    else
        log "SUCCESS" "Storage space OK ($disk_usage% used)"
    fi
}

# Function to display ASCII art logo
show_logo() {
    cat << "EOF"
  ____              _        _        _             
 / ___|__ _ _ __ _| |_ __ _(_)_ __  / \   _ __ _ __ 
| |   / _` | '_ \__| __/ _` | | '_ \/ _ \ | '__| '__|
| |__| (_| | |_) | | || (_| | | | | / ___ \| |  | |
 \____\__,_| .__/|_|\__\__,_|_|_| |_/_/   \_\_|  |_|
           |_|                                        
EOF
    echo "Version: $VERSION"
    echo
}

# Function to display help
show_help() {
    show_logo
    echo "Usage: $0 COMMAND [OPTIONS]"
    echo
    echo "Commands:"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show status of all services"
    echo "  logs [svc]  - Show logs (optionally for specific service)"
    echo "  update      - Update all containers"
    echo "  backup      - Create backup of configurations"
    echo "  restore     - Restore from backup"
    echo "  shell [svc] - Open shell in container"
    echo "  check       - Run system health check"
    echo "  reset       - Reset all configurations"
    echo "  configure   - Open configuration menu"
    echo "  prune       - Remove unused Docker resources"
    echo "  help        - Show this help message"
    echo
}

# Function to check system health
check_health() {
    log "INFO" "Running system health check..."
    
    # Check disk space
    check_disk_space
    
    # Check container status
    local running_containers=$(docker-compose ps --filter "status=running" -q | wc -l)
    local total_containers=$(docker-compose ps -q | wc -l)
    
    if [ "$running_containers" -eq 0 ]; then
        log "WARNING" "No containers are running"
    elif [ "$running_containers" -ne "$total_containers" ]; then
        log "WARNING" "$running_containers of $total_containers containers are running"
    else
        log "SUCCESS" "All $total_containers containers are running"
    fi

    # Check network connectivity
    if ! docker network inspect media_network >/dev/null 2>&1; then
        log "WARNING" "Docker network not found, attempting to create..."
        if ! docker network create media_network >/dev/null 2>&1; then
            log "ERROR" "Failed to create Docker network"
        fi
    else
        log "SUCCESS" "Docker network OK"
    fi

    # Check configurations
    local required_configs=(
        "plex" "sonarr" "radarr" "lidarr" "readarr" "prowlarr" 
        "overseerr" "bazarr" "qbittorrent"
    )
    local missing_configs=0
    
    for service in "${required_configs[@]}"; do
        if [ ! -d "$CONFIG_ROOT/$service" ]; then
            log "ERROR" "Missing configuration for $service"
            ((missing_configs++))
        fi
    done

    if [ $missing_configs -eq 0 ]; then
        log "SUCCESS" "All service configurations present"
    fi

    # Check ports
    local required_ports=(
        "$TRAEFIK_PORT" "$PORTAINER_PORT" "$PORTAINER_EDGE_PORT"
    )
    
    for port in "${required_ports[@]}"; do
        if nc -z localhost "$port" 2>/dev/null; then
            log "WARNING" "Port $port is already in use"
        fi
    done
}

# Function to create backup
create_backup() {
    mkdir -p backups
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_file="backups/backup_${backup_date}.tar.gz"
    
    log "INFO" "Creating backup..."
    
    # Stop services before backup
    log "INFO" "Stopping services for backup..."
    docker-compose down
    
    if ! tar -czf "$backup_file" -C "$CONFIG_ROOT" .; then
        log "ERROR" "Backup creation failed"
        log "INFO" "Restarting services..."
        docker-compose up -d
        return 1
    fi
    
    # Restart services
    log "INFO" "Restarting services..."
    docker-compose up -d
    
    log "SUCCESS" "Backup created: $backup_file"
}

# Function to restore backup
restore_backup() {
    if [ -z "${1:-}" ]; then
        log "ERROR" "Please specify backup file"
        echo "Available backups:"
        ls -1 backups/*.tar.gz 2>/dev/null || echo "No backups found"
        return 1
    fi

    if [ ! -f "$1" ]; then
        log "ERROR" "Backup file not found: $1"
        return 1
    fi

    log "WARNING" "This will overwrite current configurations"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Operation cancelled"
        return 0
    fi

    log "INFO" "Stopping services..."
    docker-compose down

    # Create backup of current config
    local pre_restore_backup="backups/pre_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
    log "INFO" "Creating backup of current configuration..."
    if ! tar -czf "$pre_restore_backup" -C "$CONFIG_ROOT" .; then
        log "WARNING" "Failed to backup current configuration"
    fi

    log "INFO" "Restoring backup..."
    rm -rf "$CONFIG_ROOT"/*
    if ! tar -xzf "$1" -C "$CONFIG_ROOT"; then
        log "ERROR" "Restore failed"
        log "INFO" "Attempting to restore previous configuration..."
        tar -xzf "$pre_restore_backup" -C "$CONFIG_ROOT"
        return 1
    fi

    log "SUCCESS" "Backup restored"
    log "INFO" "Starting services..."
    docker-compose up -d
}

# Main execution
check_initialized
check_environment

case "$1" in
    start)
        check_docker
        log "INFO" "Starting services..."
        docker-compose up -d
        log "SUCCESS" "Services started"
        ./captainarr.sh status
        ;;
    stop)
        check_docker
        log "INFO" "Stopping services..."
        docker-compose down
        log "SUCCESS" "Services stopped"
        ;;
    restart)
        check_docker
        log "INFO" "Restarting services..."
        docker-compose restart
        log "SUCCESS" "Services restarted"
        ./captainarr.sh status
        ;;
    status)
        check_docker
        echo "Container Status:"
        docker-compose ps
        ;;
    logs)
        check_docker
        if [ -z "${2:-}" ]; then
            docker-compose logs --tail=100 -f
        else
            if ! docker-compose ps -q "$2" >/dev/null 2>&1; then
                log "ERROR" "Service $2 not found"
                exit 1
            fi
            docker-compose logs --tail=100 -f "$2"
        fi
        ;;
    update)
        check_docker
        log "INFO" "Creating backup before update..."
        create_backup
        
        log "INFO" "Updating containers..."
        docker-compose pull
        docker-compose up -d
        
        log "INFO" "Cleaning up old images..."
        docker image prune -f
        
        log "SUCCESS" "Update complete"
        ;;
    backup)
        create_backup
        ;;
    restore)
        restore_backup "${2:-}"
        ;;
    shell)
        check_docker
        if [ -z "${2:-}" ]; then
            log "ERROR" "Please specify container name"
            docker-compose ps --services
            exit 1
        fi
        if ! docker-compose ps -q "$2" >/dev/null 2>&1; then
            log "ERROR" "Service $2 not found"
            exit 1
        fi
        docker-compose exec "$2" /bin/bash || docker-compose exec "$2" /bin/sh
        ;;
    check)
        check_health
        ;;
    reset)
        ./reset.sh
        ;;
    configure)
        if command -v nano >/dev/null 2>&1; then
            nano .env
        else
            vi .env
        fi
        ;;
    prune)
        log "INFO" "Cleaning up unused Docker resources..."
        docker system prune -f
        log "SUCCESS" "Cleanup complete"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac