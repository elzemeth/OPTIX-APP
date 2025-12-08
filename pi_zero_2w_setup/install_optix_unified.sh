#!/bin/bash

# OPTIX Smart Glasses - Unified Installation Script
# Bu script tüm gerekli bileşenleri kurar ve sistemi yapılandırır

set -e

echo "🚀 OPTIX Smart Glasses - Unified Installation"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root. Please run as pi user."
   exit 1
fi

log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

log_info "Installing required system packages..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-gi \
    bluetooth \
    bluez \
    bluez-tools \
    rfkill \
    wireless-tools \
    wpasupplicant \
    network-manager \
    dbus \
    libglib2.0-dev \
    libgirepository1.0-dev \
    gcc \
    pkg-config

log_info "Installing Python packages..."
pip3 install --user \
    requests \
    PyGObject \
    dbus-python

# Check if camera is enabled
log_info "Checking camera configuration..."
if ! vcgencmd get_camera | grep -q "detected=1"; then
    log_warning "Camera not detected. Please enable camera in raspi-config."
    log_info "Run: sudo raspi-config -> Interface Options -> Camera -> Enable"
fi

# Install camera tools if not present
log_info "Installing camera tools..."
if ! command -v rpicam-still &> /dev/null; then
    log_warning "rpicam-still not found. Installing libcamera tools..."
    sudo apt install -y libcamera-apps
fi

# Create OPTIX directory
OPTIX_DIR="/home/$USER/optix"
log_info "Creating OPTIX directory: $OPTIX_DIR"
mkdir -p "$OPTIX_DIR"

# Copy main script
if [ -f "optix_smart_glasses.py" ]; then
    cp optix_smart_glasses.py "$OPTIX_DIR/"
    chmod +x "$OPTIX_DIR/optix_smart_glasses.py"
    log_success "OPTIX script installed"
else
    log_error "optix_smart_glasses.py not found in current directory"
    exit 1
fi

# Create configuration file
log_info "Creating configuration file..."
cat > "$OPTIX_DIR/config.json" << EOF
{
    "supabase_url": "https://YOUR_PROJECT_ID.supabase.co",
    "supabase_key": "YOUR_ANON_KEY_HERE",
    "camera": {
        "interval_sec": 3,
        "server_host": "192.168.1.141",
        "server_port": 5000
    },
    "bluetooth": {
        "device_name": "OPTIX",
        "advertising_interval": 30
    },
    "wifi": {
        "scan_interval": 60,
        "connection_timeout": 30
    }
}
EOF

log_success "Configuration file created: $OPTIX_DIR/config.json"
log_warning "Please edit the configuration file with your Supabase credentials!"

# Create systemd service
log_info "Creating systemd service..."
sudo tee /etc/systemd/system/optix-glasses.service > /dev/null << EOF
[Unit]
Description=OPTIX Smart Glasses - Unified System
After=network.target bluetooth.target
Wants=bluetooth.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$OPTIX_DIR
Environment=PATH=/usr/bin:/usr/local/bin:/home/$USER/.local/bin
Environment=PYTHONPATH=/home/$USER/.local/lib/python3.9/site-packages
ExecStart=/usr/bin/python3 $OPTIX_DIR/optix_smart_glasses.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Bluetooth permissions
SupplementaryGroups=bluetooth

[Install]
WantedBy=multi-user.target
EOF

# Enable and configure Bluetooth
log_info "Configuring Bluetooth..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Add user to bluetooth group
sudo usermod -a -G bluetooth "$USER"

# Configure Bluetooth settings
sudo tee /etc/bluetooth/main.conf > /dev/null << EOF
[General]
Name = OPTIX
Class = 0x000100
DiscoverableTimeout = 0
PairableTimeout = 0
Discoverable = yes
Pairable = yes

[GATT]
Cache = yes
KeySize = 16

[Policy]
AutoEnable=true
EOF

# Enable GPIO and camera
log_info "Configuring boot settings..."
if ! grep -q "dtparam=spi=on" /boot/config.txt; then
    echo "dtparam=spi=on" | sudo tee -a /boot/config.txt
fi

if ! grep -q "start_x=1" /boot/config.txt; then
    echo "start_x=1" | sudo tee -a /boot/config.txt
fi

if ! grep -q "gpu_mem=128" /boot/config.txt; then
    echo "gpu_mem=128" | sudo tee -a /boot/config.txt
fi

# Configure WiFi country (adjust as needed)
log_info "Setting WiFi country to TR (Turkey)..."
sudo raspi-config nonint do_wifi_country TR

# Create log directory
sudo mkdir -p /var/log/optix
sudo chown "$USER:$USER" /var/log/optix

# Enable and start service
log_info "Enabling OPTIX service..."
sudo systemctl daemon-reload
sudo systemctl enable optix-glasses.service

