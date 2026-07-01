# Hardening Checklist - Infrastructure Demo Server

## Applied Security Settings

### 1. Firewall (UFW)
- Default deny incoming traffic
- Default allow outgoing traffic
- Port 8080 open (demo service)
- Port 22 open (SSH)

### 2. User Management
- Non-root sudo user 'operator' created
- Service runs as 'root' (WSL environment)

### 3. File Permissions
- /opt/infra-demo/service.py - 755 (executable)
- /opt/infra-demo/infra-demo.env - 644 (readable)

### 4. Service Hardening
- Auto-restart on failure
- Service starts automatically on boot

## Not Applied (WSL Environment)
- Full SSH hardening (SSH not installed by default)
- Kernel parameters (managed by Windows)

## WSL Specific Notes
- Firewall relies on Windows Defender
- Systemd enabled via /etc/wsl.conf
- Reboot tested via wsl --terminate
