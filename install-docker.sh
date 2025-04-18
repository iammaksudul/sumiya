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
    else
        error "Cannot detect OS"
        exit 1
    fi
}

# Install Docker on AlmaLinux/CentOS
install_docker_rhel() {
    log "Installing Docker on RHEL-based system..."
    
    # Install required packages
    dnf install -y dnf-utils device-mapper-persistent-data lvm2 || {
        error "Failed to install required packages"
        exit 1
    }
    
    # Add Docker repository
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || {
        error "Failed to add Docker repository"
        exit 1
    }
    
    # Install Docker
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || {
        error "Failed to install Docker"
        exit 1
    }
}

# Install Docker on Ubuntu/Debian
install_docker_debian() {
    log "Installing Docker on Debian-based system..."
    
    # Install required packages
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || {
        error "Failed to install required packages"
        exit 1
    }
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || {
        error "Failed to add Docker's GPG key"
        exit 1
    }
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null || {
        error "Failed to add Docker repository"
        exit 1
    }
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || {
        error "Failed to install Docker"
        exit 1
    }
}

# Start and enable Docker service
start_docker() {
    log "Starting Docker service..."
    
    if command_exists systemctl; then
        systemctl start docker
        systemctl enable docker
    elif command_exists service; then
        service docker start
        update-rc.d docker defaults
    fi
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    
    # Download Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || {
        error "Failed to download Docker Compose"
        exit 1
    }
    
    # Make it executable
    chmod +x /usr/local/bin/docker-compose || {
        error "Failed to make Docker Compose executable"
        exit 1
    }
}

# Main installation process
main() {
    log "Starting Docker installation..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
    
    # Detect OS
    detect_os
    log "Detected OS: $OS"
    
    # Install Docker based on OS
    if [[ "$OS" == *"AlmaLinux"* ]] || [[ "$OS" == *"CentOS"* ]]; then
        install_docker_rhel
    elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        install_docker_debian
    else
        error "Unsupported operating system"
        exit 1
    fi
    
    # Start Docker service
    start_docker
    
    # Install Docker Compose
    install_docker_compose
    
    success "Docker installation completed successfully!"
    log "Docker version: $(docker --version)"
    log "Docker Compose version: $(docker-compose --version)"
}

# Run main function
main 