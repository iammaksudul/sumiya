# Sumiya - AI DevOps Assistant

Sumiya is an AI-powered DevOps assistant that helps automate and streamline your development operations. It provides intelligent assistance for common DevOps tasks, code analysis, and deployment automation.

## Features

- 🤖 AI-powered command generation and task automation
- 🔒 Secure passkey authentication
- 🌐 Cross-platform compatibility
- 🚀 Easy deployment with Docker support
- 📊 Real-time system monitoring
- 🔄 Automatic issue detection and resolution
- 🛠️ Comprehensive installation and uninstallation scripts

## System Requirements

- Python 3.9 or higher
- 2GB RAM minimum (4GB recommended)
- 20GB disk space
- Internet connection for AI model downloads
- Docker (optional, for containerized deployment)

## Supported Operating Systems

- AlmaLinux 8+
- CentOS 7+
- Ubuntu 20.04+
- Debian 10+

## Installation

### Option 1: Standard Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/sumiya.git
cd sumiya
```

2. Run the installation script:
```bash
sudo ./install.sh
```

The script will:
- Detect your operating system
- Install required dependencies
- Set up Python environment
- Configure services
- Start the application

### Option 2: Docker Installation

1. Install Docker and Docker Compose:
```bash
sudo ./install-docker.sh
```

2. Build and start the containers:
```bash
docker-compose up -d
```

3. Access the application:
```
http://your-server-ip:8000
```

## Configuration

### Environment Variables

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` to configure:
- `SECRET_KEY`: Application secret key
- `DEFAULT_PASSKEY`: Default authentication passkey
- `DATABASE_URL`: Database connection string
- `AI_MODEL_NAME`: AI model to use
- `CORS_ORIGINS`: Allowed CORS origins

### Docker Configuration

Edit `docker-compose.yml` to customize:
- Port mappings
- Volume mounts
- Environment variables
- Resource limits

## Usage

1. Access the web interface:
```
http://your-server-ip:8000
```

2. Login with the default passkey:
```
Default passkey: sinbad
```

3. Start using the AI assistant for:
- Command generation
- Code analysis
- Deployment automation
- System monitoring

## Uninstallation

### Standard Installation

Run the uninstallation script:
```bash
sudo ./uninstall.sh
```

### Docker Installation

Stop and remove containers:
```bash
docker-compose down -v
```

## Troubleshooting

### Common Issues

1. Python Version Issues
```bash
# Check Python version
python3 --version

# Install Python 3.9 if needed
sudo ./install.sh --python-version=3.9
```

2. Port Conflicts
```bash
# Check if port 8000 is in use
sudo lsof -i :8000

# Change port in .env
PORT=8001
```

3. Permission Issues
```bash
# Fix permissions
sudo chown -R $USER:$USER .
```

### Logs

- Application logs: `logs/sumiya.log`
- Docker logs: `docker-compose logs`
- System logs: `journalctl -u sumiya`

## Development

### Setting Up Development Environment

1. Create virtual environment:
```bash
python3.9 -m venv venv
source venv/bin/activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run in development mode:
```bash
uvicorn app.main:app --reload
```

### Running Tests

```bash
pytest tests/
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please:
1. Check the [documentation](docs/)
2. Search [existing issues](https://github.com/yourusername/sumiya/issues)
3. Create a new issue if needed

## Authors

- Kh Maksudul Alam - Initial work - [iammaksudul](https://github.com/iammaksudul)

## Acknowledgments

- FastAPI team for the amazing framework
- Hugging Face for the AI models
- All contributors and users of Sumiya 