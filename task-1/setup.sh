#!/bin/bash

# setup.sh - Bootstrap script for deploying the application stack
# Usage: sudo bash setup.sh

set -e

echo "=========================================="
echo "  Application Stack Setup Script"
echo "=========================================="

# colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root (sudo bash setup.sh)"
fi

# step 1 - update system
log "Updating system packages..."
apt update && apt upgrade -y

# step 2 - install docker if not already installed
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
    log "Docker installed successfully"
else
    log "Docker is already installed"
fi

# step 3 - install docker compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log "Docker Compose installed successfully"
else
    log "Docker Compose is already installed"
fi

# step 4 - add current user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
    log "Added $SUDO_USER to docker group"
fi

# step 5 - build and start containers
log "Building Docker images..."
docker-compose build

log "Starting containers..."
docker-compose up -d

# step 6 - verify
log "Waiting for containers to start..."
sleep 10

echo ""
echo "=========================================="
echo "  Deployment Status"
echo "=========================================="
docker-compose ps

echo ""
log "Stack deployed successfully!"
echo ""
echo "Access the application:"
echo "  MERN App:  http://$(hostname -I | awk '{print $1}')/app/"
echo "  LAMP App:  http://$(hostname -I | awk '{print $1}')/legacy/"
echo "  Gateway:   http://$(hostname -I | awk '{print $1}')/"
echo ""
