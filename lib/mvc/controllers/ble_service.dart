import 'dart:async';
import 'dart:io';
import 'dart:convert';
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

  static const String wifiServiceUuid = '12345678-1234-5678-9abc-123456789abc';
  static const String credentialCharUuid = '87654321-4321-4321-4321-cba987654321';

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final List<BleDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
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
        // TR: Android için konum ve BLE izinleri gerekir | EN: For Android we need location and BLE permissions | RU: Для Android нужны разрешения на локацию и BLE
        List<Permission> permissions = [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];

        // TR: İzin istemlerini açmak için tek tek iste | EN: Request permissions one by one to show pop-ups | RU: Запрашивай разрешения по одному, чтобы появились окна
        for (Permission permission in permissions) {
          final currentStatus = await permission.status;
          debugPrint('Current $permission status: $currentStatus');

          // TR: Sadece verilmemişse iste | EN: Only request if not already granted | RU: Запрашивать только если не выдано
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
        // TR: iOS 18.6.2 için hem konum hem Bluetooth izinleri gerekir | EN: For iOS 18.6.2 we need both location and Bluetooth permissions | RU: Для iOS 18.6.2 нужны разрешения на локацию и Bluetooth
        debugPrint('iOS 18.6.2: Requesting permissions...');

        // TR: Konum iznini kontrol et ve iste | EN: Check and request location permission | RU: Проверить и запросить разрешение на локацию
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

        // TR: iOS 18.6.2 için Bluetooth iznini de kontrol et | EN: For iOS 18.6.2 also check Bluetooth permission | RU: Для iOS 18.6.2 также проверить разрешение Bluetooth
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
          // TR: Kontrol başarısızsa Bluetooth izinsiz devam et | EN: Continue without Bluetooth permission check if it fails | RU: Продолжить без проверки Bluetooth, если она не удалась
        }
      } else {
        // TR: Diğer platformlar için temel izinleri dene | EN: For other platforms try basic permissions | RU: Для прочих платформ запрашивать базовые разрешения
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

    // TR: Tarama yapabilir miyiz kontrol et | EN: Check if we can proceed with scanning | RU: Проверить, можем ли начать сканирование
    if (!await canProceedWithScanning()) {
      return;
    }

    // TR: İzin iste (zaten verildiyse bloklama) | EN: Request permissions without blocking if already handled | RU: Запросить разрешения, не блокируя, если уже выданы
    await _requestPermissions();

    // TR: Bluetooth durumunu kontrol et | EN: Check Bluetooth state | RU: Проверить состояние Bluetooth
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

          // TR: Hata ayıklama: bulunan tüm cihazları logla | EN: Debug: log all discovered devices | RU: Отладка: логировать все найденные устройства
          debugPrint('Discovered device: $deviceName (RSSI: ${result.rssi})');
          debugPrint('  Platform name: ${device.platformName}');
          debugPrint('  Remote ID: ${device.remoteId}');
          debugPrint('  Service UUIDs: ${result.advertisementData.serviceUuids}');
          debugPrint('  Service UUIDs count: ${result.advertisementData.serviceUuids.length}');
          debugPrint('  Manufacturer Data: ${result.advertisementData.manufacturerData}');

          bool isOptixDevice = false;
          String matchReason = '';

          // TR: Cihaz adında OPTIX var mı kontrol et (büyük/küçük harf duyarsız) | EN: Check device name for OPTIX (case insensitive) | RU: Проверить, есть ли OPTIX в имени устройства (без учета регистра)
          final deviceNameUpper = deviceName.toUpperCase();
          final deviceNameLower = deviceName.toLowerCase();
          if (deviceNameUpper.startsWith('OPTIX') ||
              deviceNameUpper.contains('OPTIX') ||
              deviceNameLower.contains('optix') ||
              deviceNameLower.contains('smartglasses') ||
              deviceNameLower.contains('wifi manager')) {
            isOptixDevice = true;
            matchReason = 'name: $deviceName';
            debugPrint('✅ Found OPTIX device by name: $deviceName');
          }

          // TR: OPTIX servis UUID'lerini kontrol et | EN: Check for OPTIX service UUIDs | RU: Проверить сервисные UUID OPTIX
          if (result.advertisementData.serviceUuids.isNotEmpty) {
            debugPrint('  Checking ${result.advertisementData.serviceUuids.length} service UUIDs...');
            for (Guid serviceUuid in result.advertisementData.serviceUuids) {
              final uuidOriginal = serviceUuid.toString();
              final uuidLower = uuidOriginal.toLowerCase();
              final uuidNoDashes = uuidLower.replaceAll('-', '');
              
              debugPrint('    UUID: $uuidOriginal');
              
              // TR: Bilinen OPTIX servis UUID'lerini kontrol et (hem tireli hem tirsiz) | EN: Check for known OPTIX service UUIDs (with and without dashes) | RU: Проверить известные сервисные UUID OPTIX (с дефисами и без)
              final optixServiceUuid = '12345678-1234-5678-9abc-123456789abc';
              final credentialUuid = '87654321-4321-4321-4321-cba987654321';
              final statusUuid = '11111111-2222-3333-4444-555555555555';
              final commandUuid = '66666666-7777-8888-9999-aaaaaaaaaaaa';
              
              // TR: Tüm UUID'ler için hem tireli hem tirsiz versiyonlar oluştur | EN: Create both dashed and non-dashed versions for all UUIDs | RU: Создать версии с дефисами и без для всех UUID
              final optixServiceUuidLower = optixServiceUuid.toLowerCase();
              final optixServiceUuidNoDashes = optixServiceUuidLower.replaceAll('-', '');
              final credentialUuidLower = credentialUuid.toLowerCase();
              final credentialUuidNoDashes = credentialUuidLower.replaceAll('-', '');
              final statusUuidLower = statusUuid.toLowerCase();
              final statusUuidNoDashes = statusUuidLower.replaceAll('-', '');
              final commandUuidLower = commandUuid.toLowerCase();
              final commandUuidNoDashes = commandUuidLower.replaceAll('-', '');
              
              // TR: Tüm UUID'ler için hem tam eşleşme hem içerme kontrolü (tireli ve tirsiz) | EN: Check both exact match and contains for all UUIDs (with and without dashes) | RU: Проверить как точное совпадение, так и содержимое для всех UUID (с дефисами и без)
              if (uuidLower == optixServiceUuidLower ||
                  uuidLower.contains(optixServiceUuidLower) ||
                  uuidNoDashes == optixServiceUuidNoDashes ||
                  uuidNoDashes.contains(optixServiceUuidNoDashes) ||
                  uuidLower == credentialUuidLower ||
                  uuidLower.contains(credentialUuidLower) ||
                  uuidNoDashes == credentialUuidNoDashes ||
                  uuidNoDashes.contains(credentialUuidNoDashes) ||
                  uuidLower == statusUuidLower ||
                  uuidLower.contains(statusUuidLower) ||
                  uuidNoDashes == statusUuidNoDashes ||
                  uuidNoDashes.contains(statusUuidNoDashes) ||
                  uuidLower == commandUuidLower ||
                  uuidLower.contains(commandUuidLower) ||
                  uuidNoDashes == commandUuidNoDashes ||
                  uuidNoDashes.contains(commandUuidNoDashes)) {
                isOptixDevice = true;
                matchReason = 'service UUID: $uuidOriginal';
                debugPrint('✅ Found OPTIX device by service UUID: $uuidOriginal');
                break;
              }
            }
          } else {
            debugPrint('  No service UUIDs in advertisement data');
          }

          // TR: Üretici verilerinde OPTIX var mı bak | EN: Check manufacturer data for OPTIX | RU: Проверить данные производителя на наличие OPTIX
          if (result.advertisementData.manufacturerData.isNotEmpty) {
            for (var entry in result.advertisementData.manufacturerData.entries) {
              if (entry.value.toString().toLowerCase().contains('optix')) {
                isOptixDevice = true;
                matchReason = 'manufacturer data: ${entry.value}';
                debugPrint('✅ Found OPTIX device by manufacturer data: ${entry.value}');
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

            // TR: Cihaz listede var mı kontrol et | EN: Check if device already exists | RU: Проверить, есть ли устройство уже в списке
            final existingIndex = _devices.indexWhere((d) => d.id == bleDevice.id);
            if (existingIndex >= 0) {
              _devices[existingIndex] = bleDevice;
              debugPrint('✅ Updated OPTIX device: $displayName (RSSI: ${result.rssi}) - Matched by: $matchReason');
            } else {
              _devices.add(bleDevice);
              debugPrint('✅ Added OPTIX device: $displayName (RSSI: ${result.rssi}) - Matched by: $matchReason');
            }
          } else {
            debugPrint('❌ Device $deviceName is NOT an OPTIX device (no name/UUID match)');
          }
        }

        _devicesController.add(List.from(_devices));
        _updateStatus('Found ${_devices.length} OPTIX devices');
      });

      // TR: 15 saniye sonra otomatik durdur | EN: Auto-stop after 15 seconds | RU: Автоостановка через 15 секунд
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
    // TR: Paralel bağlantı denemelerini engelle | EN: Prevent parallel connect attempts | RU: Предотвратить параллельные попытки подключения
    if (_isConnecting) {
      debugPrint('Already connecting, skipping new request');
      return null;
    }
    _isConnecting = true;

    try {
      _updateStatus('Connecting to ${bleDevice.name}...');

      // TR: Bağlanmadan önce taramayı durdur (iOS pairing popup tekrarlarını azaltır) | EN: Stop scan before connecting (reduces repeated iOS pairing popups) | RU: Остановить сканирование перед подключением (уменьшает повторные окна сопряжения iOS)
      if (_isScanning) {
        await stopScan();
      }

      // TR: Mevcut bağlantı durumunu kontrol et | EN: Check current connection state | RU: Проверить текущее состояние подключения
      final currentState = await bleDevice.device.connectionState.first;
      if (currentState == BluetoothConnectionState.connected) {
        debugPrint('Device already connected');
        // TR: Zaten bağlıysa seri numara al | EN: If already connected, get serial number | RU: Если уже подключено, получить серийный номер
        String? serialNumber = await _getSerialNumber(bleDevice.device);
        return {
          'connected': true,
          'serialNumber': serialNumber,
          'deviceName': bleDevice.name,
        };
      }

      // TR: Bağlanmayı dene (pairing olmadan) | EN: Try to connect (without pairing) | RU: Попробовать подключиться (без сопряжения)
      // TR: autoConnect: false - Otomatik yeniden bağlanmayı engelle | EN: autoConnect: false - Prevent auto-reconnect | RU: autoConnect: false - Предотвратить автоматическое переподключение
      await bleDevice.device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // TR: Bağlantının kurulmasını bekle (timeout ile) | EN: Wait for connection with timeout | RU: Ждать подключения с таймаутом
      BluetoothConnectionState? finalState;
      await for (final state in bleDevice.device.connectionState.timeout(const Duration(seconds: 15))) {
        finalState = state;
        if (state == BluetoothConnectionState.connected) {
          break;
        } else if (state == BluetoothConnectionState.disconnected) {
          _updateStatus('Failed to connect to ${bleDevice.name}');
          return {
            'connected': false,
            'serialNumber': null,
            'deviceName': bleDevice.name,
          };
        }
      }

      if (finalState == BluetoothConnectionState.connected) {
        _updateStatus('Connected to ${bleDevice.name}');
        
        // TR: Bağlantı kurulduktan sonra servislerin hazır olması için bekle | EN: Wait for services to be ready after connection | RU: Ждать готовности сервисов после подключения
        debugPrint('Waiting for services to be ready...');
        await Future.delayed(const Duration(seconds: 2));

        // TR: Cihazdan seri numara almaya çalış | EN: Try to get serial number from device | RU: Попробовать получить серийный номер с устройства
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
      }

      _updateStatus('Connection timeout');
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
    } finally {
      _isConnecting = false;
    }
  }

  Future<String?> _getSerialNumber(BluetoothDevice device) async {
    try {
      debugPrint('Getting serial number from device: ${device.platformName}');

      // TR: Servislerin bulunmasını bekle (retry ile) | EN: Wait for services to be discovered (with retry) | RU: Ждать обнаружения сервисов (с повторными попытками)
      List<BluetoothService> services = [];
      int retryCount = 0;
      const maxRetries = 5;
      
      while (services.isEmpty && retryCount < maxRetries) {
        try {
          await device.discoverServices();
          services = await device.services.first;
          debugPrint('Found ${services.length} services (attempt ${retryCount + 1})');
          
          if (services.isEmpty) {
            retryCount++;
            if (retryCount < maxRetries) {
              debugPrint('No services found, retrying in 1 second...');
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } catch (e) {
          debugPrint('Service discovery error (attempt ${retryCount + 1}): $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (services.isEmpty) {
        debugPrint('WiFi service not found after $maxRetries attempts - using fallback serial number');
        String deviceId = device.remoteId.toString();
        String fallbackSerial = 'OPTIX_${deviceId.substring(0, 8).toUpperCase()}';
        debugPrint('Using fallback serial number: $fallbackSerial');
        return fallbackSerial;
      }

      debugPrint('Found ${services.length} services');

      // TR: WiFi servisini ara | EN: Look for the WiFi service | RU: Искать сервис WiFi
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
        debugPrint('WiFi service not found after discovery');
        // TR: Yedek: cihaz kimliğinden seri numarası üret | EN: Fallback: generate serial from device ID | RU: Резерв: сгенерировать серийный номер из ID устройства
        String deviceId = device.remoteId.toString();
        String fallbackSerial = 'OPTIX_${deviceId.substring(0, 8).toUpperCase()}';
        debugPrint('Using fallback serial number: $fallbackSerial');
        return fallbackSerial;
      }

      // TR: Komut karakteristiğini bul | EN: Find the command characteristic | RU: Найти характеристику команды
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

      // TR: Yanıt okumak için durum karakteristiğini bul | EN: Find status characteristic for reading response | RU: Найти характеристику статуса для чтения ответа
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

      // TR: Durum bildirimlerine abone ol | EN: Subscribe to status notifications | RU: Подписаться на уведомления статуса
      await statusChar.setNotifyValue(true);

      // TR: get_serial komutunu gönder | EN: Send get_serial command | RU: Отправить команду get_serial
      debugPrint('Sending get_serial command...');
      String command = 'get_serial';
      List<int> commandBytes = command.codeUnits;
      await commandChar.write(commandBytes, withoutResponse: true);

      // TR: Yanıtı bekle | EN: Wait for response | RU: Ждать ответа
      debugPrint('Waiting for serial number response...');
      String? serialNumber;

      // TR: 10 saniyeye kadar bildirimleri dinle | EN: Listen for notifications up to 10 seconds | RU: Слушать уведомления до 10 секунд
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

      // TR: Zaman aşımıyla yanıt bekle | EN: Wait for response with timeout | RU: Ждать ответ с тайм-аутом
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

  Future<bool> sendWifiCredentials(BleDevice bleDevice, String ssid, String password) async {
    try {
      // TR: Cihazın bağlı olduğunu kontrol et | EN: Check if device is connected | RU: Проверить, подключено ли устройство
      final connectionState = await bleDevice.device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        debugPrint('Device is not connected. Current state: $connectionState');
        // TR: Bağlantıyı tekrar dene | EN: Try to reconnect | RU: Попробовать переподключиться
        await bleDevice.device.connect(timeout: const Duration(seconds: 10));
        // TR: Bağlantının kurulmasını bekle | EN: Wait for connection | RU: Ждать подключения
        await for (final state in bleDevice.device.connectionState.timeout(const Duration(seconds: 10))) {
          if (state == BluetoothConnectionState.connected) {
            break;
          } else if (state == BluetoothConnectionState.disconnected) {
            debugPrint('Failed to reconnect to device');
            return false;
          }
        }
      }
      
      // TR: Servislerin keşfedilmesini bekle (retry ile) | EN: Wait for services to be discovered (with retry) | RU: Ждать обнаружения сервисов (с повторными попытками)
      List<BluetoothService> services = [];
      int retryCount = 0;
      const maxRetries = 5;
      
      while (services.isEmpty && retryCount < maxRetries) {
        try {
          await bleDevice.device.discoverServices();
          services = await bleDevice.device.services.first;
          debugPrint('Found ${services.length} services for WiFi (attempt ${retryCount + 1})');
          
          if (services.isEmpty) {
            retryCount++;
            if (retryCount < maxRetries) {
              debugPrint('No services found, retrying in 1 second...');
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } catch (e) {
          debugPrint('Service discovery error (attempt ${retryCount + 1}): $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      if (services.isEmpty) {
        debugPrint('WiFi service not found after $maxRetries attempts');
        return false;
      }

      BluetoothService? wifiService;
      for (final s in services) {
        if (s.uuid.toString().toLowerCase() == wifiServiceUuid) {
          wifiService = s;
          break;
        }
      }

      if (wifiService == null) {
        debugPrint('WiFi service not found on device');
        return false;
      }

      BluetoothCharacteristic? credChar;
      for (final c in wifiService.characteristics) {
        if (c.uuid.toString().toLowerCase() == credentialCharUuid) {
          credChar = c;
          break;
        }
      }

      if (credChar == null) {
        debugPrint('Credential characteristic not found');
        return false;
      }

      final payload = jsonEncode({'ssid': ssid, 'password': password});
      await credChar.write(utf8.encode(payload), withoutResponse: false);
      debugPrint('WiFi credentials sent');
      return true;
    } catch (e) {
      debugPrint('Error sending WiFi credentials: $e');
      return false;
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
        // TR: Android için tüm BLE izinlerini iste | EN: For Android request all BLE permissions | RU: Для Android запросить все разрешения BLE
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
        // TR: iOS'ta Bluetooth iznini tetiklemek için adaptörü başlatmak gerekir
        // EN: On iOS we must trigger Bluetooth permission by initializing the adapter
        // RU: На iOS нужно вызвать запрос Bluetooth, инициализируя адаптер
        try {
          // TR: Bu, iOS Bluetooth izin penceresini açar | EN: This triggers the iOS Bluetooth permission dialog | RU: Это вызывает диалог разрешения Bluetooth на iOS
          final adapterState = await FlutterBluePlus.adapterState.first;
          debugPrint('iOS Bluetooth adapter state: $adapterState');

          // TR: Ayrıca konum izni iste | EN: Also request location permission | RU: Также запросить разрешение на локацию
          final locationStatus = await Permission.location.request();
          debugPrint('iOS location permission: $locationStatus');
        } catch (e) {
          debugPrint('iOS Bluetooth initialization error: $e');
          // TR: Hata olsa bile izin penceresini tetiklemiş olabilir | EN: Even on error this may have triggered the permission dialog | RU: Даже при ошибке это могло вызвать диалог разрешений
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
      
      // TR: Bluetooth izinleri kalıcı reddedildiyse devam edemeyiz | EN: If Bluetooth permissions are permanently denied, we cannot proceed | RU: Если разрешения Bluetooth навсегда отклонены, продолжать нельзя
      if (bluetoothScanStatus.isPermanentlyDenied || bluetoothConnectStatus.isPermanentlyDenied) {
        _updateStatus('Bluetooth permissions are permanently denied.\n\n${getPermissionInstructions()}');
        return false;
      }
      
      // TR: Konum izni kalıcı reddedildiyse devam edemeyiz | EN: If location is permanently denied, we also cannot proceed | RU: Если локация навсегда отклонена, тоже нельзя продолжать
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