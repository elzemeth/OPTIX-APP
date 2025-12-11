#!/usr/bin/env python3
"""
OPTIX Smart Glasses - Unified Client
WiFi Management, BLE Service, Camera Streaming & Authentication
"""

import json
import logging
import subprocess
import sys
import time
import socket
import tempfile
import os
import shutil
import hashlib
import uuid
import threading
import requests
from dataclasses import dataclass
from typing import Optional, Tuple

import dbus
import dbus.exceptions
import dbus.mainloop.glib
import dbus.service
import requests

try:
    from gi.repository import GLib
    HAS_GLIB = True
except ImportError:
    HAS_GLIB = False
    class SimpleMainLoop:
        def __init__(self):
            self.running = False
        def run(self):
            self.running = True
            try:
                while self.running:
                    time.sleep(0.1)
            except KeyboardInterrupt:
                self.running = False
        def quit(self):
            self.running = False
    class GLib:
        MainLoop = SimpleMainLoop

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [%(name)s] - %(message)s'
)
logger = logging.getLogger('OPTIX')

WIFI_SERVICE_UUID = "12345678-1234-5678-9abc-123456789abc"
CREDENTIAL_CHAR_UUID = "87654321-4321-4321-4321-cba987654321"
STATUS_CHAR_UUID = "11111111-2222-3333-4444-555555555555"
COMMAND_CHAR_UUID = "66666666-7777-8888-9999-aaaaaaaaaaaa"

SUPABASE_URL = "https://naszbfjwwpceujpjvkkc.supabase.co"  # Replace with your Supabase URL
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hc3piZmp3d3BjZXVqcGp2a2tjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzNTM2MDYsImV4cCI6MjA3MDkyOTYwNn0.n2Y1uj4nD39sdo1EJRrpHFDTbGqYl_wdRDTOv2cecJc"  # Replace with your Supabase anon key

BLUEZ_SERVICE_NAME = 'org.bluez'
GATT_MANAGER_IFACE = 'org.bluez.GattManager1'
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
DBUS_PROP_IFACE = 'org.freedesktop.DBus.Properties'
GATT_SERVICE_IFACE = 'org.bluez.GattService1'
GATT_CHRC_IFACE = 'org.bluez.GattCharacteristic1'

DEFAULT_SERVER_HOST = '192.168.1.122'
DEFAULT_SERVER_PORT = 5000
CAMERA_INTERVAL_SEC = 3
HYSTERESIS_HITS = 2

DARK_EXP_US = 12000
DARK_AGAIN = 8.0
SLOW_FPS = 12.0
AF_WINDOW = "0.4,0.4,0.2,0.2"

@dataclass
class Profile:
    name: str
    width: int
    height: int
    quality: int
    shutter_us: Optional[int]
    af_range: str
    af_speed: str
    exposure_mode: str
    denoise: Optional[str]

PROFILE_QUALITY = Profile(
    name="quality", width=4608, height=2592, quality=100,
    shutter_us=None, af_range="normal", af_speed="fast",
    exposure_mode="sport", denoise=None
)
PROFILE_LOWLIGHT = Profile(
    name="lowlight", width=3072, height=1728, quality=92,
    shutter_us=8000, af_range="normal", af_speed="fast",
    exposure_mode="sport", denoise="cdn_fast"
)
PROFILE_MOTION = Profile(
    name="motion", width=3072, height=1728, quality=90,
    shutter_us=4000, af_range="full", af_speed="fast",
    exposure_mode="sport", denoise=None
)

