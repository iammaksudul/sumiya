#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        error "Cannot detect OS"
        exit 1
    fi

    # Set package manager
    if command_exists dnf; then
        PKG_MANAGER="dnf"
    elif command_exists yum; then
        PKG_MANAGER="yum"
    elif command_exists apt; then
        PKG_MANAGER="apt"
    else
        error "No supported package manager found"
        exit 1
    fi
}

# Install Python with fallback methods
install_python() {
    log "Installing Python 3.9..."
    
    case $PKG_MANAGER in
        dnf)
            # Try EPEL repository first
            dnf install -y epel-release || {
                warning "Failed to install EPEL, trying alternative method..."
                dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm || true
            }
            
            # Try module first
            dnf module reset python3 || true
            dnf module enable python39 || true
            
            # Try multiple package names
            for pkg in python39 python3.9 python39-module; do
                dnf install -y $pkg && break
            done
            
            # Try development packages
            for pkg in python39-devel python3.9-devel python39-devel-module; do
                dnf install -y $pkg && break
            done
            ;;
            
        yum)
            # Try EPEL repository
            yum install -y epel-release || {
                warning "Failed to install EPEL, trying alternative method..."
                yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true
            }
            
            # Try multiple package names
            for pkg in python39 python3.9; do
                yum install -y $pkg && break
            done
            
            # Try development packages
            for pkg in python39-devel python3.9-devel; do
                yum install -y $pkg && break
            done
            ;;
            
        apt)
            # Add deadsnakes PPA
            add-apt-repository -y ppa:deadsnakes/ppa || {
                warning "Failed to add deadsnakes PPA, trying alternative method..."
                apt-get install -y software-properties-common
                add-apt-repository -y ppa:deadsnakes/ppa || true
            }
            
            apt-get update
            
            # Try multiple package names
            for pkg in python3.9 python39; do
                apt-get install -y $pkg && break
            done
            
            # Try development packages
            for pkg in python3.9-dev python39-dev; do
                apt-get install -y $pkg && break
            done
            ;;
    esac
    
    # Verify Python installation
    if command_exists python3.9; then
        PYTHON_CMD="python3.9"
    elif command_exists python39; then
        PYTHON_CMD="python39"
    else
        error "Failed to install Python 3.9"
        exit 1
    fi
}

# Install pip with fallback methods
install_pip() {
    log "Installing pip..."
    
    if ! command_exists pip3; then
        case $PKG_MANAGER in
            dnf|yum)
                $PKG_MANAGER install -y python3-pip || {
                    warning "Failed to install pip via package manager, trying alternative method..."
                    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                    $PYTHON_CMD get-pip.py
                    rm get-pip.py
                }
                ;;
            apt)
                apt-get install -y python3-pip || {
                    warning "Failed to install pip via package manager, trying alternative method..."
                    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                    $PYTHON_CMD get-pip.py
                    rm get-pip.py
                }
                ;;
        esac
    fi
}

# Create and activate virtual environment
setup_venv() {
    log "Setting up virtual environment..."
    
    # Install venv if not available
    if ! $PYTHON_CMD -c "import venv" 2>/dev/null; then
        case $PKG_MANAGER in
            dnf|yum)
                $PKG_MANAGER install -y python3-venv
                ;;
            apt)
                apt-get install -y python3.9-venv
                ;;
        esac
    fi
    
    # Create venv
    $PYTHON_CMD -m venv venv || {
        error "Failed to create virtual environment"
        exit 1
    }
    
    # Activate venv
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
}

# Install Python dependencies with fallback methods
install_dependencies() {
    log "Installing Python dependencies..."
    
    # Try installing from requirements.txt first
    pip install -r requirements.txt || {
        warning "Failed to install from requirements.txt, trying individual packages..."
        
        # Install core dependencies first
        pip install fastapi uvicorn python-jose[cryptography] passlib[bcrypt] python-multipart || {
            error "Failed to install core dependencies"
            exit 1
        }
        
        # Install database dependencies
        pip install sqlalchemy psycopg2-binary || {
            warning "Failed to install database dependencies, falling back to SQLite..."
            pip install sqlalchemy
        }
        
        # Install AI dependencies
        pip install transformers torch sentencepiece accelerate || {
            warning "Failed to install AI dependencies, some features may be limited..."
        }
        
        # Install remaining dependencies
        pip install pydantic pydantic-settings python-dotenv jinja2 aiofiles || true
    }
}

# Setup environment file
setup_env() {
    log "Setting up environment file..."
    
    # Generate random secret key
    SECRET_KEY=$(openssl rand -hex 32)
    
    # Create .env file
    cat > .env << EOF
# Security
SECRET_KEY=$SECRET_KEY
DEFAULT_PASSKEY=sinbad

# Database
DATABASE_URL=sqlite:///./sumiya.db

# Server
HOST=0.0.0.0
PORT=8000

# AI Model
AI_MODEL_NAME=facebook/opt-350m
AI_MODEL_CACHE_DIR=./model_cache

# Logging
LOG_LEVEL=INFO
LOG_FILE=sumiya.log

# CORS
CORS_ORIGINS=http://localhost:8000,http://127.0.0.1:8000,http://195.201.21.145:8000,http://195.201.21.145
EOF
}

# Start the application
start_app() {
    log "Starting the application..."
    
    # Create necessary directories
    mkdir -p logs model_cache
    
    # Start the application
    nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > logs/sumiya.log 2>&1 &
    
    # Wait for the application to start
    for i in {1..30}; do
        if curl -s http://localhost:8000 > /dev/null; then
            success "Application started successfully!"
            break
        fi
        sleep 1
    done
}

# Main installation process
main() {
    log "Starting Sumiya AI DevOps Assistant installation..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
        exit 1
    fi
    
    # Detect OS
    detect_os
    log "Detected OS: $OS $VERSION"
    log "Using package manager: $PKG_MANAGER"
    
    # Install Python
    install_python
    
    # Install pip
    install_pip
    
    # Setup virtual environment
    setup_venv
    
    # Install dependencies
    install_dependencies
    
    # Setup environment
    setup_env
    
    # Start the application
    start_app
    
    success "Installation completed successfully!"
    log "You can access Sumiya at: http://195.201.21.145:8000"
    log "Default passkey: sinbad"
    log "Logs are available at: logs/sumiya.log"
}

# Run main function
main 