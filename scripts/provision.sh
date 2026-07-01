#!/bin/bash -e

# provision.sh - Linux Infrastructure Intern Assignment
# This script is IDEMPOTENT - running it multiple times is safe

set -e  # Stop if any command fails

# Colors for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=========================================="
echo "Linux Infrastructure Provisioning v1.0"
echo "=========================================="

# ============================================
# PART 1: Base Setup (FR1)
# ============================================

log_info "Detecting OS..."
. /etc/os-release
log_info "OS: $NAME $VERSION"

log_info "Updating package index..."
sudo apt update -qq

log_info "Installing required packages..."
sudo apt install -y ufw curl wget git vim python3 python3-pip

log_info "Creating non-root sudo user 'operator'..."
if id "operator" &>/dev/null; then
    log_warn "User 'operator' already exists - skipping"
else
    sudo useradd -m -s /bin/bash -G sudo operator
    echo "operator:Operator123!" | sudo chpasswd
    log_info "User 'operator' created"
fi

# ============================================
# PART 2: Demo Service Setup (FR2 & FR3)
# ============================================

log_info "Creating service directories..."
sudo mkdir -p /opt/infra-demo
sudo mkdir -p /var/log/infra-demo

log_info "Creating environment file..."
cat << 'EOF' | sudo tee /opt/infra-demo/infra-demo.env
# Demo Service Configuration
PORT=8080
LOG_PATH=/var/log/infra-demo/service.log
EOF

log_info "Creating Python health service..."
cat << 'EOF' | sudo tee /opt/infra-demo/service.py
#!/usr/bin/env python3
import os
import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = int(os.environ.get('PORT', 8080))
LOG_PATH = os.environ.get('LOG_PATH', '/var/log/infra-demo/service.log')

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = json.dumps({
                'status': 'healthy',
                'service': 'infra-demo',
                'version': '1.0.0'
            })
            self.wfile.write(response.encode())
            logging.info(f'Health check from {self.client_address[0]}')
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'Not Found')
    
    def log_message(self, format, *args):
        logging.info(f'{self.address_string()} - {format % args}')

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), HealthHandler)
    print(f'Starting health service on port {PORT}')
    logging.info(f'Service started on port {PORT}')
    server.serve_forever()
EOF

sudo chmod +x /opt/infra-demo/service.py

log_info "Creating systemd service file..."
cat << 'EOF' | sudo tee /etc/systemd/system/infra-demo.service
[Unit]
Description=Infrastructure Demo HTTP Health Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
EnvironmentFile=/opt/infra-demo/infra-demo.env
ExecStart=/usr/bin/python3 /opt/infra-demo/service.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# PART 3: Maintenance Timer (FR4)
# ============================================

log_info "Creating maintenance script..."
cat << 'EOF' | sudo tee /usr/local/bin/infra-maintenance.sh
#!/bin/bash
# Maintenance: Take health snapshot and clean old logs

SNAPSHOT_DIR="/var/log/infra-demo/snapshots"
mkdir -p $SNAPSHOT_DIR

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
curl -s http://localhost:8080/health > $SNAPSHOT_DIR/health_$TIMESTAMP.json 2>/dev/null

# Keep only last 30 snapshots
ls -t $SNAPSHOT_DIR/health_*.json 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null

echo "Maintenance completed at $(date)" >> /var/log/infra-demo/maintenance.log
EOF

sudo chmod +x /usr/local/bin/infra-maintenance.sh

log_info "Creating systemd timer..."
cat << 'EOF' | sudo tee /etc/systemd/system/infra-maintenance.service
[Unit]
Description=Infrastructure Maintenance Service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/infra-maintenance.sh
User=root
EOF

cat << 'EOF' | sudo tee /etc/systemd/system/infra-maintenance.timer
[Unit]
Description=Run infrastructure maintenance daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# ============================================
# PART 4: Basic Hardening (FR5)
# ============================================

log_info "Applying file permissions..."
sudo chown -R nobody:nogroup /opt/infra-demo
sudo chmod 644 /opt/infra-demo/infra-demo.env
sudo chmod 755 /opt/infra-demo/service.py
sudo chmod 755 /usr/local/bin/infra-maintenance.sh

log_info "Configuring firewall (UFW)..."
sudo ufw --force disable 2>/dev/null || true
sudo ufw default deny incoming 2>/dev/null || true
sudo ufw default allow outgoing 2>/dev/null || true
sudo ufw allow 8080/tcp comment 'Demo service' 2>/dev/null || true
sudo ufw allow 22/tcp comment 'SSH' 2>/dev/null || true
sudo ufw --force enable 2>/dev/null || log_warn "UFW may have limited functionality"

log_info "Setting SSH defaults..."
if [ -f /etc/ssh/sshd_config ]; then
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo systemctl restart ssh 2>/dev/null || log_warn "SSH service not running"
else
    log_warn "SSH not installed - skipping"
fi

# ============================================
# PART 5: Start Services
# ============================================

log_info "Reloading systemd..."
sudo systemctl daemon-reload

log_info "Enabling and starting demo service..."
sudo systemctl enable infra-demo.service
sudo systemctl restart infra-demo.service

log_info "Enabling and starting maintenance timer..."
sudo systemctl enable infra-maintenance.timer
sudo systemctl start infra-maintenance.timer

# ============================================
# PART 6: Verification
# ============================================

log_info "Verifying setup..."
sleep 3

if systemctl is-active --quiet infra-demo.service; then
    log_info "✅ Demo service is running"
else
    log_warn "⚠️ Demo service may not be running - check with: sudo systemctl status infra-demo"
fi

if curl -s http://localhost:8080/health | grep -q "healthy"; then
    log_info "✅ Health endpoint responding correctly"
else
    log_warn "⚠️ Health endpoint not responding"
fi

echo "=========================================="
echo "Provisioning Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Service: http://localhost:8080/health"
echo "  - Logs: sudo journalctl -u infra-demo -f"
echo "  - Timer: sudo systemctl list-timers infra-maintenance"
echo "  - Validate: ./scripts/validate.sh"
echo ""
