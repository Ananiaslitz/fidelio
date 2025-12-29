#!/bin/bash

# Fidelio Production Deployment Script
# This script helps deploy the application to a VPS

set -e

echo "🚀 Backly Production Deployment"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo -e "${RED}Error: .env.production file not found!${NC}"
    echo "Please copy .env.production.example to .env.production and configure it."
    exit 1
fi

# Load environment variables
source .env.production

echo -e "${GREEN}✓${NC} Environment variables loaded"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed!${NC}"
    echo "Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is installed"

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed!${NC}"
    echo "Please install Docker Compose first: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker Compose is installed"

# Pull latest changes (disabled for manual deployment)
# if [ -d .git ]; then
#     echo -e "${YELLOW}Pulling latest changes...${NC}"
#     git pull
#     echo -e "${GREEN}✓${NC} Code updated"
# fi

# Build Docker images
echo -e "${YELLOW}Building Docker images...${NC}"
docker-compose -f docker-compose.production.yml build --no-cache

echo -e "${GREEN}✓${NC} Images built successfully"

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker-compose -f docker-compose.production.yml down

# Start containers
echo -e "${YELLOW}Starting containers...${NC}"
docker-compose -f docker-compose.production.yml up -d

echo -e "${GREEN}✓${NC} Containers started"

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be healthy...${NC}"
sleep 10

# Check container status
echo -e "${YELLOW}Container Status:${NC}"
docker-compose -f docker-compose.production.yml ps

# Show logs
echo ""
echo -e "${YELLOW}Recent logs:${NC}"
docker-compose -f docker-compose.production.yml logs --tail=50

echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}✓ Deployment completed!${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo "Your application is now running!"
echo ""
echo "Access points:"
echo "  - Web Portal: http://${DOMAIN:-YOUR_IP}"
echo "  - API: http://${DOMAIN:-YOUR_IP}/api"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose -f docker-compose.production.yml logs -f"
echo "  - Stop services: docker-compose -f docker-compose.production.yml down"
echo "  - Restart services: docker-compose -f docker-compose.production.yml restart"
echo ""

# SSL Certificate setup reminder
if [ "${SSL_ENABLED}" != "true" ]; then
    echo -e "${YELLOW}⚠️  SSL is not enabled yet!${NC}"
    echo "To enable HTTPS with Let's Encrypt:"
    echo "  1. Make sure your domain points to this server"
    echo "  2. Run: ./setup-ssl.sh"
    echo ""
fi
