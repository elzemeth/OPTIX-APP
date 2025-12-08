#!/usr/bin/env python3
"""
OPTIX GATT Server - Clean & Simple
WiFi Management via Bluetooth Low Energy
"""

import json
import logging
import subprocess
import sys
import time
import dbus
import dbus.exceptions
import dbus.mainloop.glib
import dbus.service

# Try to import GLib
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

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# BLE UUIDs
WIFI_SERVICE_UUID = "12345678-1234-5678-9abc-123456789abc"
CREDENTIAL_CHAR_UUID = "87654321-4321-4321-4321-cba987654321"
STATUS_CHAR_UUID = "11111111-2222-3333-4444-555555555555"
COMMAND_CHAR_UUID = "66666666-7777-8888-9999-aaaaaaaaaaaa"

# D-Bus Constants
BLUEZ_SERVICE_NAME = 'org.bluez'
GATT_MANAGER_IFACE = 'org.bluez.GattManager1'
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
DBUS_PROP_IFACE = 'org.freedesktop.DBus.Properties'
GATT_SERVICE_IFACE = 'org.bluez.GattService1'
GATT_CHRC_IFACE = 'org.bluez.GattCharacteristic1'

class InvalidArgsException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.freedesktop.DBus.Error.InvalidArgs'

class NotSupportedException(dbus.exceptions.DBusException):
    _dbus_error_name = 'org.bluez.Error.NotSupported'

class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = '/'
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)
        
        # Add WiFi service
        wifi_service = WiFiService(bus, 0)
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

    def __init__(self, bus, index, uuid, primary):
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []
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

    def get_descriptor_paths(self):
        return []

    def get_descriptors(self):
        return []

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
    def __init__(self, bus, index):
        super().__init__(bus, index, WIFI_SERVICE_UUID, True)
        logger.info(f"🚀 WiFi Service: {WIFI_SERVICE_UUID}")
        
        # Add characteristics
        self.add_characteristic(CredentialCharacteristic(bus, 0, self))
        self.add_characteristic(StatusCharacteristic(bus, 1, self))
        self.add_characteristic(CommandCharacteristic(bus, 2, self))

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
            logger.info(f'📡 SSID: {ssid}')
        except Exception as e:
            logger.error(f'❌ Error: {e}')

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
        except Exception as e:
            logger.error(f'❌ Error: {e}')

def setup_bluetooth():
    """Setup Bluetooth adapter"""
    try:
        logger.info("🔵 Setting up Bluetooth...")
        
        # Reset adapter
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'down'], capture_output=True)
        time.sleep(1)
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'up'], capture_output=True)
        time.sleep(2)
        
        # Set device name
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'name', 'OPTIX'], capture_output=True)
        
        # Make discoverable and pairable
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'piscan'], capture_output=True)
        
        # Enable LE advertising with proper parameters
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '0'], capture_output=True)
        time.sleep(1)
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '3'], capture_output=True)
        time.sleep(2)
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '4'], capture_output=True)
        time.sleep(3)

        # Force device name to be advertised
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'name', 'OPTIX'], capture_output=True)
        subprocess.run(['sudo', 'hciconfig', 'hci0', 'piscan'], capture_output=True)
        
        # Set up service UUID advertising using bluetoothctl
        logger.info("📡 Setting up service UUID advertising...")
        bluetoothctl_commands = f"""
power on
discoverable on
pairable on
advertise on
exit
"""
        
        try:
            subprocess.run(['sudo', 'bluetoothctl'],
                          input=bluetoothctl_commands,
                          text=True,
                          capture_output=True,
                          timeout=10)
            logger.info("✅ Service UUID advertising configured")
        except:
            logger.warning("⚠️ bluetoothctl configuration may have failed")
        
        logger.info("✅ Bluetooth configured - Device: OPTIX")
        return True
        
    except Exception as e:
        logger.error(f"❌ Bluetooth setup failed: {e}")
        return False

def find_adapter(bus):
    """Find GATT manager"""
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

def register_app_cb():
    logger.info('✅ GATT application registered!')
    logger.info('🎯 Ready for connections!')

def register_app_error_cb(error):
    logger.error(f'❌ Registration failed: {error}')

def main():
    """Main function"""
    logger.info("🚀 Starting OPTIX GATT Server...")
    
    # Setup Bluetooth
    if not setup_bluetooth():
        logger.error("❌ Bluetooth setup failed")
        sys.exit(1)
    
    # Setup D-Bus
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    try:
        bus = dbus.SystemBus()
    except Exception as e:
        logger.error(f"❌ D-Bus error: {e}")
        sys.exit(1)
    
    # Find adapter
    adapter = find_adapter(bus)
    if not adapter:
        logger.error('❌ No GATT manager found')
        sys.exit(1)
    
    # Create and register application
    logger.info("📱 Creating GATT application...")
    app = Application(bus)
    
    try:
        gatt_manager = dbus.Interface(
            bus.get_object(BLUEZ_SERVICE_NAME, adapter),
            GATT_MANAGER_IFACE)
        
        logger.info("📝 Registering application...")
        gatt_manager.RegisterApplication(app.get_path(), {},
                                        reply_handler=register_app_cb,
                                        error_handler=register_app_error_cb)
        
        logger.info("🔵 GATT Server started!")
        logger.info(f"📱 Service: {WIFI_SERVICE_UUID}")
        logger.info(f"🔧 Credential: {CREDENTIAL_CHAR_UUID}")
        logger.info(f"📊 Status: {STATUS_CHAR_UUID}")
        logger.info(f"⚡ Command: {COMMAND_CHAR_UUID}")
        logger.info("🎯 Device: OPTIX")
        
        # Set up periodic advertising renewal
        def renew_advertising():
            try:
                logger.info("🔄 Renewing BLE advertising...")
                subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '0'], capture_output=True)
                time.sleep(0.5)
                subprocess.run(['sudo', 'hciconfig', 'hci0', 'name', 'OPTIX'], capture_output=True)
                subprocess.run(['sudo', 'hciconfig', 'hci0', 'piscan'], capture_output=True)
                subprocess.run(['sudo', 'hciconfig', 'hci0', 'leadv', '3'], capture_output=True)
                return True  # Continue periodic calls
            except Exception as e:
                logger.error(f"❌ Advertising renewal failed: {e}")
                return True
        
        # Start advertising renewal timer (every 30 seconds)
        if HAS_GLIB:
            GLib.timeout_add_seconds(30, renew_advertising)
        
        # Start main loop
        mainloop = GLib.MainLoop()
        mainloop.run()
        
    except Exception as e:
        logger.error(f"❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()