#!/usr/bin/env bash
set -euo pipefail

# Installer for OPTIX Pi Zero 2W client (BLE + WiFi + camera)
# Installs dependencies, creates venv, and sets up systemd service.

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required. Please install/enable sudo." >&2
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$BASE_DIR/.venv"
SERVICE_DST="/etc/systemd/system/smart-glasses.service"
ENTRYPOINT="$BASE_DIR/optix_smart_glasses.py"

echo "[1/6] Updating package lists..."
sudo apt-get update -y

echo "[2/6] Installing system dependencies..."
sudo apt-get install -y \
  python3 python3-pip python3-venv \
  bluez bluez-tools bluetooth \
  python3-dbus python3-gi python3-gi-cairo \
  libglib2.0-dev libdbus-1-dev \
  libcairo2-dev libgirepository1.0-dev \
  pkg-config build-essential

echo "[3/6] Creating virtualenv and installing Python deps..."
python3 -m venv --system-site-packages "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install \
  requests \
  dbus-python
# Note: pygobject (gi.repository) is provided by system package python3-gi
# Using --system-site-packages allows venv to access system packages

echo "[4/6] Writing systemd service to $SERVICE_DST ..."
sudo tee "$SERVICE_DST" >/dev/null <<EOF
[Unit]
Description=OPTIX Smart Glasses BLE/WiFi client
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$BASE_DIR
Environment="PYTHONPATH=$BASE_DIR"
Environment="BLUETOOTH_DEVICE_NAME=OPTIX"
ExecStart=$VENV_DIR/bin/python $ENTRYPOINT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
ReadWritePaths=$BASE_DIR

[Install]
WantedBy=multi-user.target
EOF

echo "[5/6] Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable smart-glasses.service
sudo systemctl restart smart-glasses.service

echo "[6/6] Status:"
sudo systemctl status smart-glasses.service --no-pager || true

echo "Done. Logs: journalctl -u smart-glasses.service -f"