# Create helper scripts
log_info "Creating helper scripts..."

# Status script
cat > "$OPTIX_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "=== OPTIX Smart Glasses Status ==="
echo "Service Status:"
sudo systemctl status optix-glasses.service --no-pager -l

echo -e "\nBluetooth Status:"
sudo hciconfig hci0

echo -e "\nWiFi Status:"
iwgetid

echo -e "\nRecent Logs:"
sudo journalctl -u optix-glasses.service -n 20 --no-pager
EOF

# Start script
cat > "$OPTIX_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "Starting OPTIX Smart Glasses..."
sudo systemctl start optix-glasses.service
echo "Service started. Use ./status.sh to check status."
EOF

# Stop script
cat > "$OPTIX_DIR/stop.sh" << 'EOF'
#!/bin/bash
echo "Stopping OPTIX Smart Glasses..."
sudo systemctl stop optix-glasses.service
echo "Service stopped."
EOF

# Restart script
cat > "$OPTIX_DIR/restart.sh" << 'EOF'
#!/bin/bash
echo "Restarting OPTIX Smart Glasses..."
sudo systemctl restart optix-glasses.service
echo "Service restarted. Use ./status.sh to check status."
EOF

# Make scripts executable
chmod +x "$OPTIX_DIR"/*.sh

log_success "Helper scripts created:"
log_info "  - ./status.sh  : Check service status"
log_info "  - ./start.sh   : Start service"
log_info "  - ./stop.sh    : Stop service"
log_info "  - ./restart.sh : Restart service"

# Create test script
cat > "$OPTIX_DIR/test_system.py" << 'EOF'
#!/usr/bin/env python3
"""Test script for OPTIX system components"""

import subprocess
import sys
import json

def test_bluetooth():
    """Test Bluetooth functionality"""
    try:
        result = subprocess.run(['hciconfig', 'hci0'], capture_output=True, text=True)
        if result.returncode == 0 and 'UP RUNNING' in result.stdout:
            print("✅ Bluetooth: OK")
            return True
        else:
            print("❌ Bluetooth: Not running")
            return False
    except Exception as e:
        print(f"❌ Bluetooth test failed: {e}")
        return False

def test_camera():
    """Test camera functionality"""
    try:
        # Test with rpicam-hello
        result = subprocess.run(['rpicam-hello', '--timeout', '100'], 
                              capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print("✅ Camera: OK")
            return True
        else:
            print("❌ Camera: Not working")
            return False
    except Exception as e:
        print(f"❌ Camera test failed: {e}")
        return False

def test_wifi():
    """Test WiFi functionality"""
    try:
        result = subprocess.run(['iwconfig'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ WiFi interface: OK")
            return True
        else:
            print("❌ WiFi interface: Not found")
            return False
    except Exception as e:
        print(f"❌ WiFi test failed: {e}")
        return False

def test_serial():
    """Test serial number reading"""
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if line.startswith('Serial'):
                    serial = line.split(':')[1].strip()
                    print(f"✅ Serial number: {serial}")
                    return True
        print("❌ Serial number: Not found")
        return False
    except Exception as e:
        print(f"❌ Serial test failed: {e}")
        return False

def main():
    print("🔍 OPTIX System Test")
    print("=" * 30)
    
    tests = [
        ("Bluetooth", test_bluetooth),
        ("Camera", test_camera),
        ("WiFi", test_wifi),
        ("Serial Number", test_serial)
    ]
    
    results = []
    for name, test_func in tests:
        print(f"\nTesting {name}...")
        results.append(test_func())
    
    print("\n" + "=" * 30)
    passed = sum(results)
    total = len(results)
    
    if passed == total:
        print(f"🎉 All tests passed! ({passed}/{total})")
        sys.exit(0)
    else:
        print(f"⚠️  Some tests failed. ({passed}/{total})")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$OPTIX_DIR/test_system.py"

log_success "Test script created: ./test_system.py"

echo
echo "=============================================="
log_success "OPTIX Smart Glasses installation completed!"
echo "=============================================="
echo
log_info "Next steps:"
echo "1. Edit configuration: nano $OPTIX_DIR/config.json"
echo "2. Test system: cd $OPTIX_DIR && ./test_system.py"
echo "3. Start service: cd $OPTIX_DIR && ./start.sh"
echo "4. Check status: cd $OPTIX_DIR && ./status.sh"
echo
log_warning "Important:"
echo "- Update Supabase credentials in config.json"
echo "- Ensure camera is enabled in raspi-config"
echo "- Reboot is recommended after first installation"
echo
log_info "Service will start automatically on boot."
log_info "Logs can be viewed with: sudo journalctl -u optix-glasses.service -f"
echo
