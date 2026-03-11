#!/bin/bash

# firewall.sh - Configure UFW firewall rules for the application server
# Usage: sudo bash firewall.sh

set -e

echo "Configuring firewall rules..."

# reset ufw to default (deny all incoming, allow all outgoing)
ufw --force reset

# default policies
ufw default deny incoming
ufw default allow outgoing

# allow SSH (rate limited to prevent brute force)
ufw limit 22/tcp
echo "[OK] SSH (port 22) - rate limited"

# allow HTTP
ufw allow 80/tcp
echo "[OK] HTTP (port 80)"

# allow HTTPS
ufw allow 443/tcp
echo "[OK] HTTPS (port 443)"

# NOTE: database ports (3306, 27017) are NOT exposed to the internet
# they are only accessible within the Docker network
# if you need remote DB access, whitelist specific IPs:
# ufw allow from <trusted-ip> to any port 3306
# ufw allow from <trusted-ip> to any port 27017

# allow Node API port only from localhost (for testing)
ufw allow from 127.0.0.1 to any port 5000
echo "[OK] Node API (port 5000) - localhost only"

# enable the firewall
ufw --force enable

echo ""
echo "Firewall status:"
ufw status verbose

echo ""
echo "Firewall configured successfully."
echo ""
echo "Summary of rules:"
echo "  - SSH (22)    : rate limited (6 attempts/30 sec)"
echo "  - HTTP (80)   : open"
echo "  - HTTPS (443) : open"
echo "  - MySQL (3306): blocked externally (docker internal only)"
echo "  - MongoDB (27017): blocked externally (docker internal only)"
echo "  - All other ports: denied"
