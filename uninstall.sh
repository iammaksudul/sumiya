#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        error "Cannot detect OS"
        exit 1
    fi
}

# Stop services
stop_services() {
    log "Stopping services..."
    
    # Stop systemd service if exists
    if [ -f /etc/systemd/system/sumiya.service ]; then
        systemctl stop sumiya.service
        systemctl disable sumiya.service
        rm /etc/systemd/system/sumiya.service
        systemctl daemon-reload
    fi
    
    # Stop nginx if exists
    if command_exists nginx; then
        if [ -f /etc/nginx/conf.d/sumiya.conf ]; then
            rm /etc/nginx/conf.d/sumiya.conf
            nginx -s reload
        fi
    fi
    
    # Stop the application if running
    if pgrep -f "uvicorn app.main:app" > /dev/null; then
        pkill -f "uvicorn app.main:app"
    fi
}

# Remove configuration files
remove_config_files() {
    log "Removing configuration files..."
    
    # Remove systemd service file
    rm -f /etc/systemd/system/sumiya.service
    
    # Remove nginx configuration
    rm -f /etc/nginx/conf.d/sumiya.conf
    
    # Remove environment file
    rm -f .env
    
    # Remove log file
    rm -f sumiya.log
}

# Cleanup Python environment
cleanup_python() {
    log "Cleaning up Python environment..."
    
    # Deactivate virtual environment if active
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
    fi
    
    # Remove virtual environment
    rm -rf venv
    
    # Remove Python cache files
    find . -type d -name "__pycache__" -exec rm -r {} +
    find . -type f -name "*.pyc" -delete
    
    # Remove database file
    rm -f sumiya.db
    
    # Remove model cache
    rm -rf model_cache
}

# Cleanup system packages
cleanup_system_packages() {
    log "Cleaning up system packages..."
    
    case $OS in
        "AlmaLinux"|"CentOS Linux")
            dnf remove -y python39 python39-devel python3-pip || true
            ;;
        "Ubuntu")
            apt-get remove -y python3.9 python3.9-dev python3-pip || true
            ;;
    esac
}

# Main uninstallation process
main() {
    log "Starting uninstallation process..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
    
    # Detect OS
    detect_os
    log "Detected OS: $OS $VERSION"
    
    # Stop services
    stop_services
    
    # Remove configuration files
    remove_config_files
    
    # Cleanup Python environment
    cleanup_python
    
    # Cleanup system packages
    cleanup_system_packages
    
    success "Uninstallation completed successfully!"
}

# Run main function
main 