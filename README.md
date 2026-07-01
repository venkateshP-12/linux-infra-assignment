# Linux Infrastructure Assignment

## Author
Suryaprakash Bandoju

## Demo Video
[Click here for demo video](https://youtu.be/Jv5rodq-iw0)

## Environment
- OS: Ubuntu 22.04 LTS
- Platform: WSL2 (Windows Subsystem for Linux)
- Systemd: Enabled via /etc/wsl.conf

## Quick Start
```bash
git clone https://github.com/venkateshP-12/linux-infra-assignment.git
cd linux-infra-assignment
./scripts/provision.sh
./scripts/validate.sh

linux-infra-assignment/
├── scripts/
│   ├── provision.sh      # Main setup script (idempotent)
│   └── validate.sh       # Comprehensive validation
├── config/
│   └── infra-demo.env    # Service configuration
├── systemd/
│   ├── infra-demo.service      # Health service unit
│   └── infra-maintenance.timer # Daily maintenance timer
├── docs/
│   └── hardening-checklist.md  # Security documentation
└── evidence/                   # Screenshot proofs
