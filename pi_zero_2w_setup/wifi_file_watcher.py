#!/usr/bin/env python3
"""
TR: WiFi kimlik bilgisi dosyası izleyici | EN: WiFi credentials file watcher | RU: Наблюдатель файла учетных данных WiFi
TR: /tmp/wifi_credentials.json dosyasını izleyip WiFi'yi yapılandırır | EN: Monitors /tmp/wifi_credentials.json and configures WiFi | RU: Следит за /tmp/wifi_credentials.json и настраивает WiFi
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
    """TR: WiFi kimlik bilgisi dosya değişikliklerini işle | EN: Handle WiFi credentials file changes | RU: Обрабатывай изменения файла учетных данных WiFi"""
    
    def __init__(self):
        self.last_hash = self._get_file_hash()
        logger.info(f"📁 Watching {WIFI_CREDENTIALS_FILE}")
    
    def _get_file_hash(self):
        """TR: Değişikliği tespit etmek için dosya hash'ini al | EN: Get file hash to detect changes | RU: Получить хеш файла для обнаружения изменений"""
        try:
            if os.path.exists(WIFI_CREDENTIALS_FILE):
                with open(WIFI_CREDENTIALS_FILE, 'r') as f:
                    content = f.read()
                    return hash(content)
        except Exception as e:
            logger.debug(f"Error getting file hash: {e}")
        return None
    
    def _read_credentials(self):
        """TR: WiFi kimlik bilgilerini dosyadan oku | EN: Read WiFi credentials from file | RU: Прочитать учетные данные WiFi из файла"""
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
            logger.error(f"Error reading credentials: {e}")
            return None
    
    def _configure_wifi(self, ssid, password):
        """TR: wpa_supplicant kullanarak WiFi yapılandır | EN: Configure WiFi using wpa_supplicant | RU: Настроить WiFi с помощью wpa_supplicant"""
        try:
            logger.info(f"Configuring WiFi for SSID: {ssid}")
            
            # TR: wpa_supplicant yapılandırmasını oluştur | EN: Create wpa_supplicant configuration | RU: Создай конфиг wpa_supplicant
            config = f"""country=TR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={{
    ssid="{ssid}"
    psk="{password}"
    key_mgmt=WPA-PSK
}}
"""
            # TR: Geçici dosyaya yaz | EN: Write to temporary file | RU: Запиши во временный файл
            temp_config = '/tmp/wpa_supplicant_new.conf'
            with open(temp_config, 'w') as f:
                f.write(config)
            
            # TR: Sisteme sudo ile kopyala | EN: Copy to system location with sudo | RU: Скопируй в системный путь через sudo
            result = subprocess.run(
                ['sudo', 'cp', temp_config, WPA_SUPPLICANT_CONF],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0:
                logger.error(f"Failed to copy config: {result.stderr}")
                return False
            
            # TR: Ağ servislerini yeniden başlat | EN: Restart networking | RU: Перезапусти сетевые службы
            logger.info("Restarting networking...")
            result = subprocess.run(
                ['sudo', 'systemctl', 'restart', 'dhcpcd'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0:
                logger.warning(f"dhcpcd restart warning: {result.stderr}")
            
            # TR: wpa_supplicant'ı da yeniden başlat | EN: Also restart wpa_supplicant | RU: Перезапусти wpa_supplicant
            result = subprocess.run(
                ['sudo', 'systemctl', 'restart', 'wpa_supplicant'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            logger.info("WiFi configuration applied")
            
            # TR: Bekle ve bağlantıyı kontrol et | EN: Wait and check connection | RU: Подожди и проверь подключение
            time.sleep(5)
            if self._check_wifi_connection(ssid):
                logger.info(f"WiFi connected to {ssid}")
                return True
            else:
                logger.warning(f"WiFi connection to {ssid} not confirmed")
                return False
                
        except Exception as e:
            logger.error(f"WiFi configuration error: {e}")
            return False
    
    def _check_wifi_connection(self, ssid):
        """TR: WiFi verilen SSID'ye bağlı mı kontrol et | EN: Check if WiFi is connected to given SSID | RU: Проверить, подключен ли WiFi к данному SSID"""
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
        """TR: Dosya değişikliğini işle | EN: Handle file modification | RU: Обработать изменение файла"""
        if event.src_path == WIFI_CREDENTIALS_FILE:
            logger.info("WiFi credentials file modified")
            self._process_credentials()
    
    def on_created(self, event):
        """TR: Dosya oluşturulmasını işle | EN: Handle file creation | RU: Обработать создание файла"""
        if event.src_path == WIFI_CREDENTIALS_FILE:
            logger.info("WiFi credentials file created")
            self._process_credentials()
    
    def _process_credentials(self):
        """TR: Dosyadan WiFi kimlik bilgilerini işle | EN: Process WiFi credentials from file | RU: Обработать учетные данные WiFi из файла"""
        # Wait a moment for file to be fully written
        time.sleep(0.5)
        
        current_hash = self._get_file_hash()
        if current_hash == self.last_hash:
            logger.debug("File hash unchanged, skipping")
            return
        
        self.last_hash = current_hash
        
        credentials = self._read_credentials()
        if not credentials:
            logger.warning("No credentials found in file")
            return
        
        ssid = credentials.get('ssid', '')
        password = credentials.get('password', '')
        
        if not ssid or not password:
            logger.warning("Invalid credentials (missing SSID or password)")
            return
        
        logger.info(f"Processing WiFi credentials for: {ssid}")
        self._configure_wifi(ssid, password)


def main():
    """TR: Ana fonksiyon | EN: Main function | RU: Главная функция"""
    logger.info("WiFi Credentials File Watcher starting...")
    
    # TR: Dosya yoksa oluştur | EN: Create file if it doesn't exist | RU: Создай файл, если его нет
    Path(WIFI_CREDENTIALS_FILE).touch(exist_ok=True)
    
    # TR: Olay işleyicisini oluştur | EN: Create event handler | RU: Создай обработчик событий
    event_handler = WiFiCredentialsHandler()
    
    # TR: Gözlemciyi oluştur | EN: Create observer | RU: Создай наблюдатель
    observer = Observer()
    observer.schedule(
        event_handler,
        path=str(Path(WIFI_CREDENTIALS_FILE).parent),
        recursive=False
    )
    
    observer.start()
    logger.info("File watcher started")
    
    try:
        # TR: Dosya içerikliyse mevcut dosyayı işle | EN: Process existing file if it has content | RU: Обработай существующий файл, если в нём есть данные
        if os.path.getsize(WIFI_CREDENTIALS_FILE) > 0:
            logger.info("Processing existing credentials file...")
            event_handler._process_credentials()
        
        # TR: Çalışmayı sürdür | EN: Keep running | RU: Продолжай работу
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Stopping file watcher...")
        observer.stop()
    
    observer.join()
    logger.info("File watcher stopped")


if __name__ == "__main__":
    main()