class SystemUtils:
    @staticmethod
    def which(cmd: str) -> Optional[str]:
        return shutil.which(cmd)
    
    @staticmethod
    def get_serial_number() -> str:
        try:
            with open('/proc/cpuinfo', 'r') as f:
                for line in f:
                    if line.startswith('Serial'):
                        return line.split(':')[1].strip()
        except Exception as e:
            logger.error(f"Failed to get serial number: {e}")
        
        try:
            result = subprocess.run(['cat', '/sys/class/net/wlan0/address'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                return result.stdout.strip().replace(':', '')
        except Exception:
            pass
        
        return str(uuid.uuid4()).replace('-', '')[:16]
    
    @staticmethod
    def hash_serial(serial: str) -> str:
        return hashlib.sha256(f"OPTIX-{serial}".encode()).hexdigest()
    
    @staticmethod
    def is_wifi_connected() -> bool:
        try:
            result = subprocess.run(['iwgetid'], capture_output=True, text=True)
            return result.returncode == 0 and result.stdout.strip()
        except Exception:
            return False
    
    @staticmethod
    def get_wifi_networks() -> list:
        try:
            result = subprocess.run(['iwlist', 'wlan0', 'scan'], 
                                  capture_output=True, text=True)
            networks = []
            if result.returncode == 0:
                lines = result.stdout.split('\n')
                for line in lines:
                    if 'ESSID:' in line:
                        ssid = line.split('ESSID:')[1].strip().strip('"')
                        if ssid and ssid != '<hidden>':
                            networks.append(ssid)
            return networks
        except Exception as e:
            logger.error(f"WiFi scan failed: {e}")
            return []

class InvalidArgsException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.freedesktop.DBus.Error.InvalidArgs'

class NotSupportedException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.NotSupported'

class Application(dbus.service.Object):
    def __init__(self, bus, optix_system):
        self.path = '/'
        self.services = []
        self.optix_system = optix_system
        dbus.service.Object.__init__(self, bus, self.path)
        
        wifi_service = WiFiService(bus, 0, optix_system)
        self.add_service(wifi_service)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)

    @dbus.service.method(DBUS_OM_IFACE, out_signature='a{oa{sa{sv}}}')
    def GetManagedObjects(self):
        response = {}
        logger.info(f"📋 GetManagedObjects - {len(self.services)} services")
        
        for service in self.services:
            service_path = service.get_path()
            response[service_path] = service.get_properties()
            logger.info(f"📱 Service: {service.uuid}")
            
            for chrc in service.get_characteristics():
                chrc_path = chrc.get_path()
                response[chrc_path] = chrc.get_properties()
                logger.info(f"🔧 Characteristic: {chrc.uuid}")
        
        return response

class Service(dbus.service.Object):
    PATH_BASE = '/org/bluez/optix/service'

    def __init__(self, bus, index, uuid, primary, optix_system):
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []
        self.optix_system = optix_system
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        return {
            GATT_SERVICE_IFACE: {
                'UUID': self.uuid,
                'Primary': self.primary,
                'Characteristics': dbus.Array(
                    self.get_characteristic_paths(),
                    signature='o')
            }
        }

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_characteristic(self, characteristic):
        self.characteristics.append(characteristic)

    def get_characteristic_paths(self):
        return [chrc.get_path() for chrc in self.characteristics]

    def get_characteristics(self):
        return self.characteristics

class Characteristic(dbus.service.Object):
    def __init__(self, bus, index, uuid, flags, service):
        self.path = service.path + '/char' + str(index)
        self.bus = bus
        self.uuid = uuid
        self.service = service
        self.flags = flags
        self.descriptors = []
        self.value = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_properties(self):
        return {
            GATT_CHRC_IFACE: {
                'Service': self.service.get_path(),
                'UUID': self.uuid,
                'Flags': self.flags,
                'Descriptors': dbus.Array([], signature='o')
            }
        }

    def get_path(self):
        return dbus.ObjectPath(self.path)

    @dbus.service.method(GATT_CHRC_IFACE, in_signature='a{sv}', out_signature='ay')
    def ReadValue(self, options):
        logger.info(f'📖 Read: {self.uuid}')
        return self.value

    @dbus.service.method(GATT_CHRC_IFACE, in_signature='aya{sv}')
    def WriteValue(self, value, options):
        logger.info(f'✍️ Write: {self.uuid}')
        self.value = value

    @dbus.service.method(GATT_CHRC_IFACE)
    def StartNotify(self):
        logger.info(f'🔔 Notify start: {self.uuid}')

    @dbus.service.method(GATT_CHRC_IFACE)
    def StopNotify(self):
        logger.info(f'🔕 Notify stop: {self.uuid}')

class WiFiService(Service):
    def __init__(self, bus, index, optix_system):
        super().__init__(bus, index, WIFI_SERVICE_UUID, True, optix_system)
        logger.info(f"🚀 WiFi Service: {WIFI_SERVICE_UUID}")
        
        self.add_characteristic(CredentialCharacteristic(bus, 0, self))
        status_char = StatusCharacteristic(bus, 1, self)
        self.add_characteristic(status_char)
        self.add_characteristic(CommandCharacteristic(bus, 2, self))
        
        optix_system.status_characteristic = status_char

class CredentialCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        super().__init__(
            bus, index,
            CREDENTIAL_CHAR_UUID,
            ['write', 'write-without-response'],
            service)
        logger.info(f"🔧 Credential: {CREDENTIAL_CHAR_UUID}")

    def WriteValue(self, value, options):
        logger.info('📨 WiFi credentials received')
        try:
            data_str = ''.join([chr(byte) for byte in value])
            credential_data = json.loads(data_str)
            
            ssid = credential_data.get('ssid', '')
            password = credential_data.get('password', '')
            
            logger.info(f'📡 SSID: {ssid}')
            
            # Configure WiFi
            if ssid and password:
                success = self.service.optix_system.configure_wifi(ssid, password)
                if success:
                    logger.info("✅ WiFi configured successfully")
                else:
                    logger.error("❌ WiFi configuration failed")
                    
        except Exception as e:
            logger.error(f'❌ Credential processing error: {e}')

class StatusCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        super().__init__(
            bus, index,
            STATUS_CHAR_UUID,
            ['read', 'notify'],
            service)
        self.status_value = "Ready"
        self.update_value()
        logger.info(f"📊 Status: {STATUS_CHAR_UUID}")

    def update_value(self):
        self.value = [ord(c) for c in self.status_value]

    def ReadValue(self, options):
        wifi_connected = SystemUtils.is_wifi_connected()
        status = "WiFi Connected" if wifi_connected else "WiFi Disconnected"
        self.status_value = status
        self.update_value()
        
        logger.info(f'📖 Status: {self.status_value}')
        return self.value

class CommandCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        super().__init__(
            bus, index,
            COMMAND_CHAR_UUID,
            ['write', 'write-without-response'],
            service)
        logger.info(f"⚡ Command: {COMMAND_CHAR_UUID}")

    def WriteValue(self, value, options):
        logger.info('📨 Command received')
        try:
            data_str = ''.join([chr(byte) for byte in value])
            logger.info(f'🎯 Command: {data_str}')
            
            # Process commands
            if data_str == "scan_wifi":
                networks = SystemUtils.get_wifi_networks()
                logger.info(f"📡 Found {len(networks)} networks")
            elif data_str == "get_serial":
                serial = SystemUtils.get_serial_number()
                logger.info(f"🔢 Serial: {serial}")
                # Send serial back to mobile app
                self.service.optix_system.send_status(f"Serial: {serial}")
            elif data_str.startswith("auth:"):
                # Handle authentication request
                self.service.optix_system.handle_authentication(data_str)
            elif data_str.startswith("register:"):
                # Handle device registration
                self.service.optix_system.handle_registration(data_str)
                
        except Exception as e:
            logger.error(f'❌ Command processing error: {e}')

# =======================
#  CAMERA SYSTEM
# =======================

class CameraSystem:
    def __init__(self):
        self.camera_tool = self.find_camera_tool()
        self.probe_tool = self.find_probe_tool()
        
    def find_camera_tool(self) -> Optional[str]:
        """Find available camera tool"""
        for tool in ('rpicam-still', 'raspistill'):
            if SystemUtils.which(tool):
                logger.info(f"📷 Using camera tool: {tool}")
                return tool
        logger.warning("📷 No camera tools found - camera features disabled")
        return None
    
    def find_probe_tool(self) -> Optional[str]:
        """Find probe tool for metadata"""
        return SystemUtils.which('rpicam-hello')
    
    def probe_environment(self) -> Tuple[float, float, float]:
        """Probe camera environment"""
        if not self.probe_tool:
            return (0.0, 1.0, 0.0)
            
        try:
            cmd = [self.probe_tool, '--timeout', '1200ms',
                   '--metadata', '-', '--metadata-format', 'json', '--nopreview']
            res = subprocess.run(cmd, capture_output=True, timeout=5)
            if res.returncode != 0:
                return (0.0, 1.0, 0.0)
                
            data = json.loads(res.stdout.decode('utf-8') or '[]')
            md = data[0] if isinstance(data, list) and data else {}
            
            exp = md.get('ExposureTime', md.get('Exposure', 0))
            ag = md.get('AnalogueGain', md.get('Ag', 1.0))
            fd = md.get('FrameDuration', 0)
            fps = (1e6/float(fd)) if (isinstance(fd, (int, float)) and fd > 0) else 0.0
            
            return (float(exp or 0), float(ag or 1.0), float(fps))
            
        except Exception as e:
            logger.error(f"📷 Probe error: {e}")
            return (0.0, 1.0, 0.0)
    
    def suggest_profile(self, exp_us: float, again: float, fps: float) -> Profile:
        """Suggest optimal camera profile"""
        if (exp_us >= DARK_EXP_US) or (again >= DARK_AGAIN):
            return PROFILE_LOWLIGHT
        if fps != 0.0 and fps <= SLOW_FPS:
            return PROFILE_MOTION
        return PROFILE_QUALITY
    
    def capture_image(self, profile: Profile) -> Optional[bytes]:
        """Capture image with given profile"""
        if not self.camera_tool:
            logger.debug("📷 No camera available - skipping capture")
            return None
            
        try:
            with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
                tmp_path = tmp.name
            
            # Build command
            cmd = self.build_capture_cmd(tmp_path, profile)
            result = subprocess.run(cmd, capture_output=True, timeout=15)
            
            if result.returncode == 0 and os.path.exists(tmp_path):
                with open(tmp_path, 'rb') as f:
                    data = f.read()
                os.unlink(tmp_path)
                return data
            else:
                logger.error(f"📷 Capture failed: {result.stderr.decode() if result.stderr else 'Unknown error'}")
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
                return None
                
        except Exception as e:
            logger.error(f"📷 Capture error: {e}")
            return None
    
    def build_capture_cmd(self, tmp_path: str, profile: Profile) -> list[str]:
        """Build camera capture command"""
        if self.camera_tool == 'rpicam-still':
            cmd = [
                'rpicam-still',
                '--width', str(profile.width),
                '--height', str(profile.height),
                '--quality', str(profile.quality),
                '--timeout', '1000',
                '--nopreview',
                '--output', tmp_path,
                '--autofocus-mode', 'continuous',
                '--autofocus-range', profile.af_range,
                '--autofocus-speed', profile.af_speed,
                '--autofocus-window', AF_WINDOW,
                '--exposure', profile.exposure_mode,
                '--flicker-period', '10000us'
            ]
            if profile.denoise:
                cmd += ['--denoise', profile.denoise]
            if profile.shutter_us:
                cmd += ['--shutter', f'{profile.shutter_us}us']
            return cmd
        
        # Fallback to raspistill
        return [
            'raspistill',
            '-w', str(profile.width),
            '-h', str(profile.height),
            '-q', str(min(profile.quality, 100)),
            '-t', '1000', '-n', '-o', tmp_path
        ]

# =======================
#  MAIN OPTIX SYSTEM
# =======================

class OptixSystem:
    def __init__(self):
        self.serial_number = SystemUtils.get_serial_number()
        self.device_hash = SystemUtils.hash_serial(self.serial_number)
        self.camera_system = CameraSystem()
        self.ble_active = False
        self.ble_thread = None
        self.streaming_active = False
        self.mainloop = None
        self.status_characteristic = None  # Will be set by BLE service
        
        logger.info(f"🤖 OPTIX System initialized")
        logger.info(f"🔢 Serial: {self.serial_number}")
        logger.info(f"🔐 Hash: {self.device_hash}")
    
    def configure_wifi(self, ssid: str, password: str) -> bool:
        """Configure WiFi connection"""
        try:
            # Create wpa_supplicant configuration
            config = f"""
country=TR
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={{
    ssid="{ssid}"
    psk="{password}"
    key_mgmt=WPA-PSK
}}
"""
            # Write configuration
            with open('/tmp/wpa_supplicant.conf', 'w') as f:
                f.write(config)
            
            # Copy to system location
            subprocess.run(['sudo', 'cp', '/tmp/wpa_supplicant.conf', 
                          '/etc/wpa_supplicant/wpa_supplicant.conf'], check=True)
            
            # Restart networking
            subprocess.run(['sudo', 'systemctl', 'restart', 'dhcpcd'], check=True)
            
            # Wait and check connection
            time.sleep(5)
            if SystemUtils.is_wifi_connected():
                logger.info(f"✅ WiFi connected to {ssid}")
                return True
            else:
                logger.error(f"❌ WiFi connection to {ssid} failed")
                return False
                
        except Exception as e:
            logger.error(f"❌ WiFi configuration error: {e}")
            return False
    
    def handle_authentication(self, auth_data: str):
        """Handle authentication request from mobile app"""
        try:
            # Parse authentication data
            auth_json = auth_data[5:]  # Remove 'auth:' prefix
            auth_info = json.loads(auth_json)
            
            username = auth_info.get('username', '')
            password = auth_info.get('password', '')
            device_serial = auth_info.get('device_serial', '')
            
            logger.info(f"🔐 Authentication request for: {username}")
            
            # Hash the password
            password_hash = SystemUtils.hash_password(password)
            
            # Check against Supabase
            success = self.authenticate_with_supabase(username, password_hash)
            
            if success:
                logger.info(f"✅ Authentication successful for: {username}")
                self.send_status("Authentication Success")
            else:
                logger.warning(f"❌ Authentication failed for: {username}")
                self.send_status("Authentication Failed")
                
        except Exception as e:
            logger.error(f"❌ Authentication error: {e}")
            self.send_status("Authentication Error")
    
    def handle_registration(self, reg_data: str):
        try:
            reg_json = reg_data[9:] 
            reg_info = json.loads(reg_json)
            
            username = reg_info.get('username', '')
            email = reg_info.get('email', '')
            password = reg_info.get('password', '')
            device_serial = reg_info.get('device_serial', '')
            
            logger.info(f"📝 Registration request for: {username}")
            logger.info(f"📧 Email: {email}")
            logger.info(f"📱 Device serial: {device_serial}")
            
            password_hash = SystemUtils.hash_password(password)
            
            success = self.register_with_supabase(username, email, password_hash, device_serial)
            
            if success:
                logger.info(f"✅ Registration successful for: {username}")
                self.send_status("Registration Complete")
            else:
                logger.warning(f"❌ Registration failed for: {username}")
                self.send_status("Registration Failed")
                
        except Exception as e:
            logger.error(f"❌ Registration error: {e}")
            self.send_status("Registration Error")
    
    def authenticate_with_supabase(self, username: str, password_hash: str) -> bool:
        """Authenticate user with Supabase"""
        try:
            headers = {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
                'Content-Type': 'application/json'
            }
            
            url = f"{SUPABASE_URL}/rest/v1/users"
            params = {
                'username': f'eq.{username}',
                'password_hash': f'eq.{password_hash}',
                'select': 'id,username,email,is_active'
            }
            
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                users = response.json()
                if users and len(users) > 0:
                    user = users[0]
                    if user.get('is_active', True):
                        logger.info(f"✅ User authenticated: {user['username']}")
                        return True
                    else:
                        logger.warning(f"❌ User account deactivated: {username}")
                        return False
                else:
                    logger.warning(f"❌ User not found or invalid credentials: {username}")
                    return False
            else:
                logger.error(f"❌ Supabase query failed: {response.status_code}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Supabase authentication error: {e}")
            return False
    
    def register_with_supabase(self, username: str, email: str, password_hash: str, device_serial: str) -> bool:
        """Register user with Supabase"""
        try:
            headers = {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
                'Content-Type': 'application/json'
            }
            
            check_url = f"{SUPABASE_URL}/rest/v1/users"
            check_params = {
                'username': f'eq.{username}',
                'select': 'id'
            }
            
            check_response = requests.get(check_url, headers=headers, params=check_params)
            
            if check_response.status_code == 200:
                existing_users = check_response.json()
                if existing_users and len(existing_users) > 0:
                    logger.warning(f"❌ User already exists: {username}")
                    return False
            
            user_data = {
                'username': username,
                'email': email,
                'password_hash': password_hash,
                'device_id': self.device_hash,
                'device_serial': device_serial,
                'login_method': 'ble',
                'is_active': True,
                'created_at': time.strftime('%Y-%m-%dT%H:%M:%S.%fZ'),
                'updated_at': time.strftime('%Y-%m-%dT%H:%M:%S.%fZ')
            }
            
            create_url = f"{SUPABASE_URL}/rest/v1/users"
            create_response = requests.post(create_url, headers=headers, json=user_data)
            
            if create_response.status_code == 201:
                logger.info(f"✅ User registered successfully: {username}")
                return True
            else:
                logger.error(f"❌ User registration failed: {create_response.status_code} - {create_response.text}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Supabase registration error: {e}")
            return False
    
    def send_status(self, message: str):
        """Send status message back to mobile app"""
        try:
            logger.info(f"📤 Status: {message}")
            
            if hasattr(self, 'status_characteristic') and self.status_characteristic:
                message_bytes = message.encode('utf-8')
                
                # Update the characteristic value
                self.status_characteristic.value = list(message_bytes)
                
                # Notify connected devices
                self.status_characteristic.PropertiesChanged(
                    'org.bluez.GattCharacteristic1',
                    {'Value': dbus.Array(message_bytes, signature='y')},
                    []
                )
                
                logger.info(f"✅ Status sent via BLE: {message}")
            else:
                logger.warning("⚠️ Status characteristic not available")
                
        except Exception as e:
            logger.error(f"❌ Status send error: {e}")
    
    def handle_device_registration(self, command: str):
        try:
            _, data = command.split(':', 1)
            reg_data = json.loads(data)
            
            reg_data['device_id'] = self.device_hash
            reg_data['device_serial'] = self.serial_number
            reg_data['device_type'] = 'OPTIX_GLASSES'
            
            headers = {
                'apikey': SUPABASE_KEY,
                'Authorization': f'Bearer {SUPABASE_KEY}',
                'Content-Type': 'application/json'
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/users",
                json=reg_data,
                headers=headers
            )
            
            if response.status_code in [200, 201]:
                logger.info("✅ Device registered successfully")
            else:
                logger.error(f"❌ Registration failed: {response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Registration error: {e}")
    
    def setup_bluetooth(self) -> bool:
        try:
            logger.info("🔵 Setting up Bluetooth...")
            
            # Reset adapter
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'down'], capture_output=True)
            time.sleep(1)
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'up'], capture_output=True)
            time.sleep(2)
            
            # Set device name
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'name', 'OPTIX'], capture_output=True)
            
            # Make discoverable
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'piscan'], capture_output=True)
            
            # Enable LE advertising
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '0'], capture_output=True)
            time.sleep(1)
            subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '4'], capture_output=True)
            time.sleep(2)
            
            logger.info("✅ Bluetooth configured - Device: OPTIX")
            return True
            
        except Exception as e:
            logger.error(f"❌ Bluetooth setup failed: {e}")
            return False
    
    def start_ble_service(self):
        # If previously marked active but thread died, allow restart
        if self.ble_active and self.ble_thread and self.ble_thread.is_alive():
            return
            
        try:
            logger.info("🚀 Starting BLE service...")
            
            if not self.setup_bluetooth():
                logger.error("❌ Bluetooth setup failed")
                return
            
            # Setup D-Bus
            dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
            bus = dbus.SystemBus()
            
            # Find GATT manager
            adapter = self.find_adapter(bus)
            if not adapter:
                logger.error('❌ No GATT manager found')
                return
            
            # Create and register application
            app = Application(bus, self)
            gatt_manager = dbus.Interface(
                bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                GATT_MANAGER_IFACE)
            
            gatt_manager.RegisterApplication(app.get_path(), {},
                                          reply_handler=self.register_app_cb,
                                          error_handler=self.register_app_error_cb)
            
            self.ble_active = True
            logger.info("✅ BLE service started!")
            
            # Start main loop in thread
            self.mainloop = GLib.MainLoop()
            self.ble_thread = threading.Thread(target=self.mainloop.run)
            self.ble_thread.daemon = True
            self.ble_thread.start()
            
        except Exception as e:
            logger.error(f"❌ BLE service error: {e}")
    
    def stop_ble_service(self):
        if self.mainloop:
            self.mainloop.quit()
        self.ble_active = False
        self.ble_thread = None
        logger.info("🔴 BLE service stopped")
    
    def find_adapter(self, bus):
        try:
            remote_om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, '/'), DBUS_OM_IFACE)
            objects = remote_om.GetManagedObjects()
            
            for o, props in objects.items():
                if GATT_MANAGER_IFACE in props.keys():
                    logger.info(f"📡 GATT adapter: {o}")
                    return o
            
            logger.error("❌ No GATT manager found")
            return None
            
        except Exception as e:
            logger.error(f"❌ Error finding adapter: {e}")
            return None
    
    def register_app_cb(self):
        logger.info('✅ GATT application registered!')
    
    def register_app_error_cb(self, error):
        logger.error(f'❌ GATT registration failed: {error}')
    
    def start_camera_streaming(self, host: str = DEFAULT_SERVER_HOST, port: int = DEFAULT_SERVER_PORT):
        if self.streaming_active:
            return
            
        self.streaming_active = True
        stream_thread = threading.Thread(target=self.camera_stream_loop, args=(host, port))
        stream_thread.daemon = True
        stream_thread.start()
        logger.info(f"📹 Camera streaming started to {host}:{port}")
    
    def camera_stream_loop(self, host: str, port: int):
        last_suggestion = None
        stable_hits = 0
        current_profile = PROFILE_QUALITY
        
        try:
            client_socket = socket.socket()
            client_socket.connect((host, port))
            logger.info("📡 Connected to streaming server!")
            
            image_count = 0
            
            while self.streaming_active:
                exp_us, again, fps = self.camera_system.probe_environment()
                logger.debug(f"📊 exp={exp_us:.0f}us ag={again:.1f} fps~{fps:.1f}")
                
                suggested = self.camera_system.suggest_profile(exp_us, again, fps)
                
                if last_suggestion and suggested.name == last_suggestion:
                    stable_hits += 1
                else:
                    last_suggestion = suggested.name
                    stable_hits = 1
                
                if suggested.name != current_profile.name and stable_hits >= HYSTERESIS_HITS:
                    logger.info(f"🎯 Profile switch: {current_profile.name} -> {suggested.name}")
                    current_profile = suggested
                    stable_hits = 0
                
                image_data = self.camera_system.capture_image(current_profile)
                
                if image_data:
                    try:
                        size = len(image_data)
                        client_socket.sendall(size.to_bytes(4, byteorder='big'))
                        client_socket.sendall(image_data)
                        image_count += 1
                        logger.debug(f"📤 Image #{image_count} ({size} bytes)")
                    except Exception as e:
                        logger.error(f"📤 Send error: {e}")
                        break
                else:
                    logger.warning("📷 Capture failed")
                
                time.sleep(CAMERA_INTERVAL_SEC)
                
        except Exception as e:
            logger.error(f"📡 Streaming error: {e}")
        finally:
            try:
                client_socket.close()
                logger.info("📡 Streaming connection closed")
            except Exception:
                pass
            self.streaming_active = False
    
    def run(self):
        logger.info("🚀 OPTIX Smart Glasses starting...")
        
        logger.info("🔵 Starting BLE service immediately...")
        self.start_ble_service()
        
        try:
            while True:
                # Ensure BLE stays active for reconnects
                if (not self.ble_active) or (self.ble_thread and not self.ble_thread.is_alive()):
                    logger.info("🔄 BLE service down; restarting advertising")
                    self.ble_active = False
                    self.start_ble_service()

                wifi_connected = SystemUtils.is_wifi_connected()
                
                if wifi_connected:
                    logger.info("📶 WiFi connected - Starting camera streaming")
                    if not self.ble_active:
                        self.start_ble_service()
                    
                    if not self.streaming_active:
                        self.start_camera_streaming()
                else:
                    logger.info("📶 WiFi disconnected - BLE service already active")
                    if self.streaming_active:
                        self.streaming_active = False
                
                
                time.sleep(30)
                
        except KeyboardInterrupt:
            logger.info("🛑 Shutting down...")
        except Exception as e:
            logger.error(f"❌ System error: {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        self.streaming_active = False
        if self.ble_active:
            self.stop_ble_service()
        logger.info("🧹 Cleanup completed")

def main():
    logger.info("🚀 OPTIX Smart Glasses - Unified System")
    logger.info("=" * 50)
    
    optix_system = OptixSystem()
    optix_system.run()

if __name__ == "__main__":
    main()
