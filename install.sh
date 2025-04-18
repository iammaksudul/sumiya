#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to log messages
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to log success
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to log warnings
warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed
package_installed() {
    if command_exists dnf; then
        dnf list installed "$1" &>/dev/null
    elif command_exists yum; then
        yum list installed "$1" &>/dev/null
    elif command_exists apt; then
        dpkg -l "$1" &>/dev/null
    fi
}

# Function to install a package
install_package() {
    local package=$1
    log "Installing $package..."
    
    if command_exists dnf; then
        dnf install -y "$package" || {
            error "Failed to install $package with dnf"
            return 1
        }
    elif command_exists yum; then
        yum install -y "$package" || {
            error "Failed to install $package with yum"
            return 1
        }
    elif command_exists apt; then
        apt-get update && apt-get install -y "$package" || {
            error "Failed to install $package with apt"
            return 1
        }
    else
        error "No package manager found"
        return 1
    fi
    
    success "Successfully installed $package"
    return 0
}

# Function to install a package with multiple fallback methods
install_package_with_fallback() {
    local package=$1
    local fallback_packages=$2
    log "Installing $package with fallback options..."
    
    # Try primary package name
    if install_package "$package"; then
        return 0
    fi
    
    # Try fallback package names
    for fallback in $fallback_packages; do
        log "Trying fallback package: $fallback"
        if install_package "$fallback"; then
            return 0
        fi
    done
    
    # Try installing from source if all package managers fail
    if [ "$package" = "python3.9" ] || [ "$package" = "python39" ]; then
        log "Attempting to install Python 3.9 from source..."
        install_python_from_source
        return $?
    fi
    
    error "Failed to install $package with all fallback methods"
    return 1
}

# Function to detect OS
detect_os() {
    log "Detecting operating system..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
        VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat"
        VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\).*/\1/')
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
    
    log "Detected OS: $OS $VERSION"
    
    # Set package manager based on OS
    if command_exists dnf; then
        PKG_MANAGER="dnf"
    elif command_exists yum; then
        PKG_MANAGER="yum"
    elif command_exists apt; then
        PKG_MANAGER="apt"
    else
        warning "No supported package manager found"
        PKG_MANAGER="unknown"
    fi
    
    log "Using package manager: $PKG_MANAGER"
    
    # Set service manager based on OS
    if command_exists systemctl; then
        SERVICE_MANAGER="systemctl"
    elif command_exists service; then
        SERVICE_MANAGER="service"
    else
        warning "No supported service manager found"
        SERVICE_MANAGER="unknown"
    fi
    
    log "Using service manager: $SERVICE_MANAGER"
    
    success "OS detection completed"
}

