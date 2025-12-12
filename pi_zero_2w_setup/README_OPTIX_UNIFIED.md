# OPTIX Smart Glasses - Unified System

Bu sistem, Raspberry Pi Zero 2W üzerinde çalışan akıllı gözlük yazılımıdır. WiFi bağlantısı olmadığında BLE servisini açar, bağlantı olduğunda ise kamera streaming yapar.

## Özellikler

### Akıllı Bağlantı Yönetimi
- **WiFi Bağlı**: Kamera streaming moduna geçer
- **WiFi Yok**: BLE servisini başlatır ve WiFi konfigürasyonu bekler

### BLE (Bluetooth Low Energy) Servisi
- Flutter uygulamasıyla uyumlu UUID'ler
- WiFi credential'ları güvenli şekilde alır
- Device registration ve authentication
- Real-time status reporting

### Akıllı Kamera Sistemi
- **3 Profil**: Quality, Lowlight, Motion
- **Otomatik Profil Seçimi**: Işık ve hareket durumuna göre
- **Hysteresis**: Profil değişimlerinde kararlılık
- **Streaming**: TCP socket üzerinden görüntü gönderimi

### Güvenlik
- Device serial number hashing
- Supabase entegrasyonu
- Encrypted credential transmission

## Gereksinimler

### Donanım
- Raspberry Pi Zero 2W
- Pi Camera (v1, v2 veya HQ)
- MicroSD kart (16GB+)
- WiFi bağlantısı

### Yazılım
- Raspberry Pi OS (Bullseye veya üzeri)
- Python 3.9+
- Bluetooth enabled

## Kurulum

### 1. Dosyaları Kopyala
```bash
# Pi'ye SSH ile bağlan
ssh pi@192.168.1.XXX

# Dosyaları kopyala (scp ile)
scp optix_smart_glasses.py pi@192.168.1.XXX:~/
scp install_optix_unified.sh pi@192.168.1.XXX:~/
```

### 2. Kurulumu Çalıştır
```bash
chmod +x install_optix_unified.sh
./install_optix_unified.sh
```

### 3. Konfigürasyon
```bash
cd ~/optix
nano config.json
```

**config.json örneği:**
```json
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
```

### 4. Test Et
```bash
cd ~/optix
./test_system.py
```

### 5. Servisi Başlat
```bash
./start.sh
```

## Kullanım

### Servis Yönetimi
```bash
cd ~/optix

# Status kontrol et
./status.sh

# Servisi başlat
./start.sh

# Servisi durdur
./stop.sh

# Servisi yeniden başlat
./restart.sh
```

### Log İzleme
```bash
# Real-time log izleme
sudo journalctl -u optix-glasses.service -f

# Son 50 log satırı
sudo journalctl -u optix-glasses.service -n 50
```

### Manuel Çalıştırma (Debug için)
```bash
cd ~/optix
python3 optix_smart_glasses.py
```

## Flutter App Entegrasyonu

### BLE Bağlantı Süreci
1. **Scan**: Flutter app OPTIX cihazını arar
2. **Connect**: Cihaza bağlanır
3. **Authenticate**: Serial number hash'i ile authentication
4. **Configure**: WiFi credential'ları gönderir
5. **Monitor**: Status güncellemelerini alır

### Characteristic'ler
- **Credential** (`87654321-4321-4321-4321-cba987654321`): WiFi credentials
- **Status** (`11111111-2222-3333-4444-555555555555`): Device status
- **Command** (`66666666-7777-8888-9999-aaaaaaaaaaaa`): Commands

## Kamera Profilleri

### Quality Profile
- **Resolution**: 4608x2592
- **Quality**: 95%
- **Use Case**: İyi ışık, statik sahneler

### Lowlight Profile  
- **Resolution**: 3072x1728
- **Quality**: 92%
- **Shutter**: 8000µs
- **Denoise**: cdn_fast
- **Use Case**: Düşük ışık

### Motion Profile
- **Resolution**: 3072x1728  
- **Quality**: 90%
- **Shutter**: 4000µs
- **AF Range**: full
- **Use Case**: Hareket, hızlı sahneler

## 🐛 Troubleshooting

### BLE Servisi Başlamıyor
```bash
# Bluetooth status kontrol
sudo systemctl status bluetooth

# Bluetooth restart
sudo systemctl restart bluetooth

# HCI interface kontrol
sudo hciconfig hci0
```

### Kamera Çalışmıyor
```bash
# Kamera enable kontrol
vcgencmd get_camera

# Kamera test
rpicam-hello --timeout 2000

# Config kontrol
sudo raspi-config
```

### WiFi Bağlanamıyor
```bash
# WiFi status
iwgetid

# Available networks
iwlist wlan0 scan | grep ESSID

# wpa_supplicant config
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
```

### Servis Crash Oluyor
```bash
# Detaylı log
sudo journalctl -u optix-glasses.service -n 100

# Python path kontrol
which python3
pip3 list | grep -E "(requests|dbus|PyGObject)"
```

## Monitoring

### System Status
```bash
# CPU ve Memory kullanımı
htop

# Disk kullanımı  
df -h

# Temperature
vcgencmd measure_temp
```

### Network Status
```bash
# WiFi signal strength
iwconfig wlan0

# Network connections
netstat -an

# Ping test
ping google.com
```

## Otomatik Güncellemeler

Sistem otomatik olarak:
- WiFi durumunu kontrol eder (30s interval)
- BLE advertising'i yeniler (30s interval)  
- Kamera profili optimize eder (her frame)
- Connection durumunu monitor eder

## Güvenlik Notları

1. **Serial Number**: Device identification için hash'lenir
2. **WiFi Credentials**: BLE üzerinden encrypted gönderilir
3. **Supabase**: JWT token authentication
4. **Local Storage**: Sensitive data cache'lenmez

## 📞 Destek

Sorun yaşarsanız:
1. `./status.sh` ile durumu kontrol edin
2. Log'ları inceleyin: `sudo journalctl -u optix-glasses.service -f`
3. Test script'i çalıştırın: `./test_system.py`
4. Gerekirse manual debug: `python3 optix_smart_glasses.py`

---

**OPTIX Smart Glasses - Akıllı, Güvenli, Güçlü!**
