#!/bin/bash
set -e

echo "============================================"
echo "Home Lab Bootstrap - Setup Script"
echo "============================================"
echo ""

# Color output functions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

echo "Step 1: Creating environment file"
echo "-----------------------------------"

# Copy root .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp env.sample .env
    success "Created .env from sample"
else
    warning ".env already exists, skipping copy"
fi

echo ""
echo "Step 2: Generating secure secrets"
echo "-----------------------------------"

# Generate secure random values
KOMODO_DB_PASSWORD=$(openssl rand -base64 24)
KOMODO_PASSKEY=$(openssl rand -base64 32)
KOMODO_WEBHOOK_SECRET=$(openssl rand -base64 32)
KOMODO_JWT_SECRET=$(openssl rand -base64 32)
KOMODO_INIT_ADMIN_PASSWORD=$(openssl rand -base64 24)
KOMODO_API_TOKEN=$(openssl rand -base64 32)

success "Generated secure random secrets"

echo ""
echo "Step 3: Writing secrets to .env file"
echo "-----------------------------------"

# Update root .env file with generated secrets
sed -i "s|^KOMODO_DB_PASSWORD=.*|KOMODO_DB_PASSWORD=${KOMODO_DB_PASSWORD}|" .env
sed -i "s|^KOMODO_PASSKEY=.*|KOMODO_PASSKEY=${KOMODO_PASSKEY}|" .env
sed -i "s|^KOMODO_WEBHOOK_SECRET=.*|KOMODO_WEBHOOK_SECRET=${KOMODO_WEBHOOK_SECRET}|" .env
sed -i "s|^KOMODO_JWT_SECRET=.*|KOMODO_JWT_SECRET=${KOMODO_JWT_SECRET}|" .env
sed -i "s|^KOMODO_INIT_ADMIN_PASSWORD=.*|KOMODO_INIT_ADMIN_PASSWORD=${KOMODO_INIT_ADMIN_PASSWORD}|" .env
sed -i "s|^KOMODO_API_TOKEN=.*|KOMODO_API_TOKEN=${KOMODO_API_TOKEN}|" .env

success "Wrote all secrets to .env"

echo ""
echo "Step 4: Creating Docker networks"
echo "-----------------------------------"

# Create the shared proxy network for Traefik
if docker network inspect proxy >/dev/null 2>&1; then
    warning "Network 'proxy' already exists, skipping"
else
    docker network create proxy
    success "Created Docker network 'proxy'"
fi

# Create br9 network if it doesn't exist (optional)
if docker network inspect br9 >/dev/null 2>&1; then
    warning "Network 'br9' already exists, skipping"
else
    docker network create br9 --subnet=${PROXY_SUBNET}
    success "Created Docker network 'br9'"
fi

echo ""
echo "Step 5: Creating Docker volumes"
echo "-----------------------------------"

if docker volume inspect komodo-data >/dev/null 2>&1; then
    warning "Volume 'komodo-data' already exists, skipping"
else
    docker volume create komodo-data
    success "Created Docker volume 'komodo-data'"
fi

echo ""
echo "Step 6: Configuring Traefik"
echo "-----------------------------------"

# Ensure acme.json exists with correct permissions
touch traefik/acme/acme.json
chmod 600 traefik/acme/acme.json
touch traefik/acme/acme-staging.json
chmod 600 traefik/acme/acme-staging.json

success "Configured Traefik certificate storage"

echo ""
echo "============================================"
echo "Setup Complete!"
echo "============================================"
echo ""
echo "Generated Admin Passwords (SAVE THESE!):"
echo "-----------------------------------"
echo "Komodo Admin Password:"
echo "  ${KOMODO_INIT_ADMIN_PASSWORD}"
echo ""
echo "⚠ IMPORTANT: Edit .env with your configuration:"
echo "-----------------------------------"
echo ""
echo "Required values to set in .env:"
echo "  - DOMAIN (currently: coddington.cc)"
echo "  - ACME_EMAIL (your email address)"
echo "  - CF_DNS_API_TOKEN (your Cloudflare API token)"
echo ""
echo "Optional values in .env:"
echo "  - GIT_USERNAME (for git-based Komodo stacks)"
echo "  - GIT_TOKEN (for git-based Komodo stacks)"
echo "  - TRAEFIK_BR9_IP (if using br9 network)"
echo "  - KOMODO_BACKUPS_PATH (default: /backups)"
echo "  - KOMODO_STACKS_PATH (default: /stacks)"
echo ""
echo "Next Steps:"
echo "-----------------------------------"
echo "1. Edit .env with your domain and Cloudflare token"
echo "2. Run: docker compose up -d"
echo "3. Monitor: docker compose logs -f"
echo ""
echo "After bootstrap completes, services will be available at:"
echo "  - Traefik Dashboard: https://traefik.<your-domain>"
echo "  - Komodo UI: https://komodo.<your-domain>"
echo ""
echo "First login credentials:"
echo "  Komodo    - Username: admin, Password: ${KOMODO_INIT_ADMIN_PASSWORD}"
echo ""
