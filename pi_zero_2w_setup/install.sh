#!/bin/bash

echo "🚀 Installing OPTIX GATT Server..."

# Copy files
echo "📁 Copying files..."
sudo cp gatt_server.py /home/hakan/optix/pi_zero_2w_setup/
sudo cp smart-glasses.service /etc/systemd/system/

# Set permissions
echo "🔧 Setting permissions..."
sudo chmod +x /home/hakan/optix/pi_zero_2w_setup/gatt_server.py
sudo chown root:root /etc/systemd/system/smart-glasses.service
sudo chown hakan:hakan /home/hakan/optix/pi_zero_2w_setup/gatt_server.py

# Reload systemd
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start service
echo "▶️ Enabling and starting service..."
sudo systemctl enable smart-glasses.service
sudo systemctl restart smart-glasses.service

# Check status
echo "📊 Service status:"
sudo systemctl status smart-glasses.service --no-pager

echo "✅ OPTIX GATT Server installation complete!"
echo ""
echo "📱 Your device will be advertised as: OPTIX"
echo "🔧 Service UUIDs are configured for Flutter app"
echo ""
echo "📋 Useful commands:"
echo "  sudo systemctl status smart-glasses.service"
echo "  sudo systemctl restart smart-glasses.service" 
echo "  sudo journalctl -u smart-glasses.service -f"