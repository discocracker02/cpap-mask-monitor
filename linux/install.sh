#!/bin/bash
# CPAP Mask Monitor — Linux Installer
# 
# One-line install:
#   curl -sSL https://raw.githubusercontent.com/discocracker02/cpap-mask-monitor/main/linux/install.sh | bash
#
# Or run manually:
#   bash install.sh

set -e

INSTALL_DIR="$HOME/cpap-mask-monitor"
REPO_URL="https://github.com/discocracker02/cpap-mask-monitor"
SERVICE_DIR="$HOME/.config/systemd/user"

echo ""
echo "============================================"
echo "   CPAP Mask Monitor - Linux Installer"
echo "============================================"
echo ""

# ── Detect distro ─────────────────────────────────────────────────────────────
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi
echo "► Detected distro: $DISTRO"

# ── Check Python ──────────────────────────────────────────────────────────────
echo "► Checking Python..."
if command -v python3 &>/dev/null; then
    PY_VERSION=$(python3 --version)
    echo "  Found: $PY_VERSION"
    PYTHON=python3
else
    echo "  Python3 not found. Installing..."
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip
    elif [[ "$DISTRO" == "fedora" ]]; then
        sudo dnf install -y python3 python3-pip
    elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Sy --noconfirm python python-pip
    else
        echo "  ERROR: Could not install Python automatically."
        echo "  Please install Python 3.10+ manually and run this script again."
        exit 1
    fi
    PYTHON=python3
fi

# ── Check pip ─────────────────────────────────────────────────────────────────
echo "► Checking pip..."
if ! $PYTHON -m pip --version &>/dev/null; then
    echo "  pip not found. Installing..."
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        sudo apt-get install -y python3-pip
    elif [[ "$DISTRO" == "fedora" ]]; then
        sudo dnf install -y python3-pip
    elif [[ "$DISTRO" == "arch" ]]; then
        sudo pacman -Sy --noconfirm python-pip
    fi
fi
echo "  OK"

# ── Check Rust (required for tapo library) ────────────────────────────────────
echo "► Checking Rust..."
if ! command -v cargo &>/dev/null; then
    echo "  Rust not found. Installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
    source "$HOME/.cargo/env"
    echo "  Rust installed."
else
    echo "  Found: $(rustc --version)"
fi

# ── Install Python dependencies ───────────────────────────────────────────────
echo "► Installing Python dependencies..."
$PYTHON -m pip install tapo requests --quiet --break-system-packages 2>/dev/null || \
$PYTHON -m pip install tapo requests --quiet
echo "  Done"

# ── Create install directory ──────────────────────────────────────────────────
echo "► Setting up install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy files (if running from cloned repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in cpap_monitor.py cpap_http_server.py config.example.json; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        cp "$SCRIPT_DIR/$f" "$INSTALL_DIR/"
    fi
done
echo "  Done"

# ── Config setup ──────────────────────────────────────────────────────────────
echo "► Setting up config..."
if [ ! -f "$INSTALL_DIR/config.json" ]; then
    cp "$INSTALL_DIR/config.example.json" "$INSTALL_DIR/config.json"
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  Please fill in your details:           │"
    echo "  │                                         │"
    echo "  │  • Tapo account email & password        │"
    echo "  │  • Tapo plug IP address                 │"
    echo "  │  • Pushover user key & app token        │"
    echo "  │  • Your timezone offset (e.g. 5.5 IST) │"
    echo "  └─────────────────────────────────────────┘"
    echo ""
    read -p "  Press Enter to open config.json in nano..."
    nano "$INSTALL_DIR/config.json"
else
    echo "  config.json already exists, skipping."
fi

# ── Create systemd user services ──────────────────────────────────────────────
echo "► Installing systemd services..."
mkdir -p "$SERVICE_DIR"

# Monitor service
cat > "$SERVICE_DIR/cpap-monitor.service" << EOF
[Unit]
Description=CPAP Mask Monitor
After=network.target

[Service]
Type=simple
ExecStart=$PYTHON $INSTALL_DIR/cpap_monitor.py
WorkingDirectory=$INSTALL_DIR
Restart=always
RestartSec=10
StandardOutput=append:$INSTALL_DIR/cpap_monitor.log
StandardError=append:$INSTALL_DIR/cpap_monitor.log

[Install]
WantedBy=default.target
EOF

# HTTP server service
cat > "$SERVICE_DIR/cpap-httpserver.service" << EOF
[Unit]
Description=CPAP HTTP Alert Server
After=network.target

[Service]
Type=simple
ExecStart=$PYTHON $INSTALL_DIR/cpap_http_server.py
WorkingDirectory=$INSTALL_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# Enable lingering so services run without login
loginctl enable-linger "$USER" 2>/dev/null || true

# Reload and enable services
systemctl --user daemon-reload
systemctl --user enable cpap-monitor.service cpap-httpserver.service
systemctl --user start cpap-monitor.service cpap-httpserver.service
echo "  Done"

# ── Verify ────────────────────────────────────────────────────────────────────
sleep 3
echo ""
echo "► Verifying services..."
MONITOR_STATUS=$(systemctl --user is-active cpap-monitor.service)
HTTP_STATUS=$(systemctl --user is-active cpap-httpserver.service)
echo "  Monitor:     $MONITOR_STATUS"
echo "  HTTP server: $HTTP_STATUS"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "      Installation Complete!               "
echo "============================================"
echo ""
echo "  Monitor is now running in the background."
echo ""
echo "  Useful commands:"
echo "  • Check status:   systemctl --user status cpap-monitor"
echo "  • View log:       tail -f $INSTALL_DIR/cpap_monitor.log"
echo "  • Stop monitor:   systemctl --user stop cpap-monitor"
echo "  • Start monitor:  systemctl --user start cpap-monitor"
echo "  • HTTP status:    curl http://localhost:8765/status"
echo ""
echo "  Install directory: $INSTALL_DIR"
echo "  Log file:          $INSTALL_DIR/cpap_monitor.log"
echo ""
