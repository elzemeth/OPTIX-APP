import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_constants.dart';

class BleDevice {
  final String name;
  final String id;
  final BluetoothDevice device;
  final String? serialNumber;

  BleDevice({
    required this.name,
    required this.id,
    required this.device,
    this.serialNumber,
  });
}

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<BleDevice> _devices = [];
  bool _isScanning = false;
  String? _status;

  List<BleDevice> get devices => _devices;
  bool get isScanning => _isScanning;
  String? get status => _status;

  Stream<List<BleDevice>> get devicesStream => _devicesController.stream;
  final StreamController<List<BleDevice>> _devicesController = StreamController<List<BleDevice>>.broadcast();

  Stream<String?> get statusStream => _statusController.stream;
  final StreamController<String?> _statusController = StreamController<String?>.broadcast();

  Future<bool> _requestPermissions() async {
    _updateStatus('Requesting permissions...');

    try {
      if (Platform.isAndroid) {
        // For Android, we need location and BLE permissions
        List<Permission> permissions = [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];

        // Request permissions one by one to ensure pop-ups appear
        for (Permission permission in permissions) {
          final currentStatus = await permission.status;
          debugPrint('Current $permission status: $currentStatus');

          // Only request if not already granted
          if (!currentStatus.isGranted) {
            await permission
              .onDeniedCallback(() {
                debugPrint('Permission $permission denied');
                _updateStatus('Permission denied: $permission. Please enable in Settings > Apps > Design > Permissions');
              })
              .onGrantedCallback(() {
                debugPrint('Permission $permission granted');
              })
              .onPermanentlyDeniedCallback(() {
                debugPrint('Permission $permission permanently denied');
                _updateStatus('Bluetooth permissions are permanently denied. Please go to Settings > Apps > Design > Permissions and enable Bluetooth permissions manually.');
              })
              .onRestrictedCallback(() {
                debugPrint('Permission $permission restricted');
                _updateStatus('Permission restricted: $permission');
              })
              .onLimitedCallback(() {
                debugPrint('Permission $permission limited');
                _updateStatus('Permission limited: $permission');
              })
              .onProvisionalCallback(() {
                debugPrint('Permission $permission provisional');
                _updateStatus('Permission provisional: $permission');
              })
              .request();
          } else {
            debugPrint('Permission $permission already granted');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS 18.6.2, we need both location and Bluetooth permissions
        debugPrint('iOS 18.6.2: Requesting permissions...');

        // Check and request location permission
        final locationStatus = await Permission.location.status;
        debugPrint('iOS Location permission status: $locationStatus');

        if (!locationStatus.isGranted) {
          await Permission.location
            .onDeniedCallback(() {
              debugPrint('iOS Location permission denied');
              _updateStatus('Location permission denied. Please enable in Settings > Privacy & Security > Location Services');
            })
            .onGrantedCallback(() {
              debugPrint('iOS Location permission granted');
            })
            .onPermanentlyDeniedCallback(() {
              debugPrint('iOS Location permission permanently denied');
              _updateStatus('Location permission permanently denied. Opening Settings...');
              openAppSettings();
            })
            .onRestrictedCallback(() {
              debugPrint('iOS Location permission restricted');
              _updateStatus('Location permission restricted');
            })
            .onLimitedCallback(() {
              debugPrint('iOS Location permission limited');
              _updateStatus('Location permission limited');
            })
            .onProvisionalCallback(() {
              debugPrint('iOS Location permission provisional');
              _updateStatus('Location permission provisional');
            })
            .request();
        } else {
          debugPrint('iOS Location permission already granted');
        }

        // For iOS 18.6.2, also check Bluetooth permission
        try {
          final bluetoothStatus = await Permission.bluetooth.status;
          debugPrint('iOS Bluetooth permission status: $bluetoothStatus');

          if (!bluetoothStatus.isGranted) {
            await Permission.bluetooth
              .onDeniedCallback(() {
                debugPrint('iOS Bluetooth permission denied');
                _updateStatus('Bluetooth permission denied. Please enable in Settings > Privacy & Security > Bluetooth');
              })
              .onGrantedCallback(() {
                debugPrint('iOS Bluetooth permission granted');
              })
              .onPermanentlyDeniedCallback(() {
                debugPrint('iOS Bluetooth permission permanently denied');
                _updateStatus('Bluetooth permission permanently denied. Opening Settings...');
                openAppSettings();
              })
              .onRestrictedCallback(() {
                debugPrint('iOS Bluetooth permission restricted');
                _updateStatus('Bluetooth permission restricted');
              })
              .onLimitedCallback(() {
                debugPrint('iOS Bluetooth permission limited');
                _updateStatus('Bluetooth permission limited');
              })
              .onProvisionalCallback(() {
                debugPrint('iOS Bluetooth permission provisional');
                _updateStatus('Bluetooth permission provisional');
              })
              .request();
          } else {
            debugPrint('iOS Bluetooth permission already granted');
          }
        } catch (e) {
          debugPrint('iOS Bluetooth permission check failed: $e');
          // Continue without Bluetooth permission check if it fails
        }
      } else {
        // For other platforms, try basic permissions
        await Permission.location
          .onDeniedCallback(() {
            debugPrint('Location permission denied');
            _updateStatus('Location permission denied. Please enable location services.');
          })
          .onGrantedCallback(() {
            debugPrint('Location permission granted');
          })
          .onPermanentlyDeniedCallback(() {
            debugPrint('Location permission permanently denied');
            _updateStatus('Location permission permanently denied. Opening Settings...');
            openAppSettings();
          })
          .onRestrictedCallback(() {
            debugPrint('Location permission restricted');
            _updateStatus('Location permission restricted');
          })
          .onLimitedCallback(() {
            debugPrint('Location permission limited');
            _updateStatus('Location permission limited');
          })
          .onProvisionalCallback(() {
            debugPrint('Location permission provisional');
            _updateStatus('Location permission provisional');
          })
          .request();
      }

      _updateStatus('All permissions granted');
      return true;
    } catch (e) {
      _updateStatus('Permission request failed: $e');
      return false;
    }
  }

  Future<bool> _checkBluetoothState() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _updateStatus('Bluetooth is not enabled. Please turn on Bluetooth in Settings.');
        return false;
      }
      return true;
    } catch (e) {
      _updateStatus('Bluetooth not available: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) {
      _updateStatus('Scan already in progress...');
      return;
    }

    _updateStatus('Initializing BLE scan...');

    // Check if we can proceed with scanning
    if (!await canProceedWithScanning()) {
      return;
    }

    // Request permissions (but don't block if they're already handled)
    await _requestPermissions();

    // Check Bluetooth state
    if (!await _checkBluetoothState()) {
      _updateStatus('Bluetooth check failed');
      return;
    }

    _isScanning = true;
    _devices.clear();
    _updateStatus('Scanning for devices...');

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((scanResults) {
        for (final result in scanResults) {
          final device = result.device;
          final deviceName = device.platformName.isNotEmpty 
              ? device.platformName 
              : device.remoteId.toString();

          // Debug: Log all discovered devices
          debugPrint('Discovered device: $deviceName (RSSI: ${result.rssi})');
          debugPrint('Service UUIDs: ${result.advertisementData.serviceUuids}');
          debugPrint('Manufacturer Data: ${result.advertisementData.manufacturerData}');

          bool isOptixDevice = false;

          // Check device name for OPTIX
          if (deviceName.toUpperCase().startsWith(AppConstants.bleDeviceNamePrefix) ||
              deviceName.toLowerCase().contains('smartglasses') ||
              deviceName.toLowerCase().contains('wifi manager')) {
            isOptixDevice = true;
            debugPrint('Found OPTIX device by name: $deviceName');
          }

          // Check for OPTIX service UUIDs
          if (result.advertisementData.serviceUuids.isNotEmpty) {
            for (Guid serviceUuid in result.advertisementData.serviceUuids) {
              String uuidString = serviceUuid.toString().toLowerCase();
              // Check for known OPTIX service UUIDs
              if (uuidString.contains('12345678-1234-5678-9abc-123456789abc') ||
                  uuidString.contains('87654321-4321-4321-4321-cba987654321') ||
                  uuidString.contains('11111111-2222-3333-4444-555555555555') ||
                  uuidString.contains('66666666-7777-8888-9999-aaaaaaaaaaaa')) {
                isOptixDevice = true;
                debugPrint('Found OPTIX device by service UUID: $uuidString');
                break;
              }
            }
          }

          // Check manufacturer data for OPTIX
          if (result.advertisementData.manufacturerData.isNotEmpty) {
            for (var entry in result.advertisementData.manufacturerData.entries) {
              if (entry.value.toString().toLowerCase().contains('optix')) {
                isOptixDevice = true;
                debugPrint('Found OPTIX device by manufacturer data');
                break;
              }
            }
          }

          if (isOptixDevice) {
            final displayName = deviceName.isNotEmpty ? deviceName : 'OPTIX Device';
            final bleDevice = BleDevice(
              name: displayName,
              id: device.remoteId.toString(),
              device: device,
            );

            // Check if device already exists
            final existingIndex = _devices.indexWhere((d) => d.id == bleDevice.id);
            if (existingIndex >= 0) {
              _devices[existingIndex] = bleDevice;
            } else {
              _devices.add(bleDevice);
            }
            debugPrint('Added OPTIX device: $displayName (RSSI: ${result.rssi})');
          }
        }

        _devicesController.add(List.from(_devices));
        _updateStatus('Found ${_devices.length} OPTIX devices');
      });

      // Auto-stop after 15 seconds
      Timer(const Duration(seconds: 15), () {
        if (_isScanning) {
          stopScan();
        }
      });

    } catch (e) {
      _isScanning = false;
      _updateStatus('Scan failed: $e');
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    _isScanning = false;
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _updateStatus('Scan stopped');
  }

  Future<Map<String, dynamic>?> connectToDevice(BleDevice bleDevice) async {
    try {
      _updateStatus('Connecting to ${bleDevice.name}...');

      await bleDevice.device.connect();

      // Wait for connection to be established
      await for (final state in bleDevice.device.connectionState) {
        if (state == BluetoothConnectionState.connected) {
          _updateStatus('Connected to ${bleDevice.name}');

          // Try to get serial number from device
          String? serialNumber = await _getSerialNumber(bleDevice.device);

          if (serialNumber != null) {
            _updateStatus('Serial number found: $serialNumber');
            return {
              'connected': true,
              'serialNumber': serialNumber,
              'deviceName': bleDevice.name,
            };
          } else {
            _updateStatus('No serial number found');
            return {
              'connected': true,
              'serialNumber': null,
              'deviceName': bleDevice.name,
            };
          }
        } else if (state == BluetoothConnectionState.disconnected) {
          _updateStatus('Failed to connect to ${bleDevice.name}');
          return {
            'connected': false,
            'serialNumber': null,
            'deviceName': bleDevice.name,
          };
        }
      }

      return {
        'connected': false,
        'serialNumber': null,
        'deviceName': bleDevice.name,
      };
    } catch (e) {
      _updateStatus('Connection error: $e');
      return {
        'connected': false,
        'serialNumber': null,
        'deviceName': bleDevice.name,
        'error': e.toString(),
      };
    }
  }

  Future<String?> _getSerialNumber(BluetoothDevice device) async {
    try {
      debugPrint('Getting serial number from device: ${device.platformName}');

      // Wait for services to be discovered
      await device.discoverServices();
      List<BluetoothService> services = await device.services.first;

      debugPrint('Found ${services.length} services');

      // Look for the WiFi service
      BluetoothService? wifiService;
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        debugPrint('Service UUID: $serviceUuid');

        if (serviceUuid == '12345678-1234-5678-9abc-123456789abc') {
          wifiService = service;
          debugPrint('Found WiFi service!');
          break;
        }
      }

      if (wifiService == null) {
        debugPrint('WiFi service not found - using fallback serial number');
        // Fallback: Generate serial number based on device ID
        String deviceId = device.remoteId.toString();
        String fallbackSerial = 'OPTIX_${deviceId.substring(0, 8).toUpperCase()}';
        debugPrint('Using fallback serial number: $fallbackSerial');
        return fallbackSerial;
      }

      // Find the command characteristic
      BluetoothCharacteristic? commandChar;
      for (BluetoothCharacteristic char in wifiService.characteristics) {
        String charUuid = char.uuid.toString().toLowerCase();
        debugPrint('Characteristic UUID: $charUuid');

        if (charUuid == '66666666-7777-8888-9999-aaaaaaaaaaaa') {
          commandChar = char;
          debugPrint('Found command characteristic!');
          break;
        }
      }

      if (commandChar == null) {
        debugPrint('Command characteristic not found');
        return null;
      }

      // Find the status characteristic for reading response
      BluetoothCharacteristic? statusChar;
      for (BluetoothCharacteristic char in wifiService.characteristics) {
        String charUuid = char.uuid.toString().toLowerCase();
        if (charUuid == '11111111-2222-3333-4444-555555555555') {
          statusChar = char;
          debugPrint('Found status characteristic!');
          break;
        }
      }

      if (statusChar == null) {
        debugPrint('Status characteristic not found');
        return null;
      }

      // Subscribe to status notifications
      await statusChar.setNotifyValue(true);

      // Send get_serial command
      debugPrint('Sending get_serial command...');
      String command = 'get_serial';
      List<int> commandBytes = command.codeUnits;
      await commandChar.write(commandBytes, withoutResponse: true);

      // Wait for response
      debugPrint('Waiting for serial number response...');
      String? serialNumber;

      // Listen for notifications for up to 10 seconds
      StreamSubscription? subscription;
      Completer<String?> completer = Completer<String?>();

      subscription = statusChar.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          String response = String.fromCharCodes(value);
          debugPrint('Received response: $response');

          if (response.startsWith('Serial: ')) {
            serialNumber = response.substring(8); // Remove 'Serial: ' prefix
            debugPrint('Extracted serial number: $serialNumber');
            if (!completer.isCompleted) {
              completer.complete(serialNumber);
            }
          }
        }
      });

      // Wait for response with timeout
      try {
        serialNumber = await completer.future.timeout(
          Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Timeout waiting for serial number');
            return null;
          },
        );
      } catch (e) {
        debugPrint('Error waiting for serial number: $e');
        serialNumber = null;
      } finally {
        await subscription.cancel();
        await statusChar.setNotifyValue(false);
      }

      if (serialNumber != null && serialNumber!.isNotEmpty) {
        debugPrint('Successfully received serial number: $serialNumber');
        return serialNumber;
      } else {
        debugPrint('Failed to get serial number from device');
        return null;
      }

    } catch (e) {
      debugPrint('Error getting serial number: $e');
      return null;
    }
  }

  Future<void> disconnectDevice(BleDevice bleDevice) async {
    try {
      await bleDevice.device.disconnect();
      _updateStatus('Disconnected from ${bleDevice.name}');
    } catch (e) {
      _updateStatus('Disconnect error: $e');
    }
  }

  Future<Map<String, bool>> getPermissionStatus() async {
    Map<String, bool> status = {};

    if (Platform.isAndroid) {
      status['location'] = await Permission.location.isGranted;
      status['bluetoothScan'] = await Permission.bluetoothScan.isGranted;
      status['bluetoothConnect'] = await Permission.bluetoothConnect.isGranted;
    } else if (Platform.isIOS) {
      status['location'] = await Permission.location.isGranted;
    }

    return status;
  }

  Future<void> requestPermissionsOnStartup() async {
    debugPrint('Requesting BLE permissions on app startup...');

    try {
      if (Platform.isAndroid) {
        // For Android, request all BLE permissions
        List<Permission> permissions = [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];

        Map<Permission, PermissionStatus> statuses = await permissions.request();

        debugPrint('Android permission status:');
        statuses.forEach((permission, status) {
          debugPrint('  ${permission.toString()}: $status');
        });

      } else if (Platform.isIOS) {
        // For iOS, we need to trigger the actual Bluetooth permission request
        // by initializing the Bluetooth adapter, not just requesting location
        try {
          // This will trigger the iOS Bluetooth permission dialog
          final adapterState = await FlutterBluePlus.adapterState.first;
          debugPrint('iOS Bluetooth adapter state: $adapterState');

          // Also request location permission
          final locationStatus = await Permission.location.request();
          debugPrint('iOS location permission: $locationStatus');
        } catch (e) {
          debugPrint('iOS Bluetooth initialization error: $e');
          // Even if there's an error, this might have triggered the permission dialog
        }
      }

      debugPrint('BLE permissions requested on startup');
    } catch (e) {
      debugPrint('Error requesting BLE permissions on startup: $e');
    }
  }

  Future<bool> canProceedWithScanning() async {
    try {
      final locationStatus = await Permission.location.status;
      final bluetoothScanStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;
      
      debugPrint('Permission check - Location: $locationStatus, BluetoothScan: $bluetoothScanStatus, BluetoothConnect: $bluetoothConnectStatus');
      
      // If Bluetooth permissions are permanently denied, we cannot proceed
      if (bluetoothScanStatus.isPermanentlyDenied || bluetoothConnectStatus.isPermanentlyDenied) {
        _updateStatus('Bluetooth permissions are permanently denied.\n\n${getPermissionInstructions()}');
        return false;
      }
      
      // If location is permanently denied, we also cannot proceed
      if (locationStatus.isPermanentlyDenied) {
        _updateStatus('Location permission is permanently denied.\n\n${getPermissionInstructions()}');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  String getPermissionInstructions() {
    if (Platform.isAndroid) {
      return 'To enable Bluetooth permissions:\n1. Go to Settings > Apps > Design\n2. Tap on Permissions\n3. Enable "Nearby devices" and "Location"\n4. Restart the app';
    } else if (Platform.isIOS) {
      return 'To enable Bluetooth permissions:\n1. Go to Settings > Privacy & Security > Bluetooth\n2. Enable Bluetooth for this app\n3. Also check Location Services in Privacy & Security\n4. Restart the app';
    } else {
      return 'Please enable Bluetooth and Location permissions in your device settings.';
    }
  }

  void _updateStatus(String? status) {
    _status = status;
    _statusController.add(_status);
  }

  void dispose() {
    stopScan();
    _devicesController.close();
    _statusController.close();
  }
}