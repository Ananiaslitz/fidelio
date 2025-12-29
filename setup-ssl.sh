#!/bin/bash

# SSL Certificate Setup Script using Let's Encrypt
# Run this after your domain is pointing to the server

set -e

echo "🔒 SSL Certificate Setup with Let's Encrypt"
echo "==========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if .env.production exists
if [ ! -f .env.production ]; then
    echo -e "${RED}Error: .env.production file not found!${NC}"
    exit 1
fi

# Load environment variables
source .env.production

# Validate required variables
if [ -z "$DOMAIN" ] || [ "$DOMAIN" == "YOURDOMAIN.cloud" ]; then
    echo -e "${RED}Error: Please set your DOMAIN in .env.production${NC}"
    exit 1
fi

if [ -z "$CERTBOT_EMAIL" ] || [ "$CERTBOT_EMAIL" == "your-email@example.com" ]; then
    echo -e "${RED}Error: Please set your CERTBOT_EMAIL in .env.production${NC}"
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Email: $CERTBOT_EMAIL"
echo ""

# Confirm domain is pointing to this server
echo -e "${YELLOW}⚠️  Important: Make sure your domain $DOMAIN is pointing to this server's IP!${NC}"
read -p "Is your domain configured correctly? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please configure your domain first, then run this script again."
    exit 1
fi

# Stop nginx to free port 80
echo -e "${YELLOW}Stopping Nginx...${NC}"
docker-compose -f docker-compose.production.yml stop nginx

# Obtain SSL certificate
echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
docker-compose -f docker-compose.production.yml run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $CERTBOT_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} SSL certificate obtained successfully!"
    
    # Update nginx configuration to enable HTTPS
    echo -e "${YELLOW}Updating Nginx configuration...${NC}"
    
    # Replace YOURDOMAIN.cloud with actual domain
    sed -i "s/YOURDOMAIN.cloud/$DOMAIN/g" nginx/conf.d/default.conf
    
    # Uncomment HTTPS server block
    sed -i 's/# server {/server {/g' nginx/conf.d/default.conf
    sed -i 's/#     /    /g' nginx/conf.d/default.conf
    sed -i 's/# }/}/g' nginx/conf.d/default.conf
    
    # Comment out temporary HTTP proxy
    sed -i 's/    # Temporary:/    # Temporary (disabled after SSL):/g' nginx/conf.d/default.conf
    sed -i '/# Temporary (disabled after SSL):/,/^    }$/ s/^/    # /' nginx/conf.d/default.conf
    
    # Enable redirect to HTTPS
    sed -i 's/    # location \/ {/    location \/ {/g' nginx/conf.d/default.conf
    sed -i 's/    #     return 301/        return 301/g' nginx/conf.d/default.conf
    sed -i 's/    # }/    }/g' nginx/conf.d/default.conf
    
    echo -e "${GREEN}✓${NC} Nginx configuration updated"
    
    # Restart services
    echo -e "${YELLOW}Restarting services...${NC}"
    docker-compose -f docker-compose.production.yml up -d
    
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}✓ SSL Setup Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo "Your site is now available at:"
    echo "  - https://$DOMAIN"
    echo "  - API: https://$DOMAIN/api"
    echo ""
    echo "Certificate will auto-renew every 12 hours."
    
else
    echo -e "${RED}Failed to obtain SSL certificate!${NC}"
    echo "Please check:"
    echo "  1. Domain is pointing to this server"
    echo "  2. Port 80 is accessible from the internet"
    echo "  3. Firewall allows HTTP/HTTPS traffic"
    
    # Restart nginx
    docker-compose -f docker-compose.production.yml up -d nginx
    exit 1
fi
