#!/usr/bin/env python3
"""
WiFi Credentials File Watcher
Monitors /tmp/wifi_credentials.json for changes and configures WiFi
"""

import json
import logging
import os
import subprocess
import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [WiFi Watcher] - %(message)s'
)
logger = logging.getLogger('WiFiWatcher')

WIFI_CREDENTIALS_FILE = '/tmp/wifi_credentials.json'
WPA_SUPPLICANT_CONF = '/etc/wpa_supplicant/wpa_supplicant.conf'
LAST_PROCESSED_HASH = '/tmp/wifi_credentials_last_hash.txt'


class WiFiCredentialsHandler(FileSystemEventHandler):
    """Handle WiFi credentials file changes"""
    
    def __init__(self):
        self.last_hash = self._get_file_hash()
        logger.info(f"📁 Watching {WIFI_CREDENTIALS_FILE}")
    
    def _get_file_hash(self):
        """Get file hash to detect changes"""
        try:
            if os.path.exists(WIFI_CREDENTIALS_FILE):
                with open(WIFI_CREDENTIALS_FILE, 'r') as f:
                    content = f.read()
                    return hash(content)
        except Exception as e:
            logger.debug(f"Error getting file hash: {e}")
        return None
    
    def _read_credentials(self):
        """Read WiFi credentials from file"""
        try:
            if not os.path.exists(WIFI_CREDENTIALS_FILE):
                return None
            
            with open(WIFI_CREDENTIALS_FILE, 'r') as f:
                data = json.load(f)
                return {
                    'ssid': data.get('ssid', ''),
                    'password': data.get('password', ''),
                    'timestamp': data.get('timestamp', '')
                }
        except Exception as e:
            logger.error(f"❌ Error reading credentials: {e}")
            return None
    
    def _configure_wifi(self, ssid, password):
        """Configure WiFi using wpa_supplicant"""
        try:
            logger.info(f"📡 Configuring WiFi for SSID: {ssid}")
            
            # Create wpa_supplicant configuration
            config = f"""country=TR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={{
    ssid="{ssid}"
    psk="{password}"
    key_mgmt=WPA-PSK
}}
"""
            # Write to temporary file
            temp_config = '/tmp/wpa_supplicant_new.conf'
            with open(temp_config, 'w') as f:
                f.write(config)
            
            # Copy to system location with sudo
            result = subprocess.run(
                ['sudo', 'cp', temp_config, WPA_SUPPLICANT_CONF],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0:
                logger.error(f"❌ Failed to copy config: {result.stderr}")
                return False
            
            # Restart networking
            logger.info("🔄 Restarting networking...")
            result = subprocess.run(
                ['sudo', 'systemctl', 'restart', 'dhcpcd'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0:
                logger.warning(f"⚠️ dhcpcd restart warning: {result.stderr}")
            
            # Also restart wpa_supplicant
            result = subprocess.run(
                ['sudo', 'systemctl', 'restart', 'wpa_supplicant'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            logger.info("✅ WiFi configuration applied")
            
            # Wait and check connection
            time.sleep(5)
            if self._check_wifi_connection(ssid):
                logger.info(f"✅ WiFi connected to {ssid}")
                return True
            else:
                logger.warning(f"⚠️ WiFi connection to {ssid} not confirmed")
                return False
                
        except Exception as e:
            logger.error(f"❌ WiFi configuration error: {e}")
            return False
    
    def _check_wifi_connection(self, ssid):
        """Check if WiFi is connected to given SSID"""
        try:
            result = subprocess.run(
                ['iwgetid'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0 and ssid in result.stdout:
                return True
        except Exception:
            pass
        return False
    
    def on_modified(self, event):
        """Handle file modification"""
        if event.src_path == WIFI_CREDENTIALS_FILE:
            logger.info("📝 WiFi credentials file modified")
            self._process_credentials()
    
    def on_created(self, event):
        """Handle file creation"""
        if event.src_path == WIFI_CREDENTIALS_FILE:
            logger.info("📝 WiFi credentials file created")
            self._process_credentials()
    
    def _process_credentials(self):
        """Process WiFi credentials from file"""
        # Wait a moment for file to be fully written
        time.sleep(0.5)
        
        current_hash = self._get_file_hash()
        if current_hash == self.last_hash:
            logger.debug("File hash unchanged, skipping")
            return
        
        self.last_hash = current_hash
        
        credentials = self._read_credentials()
        if not credentials:
            logger.warning("⚠️ No credentials found in file")
            return
        
        ssid = credentials.get('ssid', '')
        password = credentials.get('password', '')
        
        if not ssid or not password:
            logger.warning("⚠️ Invalid credentials (missing SSID or password)")
            return
        
        logger.info(f"📨 Processing WiFi credentials for: {ssid}")
        self._configure_wifi(ssid, password)


def main():
    """Main function"""
    logger.info("🚀 WiFi Credentials File Watcher starting...")
    
    # Create file if it doesn't exist
    Path(WIFI_CREDENTIALS_FILE).touch(exist_ok=True)
    
    # Create event handler
    event_handler = WiFiCredentialsHandler()
    
    # Create observer
    observer = Observer()
    observer.schedule(
        event_handler,
        path=str(Path(WIFI_CREDENTIALS_FILE).parent),
        recursive=False
    )
    
    observer.start()
    logger.info("✅ File watcher started")
    
    try:
        # Process existing file if it has content
        if os.path.getsize(WIFI_CREDENTIALS_FILE) > 0:
            logger.info("📄 Processing existing credentials file...")
            event_handler._process_credentials()
        
        # Keep running
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("🛑 Stopping file watcher...")
        observer.stop()
    
    observer.join()
    logger.info("👋 File watcher stopped")


if __name__ == "__main__":
    main()