# Function to get IPv4 address
get_ipv4() {
    log "Detecting IPv4 address..."
    
    # Try different methods to get IPv4
    if command_exists ip; then
        IPV4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n 1)
    elif command_exists ifconfig; then
        IPV4=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
    elif command_exists hostname; then
        IPV4=$(hostname -I | awk '{print $1}')
    else
        warning "Could not detect IPv4 address, using localhost"
        IPV4="127.0.0.1"
    fi
    
    # If still no IPv4, try external service
    if [ -z "$IPV4" ] || [ "$IPV4" = "127.0.0.1" ]; then
        if command_exists curl; then
            IPV4=$(curl -s https://api.ipify.org)
        elif command_exists wget; then
            IPV4=$(wget -qO- https://api.ipify.org)
        fi
    fi
    
    # If still no IPv4, use localhost
    if [ -z "$IPV4" ]; then
        warning "Could not detect IPv4 address, using localhost"
        IPV4="127.0.0.1"
    fi
    
    log "Detected IPv4: $IPV4"
    success "IPv4 detection completed"
}

# Function to install Python from source
install_python_from_source() {
    log "Installing Python 3.9 from source..."
    
    # Install build dependencies
    install_package_with_fallback "gcc" "gcc-c++"
    install_package_with_fallback "make" "make"
    install_package_with_fallback "zlib-devel" "zlib1g-dev"
    install_package_with_fallback "bzip2-devel" "libbz2-dev"
    install_package_with_fallback "openssl-devel" "libssl-dev"
    install_package_with_fallback "sqlite-devel" "libsqlite3-dev"
    install_package_with_fallback "readline-devel" "libreadline-dev"
    install_package_with_fallback "tk-devel" "python3-tk"
    install_package_with_fallback "gdbm-devel" "libgdbm-dev"
    install_package_with_fallback "libffi-devel" "libffi-dev"
    install_package_with_fallback "libnsl2-devel" "libnsl-dev"
    install_package_with_fallback "libexpat1-devel" "libexpat1-dev"
    
    # Download and compile Python 3.9
    cd /tmp
    wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz
    tar -xf Python-3.9.18.tgz
    cd Python-3.9.18
    ./configure --enable-optimizations
    make -j $(nproc)
    make altinstall
    
    # Create symlinks
    ln -sf /usr/local/bin/python3.9 /usr/bin/python3.9
    ln -sf /usr/local/bin/pip3.9 /usr/bin/pip3.9
    
    # Verify installation
    if command_exists python3.9; then
        success "Python 3.9 installed from source"
        return 0
    else
        error "Failed to install Python 3.9 from source"
        return 1
    fi
}

# Function to check and fix Python version
check_python_version() {
    log "Checking Python version..."
    
    # Try to install Python 3.9 or higher
    if [ "$PKG_MANAGER" = "dnf" ]; then
        # Try module first
        dnf module reset python3
        dnf module enable python39
        install_package_with_fallback "python39" "python3.9 python39-module"
        
        # Try development packages
        install_package_with_fallback "python39-devel" "python3.9-devel python39-devel-module"
        
        # Try pip packages
        install_package_with_fallback "python39-pip" "python3.9-pip python39-pip-module"
    elif [ "$PKG_MANAGER" = "yum" ]; then
        install_package_with_fallback "python39" "python3.9"
        install_package_with_fallback "python39-devel" "python3.9-devel"
        install_package_with_fallback "python39-pip" "python3.9-pip"
    elif [ "$PKG_MANAGER" = "apt" ]; then
        install_package_with_fallback "python3.9" "python39"
        install_package_with_fallback "python3.9-dev" "python39-dev"
        install_package_with_fallback "python3.9-venv" "python39-venv"
        install_package_with_fallback "python3.9-distutils" "python39-distutils"
    fi
    
    # Verify Python 3.9 is installed
    if command_exists python3.9; then
        PYTHON_CMD="python3.9"
    elif command_exists python39; then
        PYTHON_CMD="python39"
    else
        error "Python 3.9 not found after installation"
        exit 1
    fi
    
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
    log "Using Python version: $PYTHON_VERSION"
    
    success "Python version check completed"
}

# Function to check and fix Python environment
check_python_env() {
    log "Checking Python environment..."
    
    # Check if Python is installed
    if ! command_exists $PYTHON_CMD; then
        warning "Python3.9 not found, installing..."
        check_python_version
    fi
    
    # Check if pip is installed
    if ! command_exists pip3; then
        warning "pip3 not found, installing..."
        install_package python3-pip || {
            error "Failed to install pip3"
            exit 1
        }
    fi
    
    # Check if venv module is available
    if ! $PYTHON_CMD -c "import venv" 2>/dev/null; then
        warning "venv module not found, installing..."
        install_package python3-venv || {
            error "Failed to install python3-venv"
            exit 1
        }
    fi
    
    success "Python environment check completed"
}

# Function to check and fix Python dependencies
check_dependencies() {
    log "Checking Python dependencies..."
    
    # Check if virtual environment exists
    if [ ! -d "/opt/sumiya/venv" ]; then
        warning "Virtual environment does not exist, creating..."
        cd /opt/sumiya
        $PYTHON_CMD -m venv venv || {
            error "Failed to create virtual environment"
            exit 1
        }
    fi
    
    # Activate virtual environment
    source /opt/sumiya/venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip || {
        warning "Failed to upgrade pip, continuing anyway..."
    }
    
    # Install dependencies
    log "Installing Python dependencies..."
    pip install -r /opt/sumiya/requirements.txt || {
        error "Failed to install Python dependencies"
        exit 1
    }
    
    success "Dependencies check completed"
}

# Function to fix Python module conflicts
fix_python_conflicts() {
    log "Fixing Python module conflicts..."
    
    # Remove conflicting packages
    pip uninstall -y fastapi uvicorn || true
    
    # Install specific versions
    pip install "fastapi>=0.104.1,<0.105.0" "uvicorn>=0.24.0,<0.25.0" || {
        error "Failed to install FastAPI dependencies"
        exit 1
    }
    
    success "Python conflicts resolved"
}

# Function to check and fix database
check_database() {
    log "Checking database..."
    
    # Check if SQLite is installed
    if ! command_exists sqlite3; then
        warning "SQLite3 not found, installing..."
        install_package sqlite || {
            error "Failed to install SQLite3"
            exit 1
        }
    fi
    
    # Check if database file exists and is writable
    if [ -f "/opt/sumiya/sumiya.db" ]; then
        if [ ! -w "/opt/sumiya/sumiya.db" ]; then
            warning "Database file exists but is not writable, fixing permissions..."
            chmod 644 "/opt/sumiya/sumiya.db"
        fi
    else
        warning "Database file does not exist, will be created during initialization"
    fi
    
    success "Database check completed"
}

# Function to check and fix permissions
check_permissions() {
    log "Checking permissions..."
    
    # Check if application directory exists and is writable
    if [ -d "/opt/sumiya" ]; then
        if [ ! -w "/opt/sumiya" ]; then
            warning "Application directory exists but is not writable, fixing permissions..."
            chmod -R 755 "/opt/sumiya"
        fi
    else
        warning "Application directory does not exist, will be created"
    fi
    
    # Check if logs directory exists and is writable
    if [ -d "/opt/sumiya/logs" ]; then
        if [ ! -w "/opt/sumiya/logs" ]; then
            warning "Logs directory exists but is not writable, fixing permissions..."
            chmod -R 755 "/opt/sumiya/logs"
        fi
    else
        warning "Logs directory does not exist, will be created"
    fi
    
    success "Permissions check completed"
}

# Function to check and fix services
check_services() {
    log "Checking services..."
    
    # Check if Nginx is installed
    if ! command_exists nginx; then
        warning "Nginx not found, installing..."
        install_package nginx || {
            error "Failed to install Nginx"
            exit 1
        }
    fi
    
    # Check if Supervisor is installed
    if ! command_exists supervisord; then
        warning "Supervisor not found, installing..."
        install_package supervisor || {
            error "Failed to install Supervisor"
            exit 1
        }
    fi
    
    # Check if services are running
    if [ "$SERVICE_MANAGER" = "systemctl" ]; then
        if ! systemctl is-active --quiet nginx; then
            warning "Nginx is not running, starting..."
            systemctl start nginx || {
                error "Failed to start Nginx"
                exit 1
            }
        fi
        
        if ! systemctl is-active --quiet supervisord; then
            warning "Supervisor is not running, starting..."
            systemctl start supervisord || {
                error "Failed to start Supervisor"
                exit 1
            }
        fi
    elif [ "$SERVICE_MANAGER" = "service" ]; then
        if ! service nginx status >/dev/null 2>&1; then
            warning "Nginx is not running, starting..."
            service nginx start || {
                error "Failed to start Nginx"
                exit 1
            }
        fi
        
        if ! service supervisor status >/dev/null 2>&1; then
            warning "Supervisor is not running, starting..."
            service supervisor start || {
                error "Failed to start Supervisor"
                exit 1
            }
        fi
    else
        warning "Unsupported service manager, skipping service checks"
    fi
    
    success "Services check completed"
}

# Function to configure Nginx based on OS
configure_nginx() {
    log "Configuring Nginx..."
    
    # Determine Nginx config directory based on OS
    if [ -d "/etc/nginx/conf.d" ]; then
        NGINX_CONF_DIR="/etc/nginx/conf.d"
    elif [ -d "/etc/nginx/sites-available" ]; then
        NGINX_CONF_DIR="/etc/nginx/sites-available"
    else
        NGINX_CONF_DIR="/etc/nginx"
    fi
    
    # Create Nginx configuration
    cat > "$NGINX_CONF_DIR/sumiya.conf" << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    
    # If using sites-available, create symlink to sites-enabled
    if [ "$NGINX_CONF_DIR" = "/etc/nginx/sites-available" ]; then
        ln -sf /etc/nginx/sites-available/sumiya.conf /etc/nginx/sites-enabled/
    fi
    
    success "Nginx configuration completed"
}

# Function to configure Supervisor based on OS
configure_supervisor() {
    log "Configuring Supervisor..."
    
    # Determine Supervisor config directory based on OS
    if [ -d "/etc/supervisord.d" ]; then
        SUPERVISOR_CONF_DIR="/etc/supervisord.d"
    elif [ -d "/etc/supervisor/conf.d" ]; then
        SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"
    else
        SUPERVISOR_CONF_DIR="/etc"
    fi
    
    # Create Supervisor configuration
    cat > "$SUPERVISOR_CONF_DIR/sumiya.ini" << EOF
[program:sumiya]
command=/opt/sumiya/venv/bin/$PYTHON_CMD -m uvicorn app.main:app --host 0.0.0.0 --port 8000
directory=/opt/sumiya
user=root
autostart=true
autorestart=true
stdout_logfile=/opt/sumiya/logs/sumiya.out.log
stderr_logfile=/opt/sumiya/logs/sumiya.err.log
EOF
    
    success "Supervisor configuration completed"
}

# Function to start services based on OS
start_services() {
    log "Starting services..."
    
    if [ "$SERVICE_MANAGER" = "systemctl" ]; then
        systemctl enable nginx
        systemctl start nginx
        systemctl enable supervisord
        systemctl start supervisord
        supervisorctl reread
        supervisorctl update
        supervisorctl restart sumiya
    elif [ "$SERVICE_MANAGER" = "service" ]; then
        service nginx enable
        service nginx start
        service supervisor enable
        service supervisor start
        supervisorctl reread
        supervisorctl update
        supervisorctl restart sumiya
    else
        warning "Unsupported service manager, skipping service start"
    fi
    
    success "Services started"
}

# Function to check and fix firewall
check_firewall() {
    log "Checking firewall..."
    
    # Check if firewall is installed and running
    if command_exists firewall-cmd; then
        if firewall-cmd --state >/dev/null 2>&1; then
            warning "Firewall is running, adding HTTP port..."
            firewall-cmd --permanent --add-service=http || {
                warning "Failed to add HTTP service to firewall"
            }
            firewall-cmd --reload || {
                warning "Failed to reload firewall"
            }
        fi
    elif command_exists ufw; then
        if ufw status | grep -q "active"; then
            warning "UFW is running, allowing HTTP port..."
            ufw allow 80/tcp || {
                warning "Failed to allow HTTP port in UFW"
            }
        fi
    fi
    
    success "Firewall check completed"
}

# Function to check and fix SELinux
check_selinux() {
    log "Checking SELinux..."
    
    if command_exists sestatus; then
        if sestatus | grep -q "SELinux status:\s*enabled"; then
            warning "SELinux is enabled, setting context..."
            if command_exists semanage; then
                semanage port -a -t http_port_t -p tcp 8000 || {
                    warning "Failed to add port 8000 to SELinux"
                }
            fi
            setsebool -P httpd_can_network_connect 1 || {
                warning "Failed to set SELinux boolean"
            }
        fi
    fi
    
    success "SELinux check completed"
}

# Function to check and fix system resources
check_resources() {
    log "Checking system resources..."
    
    # Check available disk space
    DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}')
    log "Available disk space: $DISK_SPACE"
    
    # Check available memory
    if command_exists free; then
        MEMORY=$(free -h | awk '/Mem:/ {print $4}')
        log "Available memory: $MEMORY"
    fi
    
    # Check CPU cores
    if command_exists nproc; then
        CORES=$(nproc)
        log "Available CPU cores: $CORES"
    fi
    
    success "Resource check completed"
}

