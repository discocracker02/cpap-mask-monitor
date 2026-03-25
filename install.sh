#!/bin/bash
# CPAP Mask Monitor — one-command installer for macOS
# Usage: bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_PATH="$HOME/Library/LaunchAgents/com.cpap.monitor.plist"
PYTHON=$(which python3.11 2>/dev/null || which python3)

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       CPAP Mask Monitor — Installer      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Check Python version
echo "► Checking Python..."
PY_VERSION=$($PYTHON --version 2>&1 | awk '{print $2}')
echo "  Found: Python $PY_VERSION"

# 2. Install dependencies
echo "► Installing Python dependencies..."
$PYTHON -m pip install tapo requests --quiet
echo "  Done."

# 3. Config setup
if [ ! -f "$REPO_DIR/config.json" ]; then
    echo ""
    echo "► Setting up config.json..."
    cp "$REPO_DIR/config.example.json" "$REPO_DIR/config.json"
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  Please fill in your details:           │"
    echo "  │                                         │"
    echo "  │  • Tapo account email & password        │"
    echo "  │  • Tapo plug IP address                 │"
    echo "  │  • Pushover user key & app token        │"
    echo "  └─────────────────────────────────────────┘"
    echo ""
    read -p "  Press Enter to open config.json in your editor..."
    ${EDITOR:-nano} "$REPO_DIR/config.json"
else
    echo "► config.json already exists, skipping."
fi

# 4. Create launchd plist
echo "► Installing background service (launchd)..."
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cpap.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON</string>
        <string>-u</string>
        <string>$REPO_DIR/cpap_monitor.py</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$REPO_DIR/cpap_monitor.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_DIR/cpap_monitor.log</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

# 5. Load the service
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         Installation Complete! ✓         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "  Monitor is now running in the background."
echo ""
echo "  Useful commands:"
echo "  • Check status:  launchctl list | grep cpap"
echo "  • View logs:     tail -f $REPO_DIR/cpap_monitor.log"
echo "  • Stop monitor:  launchctl unload $PLIST_PATH"
echo "  • Start monitor: launchctl load $PLIST_PATH"
echo ""