# Function to check and fix network connectivity
check_network() {
    log "Checking network connectivity..."
    
    # Check if we can reach the internet
    if command_exists ping; then
        if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            success "Internet connectivity: OK"
        else
            warning "No internet connectivity detected"
        fi
    fi
    
    # Check DNS resolution
    if command_exists nslookup; then
        if nslookup github.com >/dev/null 2>&1; then
            success "DNS resolution: OK"
        else
            warning "DNS resolution issues detected"
        fi
    fi
    
    success "Network check completed"
}

# Function to check and fix system time
check_system_time() {
    log "Checking system time..."
    
    # Check if NTP is installed
    if ! command_exists ntpdate; then
        warning "NTP not found, installing..."
        install_package ntpdate || {
            warning "Failed to install NTP, continuing anyway..."
        }
    fi
    
    # Try to sync time
    if command_exists ntpdate; then
        ntpdate pool.ntp.org || {
            warning "Failed to sync time with NTP server"
        }
    fi
    
    success "System time check completed"
}

# Main installation process
echo -e "${GREEN}Starting Sumiya AI DevOps Assistant installation...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
    exit 1
fi

# Detect OS
detect_os

# Get IPv4 address
get_ipv4

# Check system resources
check_resources

# Check network connectivity
check_network

# Check system time
check_system_time

# Check Python version
check_python_version

# Check and fix Python environment
check_python_env

# Install system dependencies
log "Installing system dependencies..."
if [ "$PKG_MANAGER" = "dnf" ]; then
    dnf update -y || {
        warning "Failed to update system packages, continuing anyway..."
    }
    dnf install -y epel-release || {
        warning "Failed to install EPEL repository, continuing anyway..."
    }
    
    # Install Python 3.9 and related packages
    check_python_version
    
    # Install other dependencies
    install_package_with_fallback "gcc" "gcc-c++"
    install_package_with_fallback "git" "git-core"
    install_package_with_fallback "nginx" "nginx-core"
    install_package_with_fallback "supervisor" "supervisord"
elif [ "$PKG_MANAGER" = "yum" ]; then
    yum update -y || {
        warning "Failed to update system packages, continuing anyway..."
    }
    yum install -y epel-release || {
        warning "Failed to install EPEL repository, continuing anyway..."
    }
    
    # Install Python 3.9 and related packages
    check_python_version
    
    # Install other dependencies
    install_package_with_fallback "gcc" "gcc-c++"
    install_package_with_fallback "git" "git-core"
    install_package_with_fallback "nginx" "nginx-core"
    install_package_with_fallback "supervisor" "supervisord"
elif [ "$PKG_MANAGER" = "apt" ]; then
    apt update -y || {
        warning "Failed to update system packages, continuing anyway..."
    }
    
    # Install Python 3.9 and related packages
    check_python_version
    
    # Install other dependencies
    install_package_with_fallback "gcc" "g++"
    install_package_with_fallback "git" "git-core"
    install_package_with_fallback "nginx" "nginx-core"
    install_package_with_fallback "supervisor" "supervisord"
else
    error "Unsupported package manager"
    exit 1
fi

# Create application directory
log "Creating application directory..."
mkdir -p /opt/sumiya
cd /opt/sumiya

# Clone repository
log "Cloning repository..."
git clone https://github.com/iammaksudul/sumiya.git . || {
    error "Failed to clone repository"
    exit 1
}

# Check and fix Python dependencies
check_dependencies

# Fix Python module conflicts
fix_python_conflicts

# Create necessary directories
log "Creating necessary directories..."
mkdir -p logs
mkdir -p app/static
mkdir -p app/templates

# Set up environment variables
log "Setting up environment variables..."
cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 32)
DATABASE_URL=sqlite:///./sumiya.db
EOF

# Configure Nginx
configure_nginx

# Configure Supervisor
configure_supervisor

# Check and fix database
check_database

# Check and fix permissions
check_permissions

# Set permissions
log "Setting permissions..."
chown -R root:root /opt/sumiya
chmod -R 755 /opt/sumiya

# Check and fix services
check_services

# Check and fix firewall
check_firewall

# Check and fix SELinux
check_selinux

# Start services
start_services

echo -e "${GREEN}====================================================="
echo -e "Sumiya AI DevOps Assistant has been successfully installed!"
echo -e "====================================================="
echo -e "You can access Sumiya at: http://${IPV4}"
echo -e "Default passkey: sinbad"
echo -e "====================================================="
echo -e "Created by: Kh Maksudul Alam (https://github.com/iammaksudul)"
echo -e "====================================================="
echo -e "If you encounter any issues, check the logs at:"
echo -e "/opt/sumiya/logs/sumiya.err.log"
echo -e "/opt/sumiya/logs/sumiya.out.log"
echo -e "=====================================================${NC}" 