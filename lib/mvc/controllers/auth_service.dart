import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'storage.dart';
import '../models/user.dart';
import 'utils/serial_hash.dart';
import 'supabase.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static User? _currentUser;
  static String? _userSerialHash;
  
  static User? get currentUser => _currentUser;
  static String? get userSerialHash => _userSerialHash;

  /// TR: Cihazın başka bir hesaba bağlı olup olmadığını kontrol eder | EN: Check if device is linked to another account | RU: Проверяет, подключено ли устройство к другой учетной записи
  Future<bool> isDeviceConnectedToAnotherAccount(String deviceId) async {
    try {
      final response = await SupabaseService().client
          .from('users')
          .select('id, username')
          .eq('device_id', deviceId)
          .eq('is_active', true);
      
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        final existingUser = responseList.first;
        // TR: Geçerli kullanıcı değil mi kontrol et | EN: Check if not current user | RU: Проверить, что это не текущий пользователь
        if (_currentUser == null || existingUser['id'] != _currentUser!.id) {
          debugPrint('Device $deviceId is already connected to user: ${existingUser['username']}');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking device connection: $e');
      return false;
    }
  }

  /// TR: Cihazı mevcut kullanıcı hesabına bağlar | EN: Connect device to current user | RU: Подключает устройство к текущей учетной записи
  Future<bool> connectDevice(String deviceId, String deviceName, String deviceMacAddress) async {
    try {
      if (_currentUser == null) {
        debugPrint('No current user to connect device to');
        return false;
      }

      // TR: Cihaz başka hesaba bağlı mı kontrol et | EN: Check if device is linked to another account | RU: Проверить, привязано ли устройство к другой учетной записи
      if (await isDeviceConnectedToAnotherAccount(deviceId)) {
        debugPrint('Device is already connected to another account');
        return false;
      }

      // TR: Kullanıcıyı cihaz bilgileriyle güncelle | EN: Update user with device info | RU: Обновить пользователя данными устройства
      final response = await SupabaseService().client
          .from('users')
          .update({
            'device_id': deviceId,
            'device_name': deviceName,
            'device_mac_address': deviceMacAddress,
            'is_ble_registered': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      debugPrint('Device connection response: $response');
      
      // TR: Yerel kullanıcı verisini güncelle | EN: Update local user data | RU: Обновить локальные данные пользователя
      _currentUser = _currentUser!.copyWith(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceMacAddress: deviceMacAddress,
        isBleRegistered: true,
        updatedAt: DateTime.now(),
      );
      
      // TR: Güncellenmiş kullanıcı verisini kaydet | EN: Save updated user data | RU: Сохранить обновленные данные пользователя
      await Storage.setUserData(_currentUser!.toJson());
      
      debugPrint('Device connected successfully to user: ${_currentUser!.username}');
      return true;
    } catch (e) {
      debugPrint('Error connecting device: $e');
      return false;
    }
  }

  /// TR: Cihazı mevcut kullanıcıdan ayırır | EN: Disconnect device from current user | RU: Отключает устройство от текущего пользователя
  Future<bool> disconnectDevice() async {
    try {
      if (_currentUser == null) {
        debugPrint('No current user to disconnect device from');
        return false;
      }

      // TR: Kullanıcıdan cihaz bilgilerini temizle | EN: Clear device info from user | RU: Очистить данные устройства у пользователя
      final response = await SupabaseService().client
          .from('users')
          .update({
            'device_id': null,
            'device_name': null,
            'device_mac_address': null,
            'is_ble_registered': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      debugPrint('Device disconnection response: $response');
      
      // TR: Yerel kullanıcı verisini güncelle | EN: Update local user data | RU: Обновить локальные данные пользователя
      _currentUser = _currentUser!.copyWith(
        deviceId: null,
        deviceName: null,
        deviceMacAddress: null,
        isBleRegistered: false,
        updatedAt: DateTime.now(),
      );
      
      // TR: Güncellenmiş kullanıcı verisini kaydet | EN: Save updated user data | RU: Сохранить обновленные данные пользователя
      await Storage.setUserData(_currentUser!.toJson());
      
      debugPrint('Device disconnected successfully from user: ${_currentUser!.username}');
      return true;
    } catch (e) {
      debugPrint('Error disconnecting device: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      // TR: Şifreyi hashle | EN: Hash the password | RU: Хэшировать пароль
      final passwordHash = hashPassword(password);
      
      // TR: Kullanıcı için veritabanını sorgula | EN: Query database for user | RU: Выполнить запрос пользователя в базе
      final response = await SupabaseService().client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password_hash', passwordHash)
          .eq('is_active', true);
      
      // TR: PostgrestList'i List<Map<String, dynamic>> biçimine çevir | EN: Convert PostgrestList to List<Map<String, dynamic>> | RU: Преобразовать PostgrestList в List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        _currentUser = User.fromJson(responseList.first);
        await Storage.setLoggedIn(true);
        await Storage.setUserData(_currentUser!.toJson());
        
        // TR: Kullanıcının seri numara hash'i var mı kontrol et (BLE bağlantısından) | EN: Check if user has serial hash from BLE | RU: Проверить, есть ли у пользователя хэш серийного номера из BLE
        final serialHash = getSerialHash();
        if (serialHash != null) {
          // TR: Cihazı bu kullanıcı hesabına bağlamayı dene | EN: Try to connect device to this account | RU: Попробовать привязать устройство к этой учетной записи
          await connectDevice(serialHash, 'OPTIX Device', '');
        }
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signUp(String username, String email, String password) async {
    try {
      debugPrint('AuthService: Starting signup for $username');
      
      // TR: Kullanıcı zaten var mı kontrol et | EN: Check if user already exists | RU: Проверить, существует ли пользователь
      debugPrint('AuthService: Checking if user exists...');
      final existingUser = await SupabaseService().client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      
      if (existingUser != null) {
        debugPrint('AuthService: User already exists');
        return false; // User already exists
      }
      
      // TR: E-posta zaten var mı kontrol et | EN: Check if email already exists | RU: Проверить, существует ли email
      final existingEmail = await SupabaseService().client
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      if (existingEmail != null) {
        debugPrint('AuthService: Email already exists');
        return false; // Email already exists
      }
      
      debugPrint('AuthService: User does not exist, proceeding with signup');
      
      // TR: Şifreyi hashle | EN: Hash the password | RU: Хэшировать пароль
      final passwordHash = hashPassword(password);
      debugPrint('AuthService: Password hashed');
      
      // TR: Yeni kullanıcı oluştur | EN: Create new user | RU: Создать нового пользователя
      debugPrint('AuthService: Creating user in database...');
      final response = await SupabaseService().client
          .from('users')
          .insert({
            'username': username,
            'email': email,
            'password_hash': passwordHash,
            'login_method': 'credentials',
            'is_active': true,
            'is_verified': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select();
      
      debugPrint('AuthService: Database response: $response');
      debugPrint('AuthService: Response type: ${response.runtimeType}');
      
      // TR: PostgrestList'i List<Map<String, dynamic>> biçimine çevir | EN: Convert PostgrestList to List<Map<String, dynamic>> | RU: Преобразовать PostgrestList в List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        final userData = responseList.first;
        debugPrint('AuthService: User data: $userData');
        debugPrint('AuthService: User data type: ${userData.runtimeType}');
        debugPrint('AuthService: User data keys: ${userData.keys.toList()}');
        
        try {
          _currentUser = User.fromJson(userData);
          debugPrint('AuthService: User created successfully');
        } catch (e) {
          debugPrint('AuthService: Error creating User from JSON: $e');
          debugPrint('AuthService: User data that failed: $userData');
          rethrow;
        }
        await Storage.setLoggedIn(true);
        await Storage.setUserData(_currentUser!.toJson());
        
        // TR: Kullanıcının seri numara hash'i var mı kontrol et (BLE bağlantısından) | EN: Check if user has serial hash from BLE | RU: Проверить, есть ли у пользователя хэш серийного номера из BLE
        final serialHash = getSerialHash();
        if (serialHash != null) {
          // TR: Cihazı bu yeni kullanıcıya bağlamayı dene | EN: Try to connect device to this new user | RU: Попробовать привязать устройство к этому новому пользователю
          await connectDevice(serialHash, 'OPTIX Device', '');
        }
        
        debugPrint('AuthService: User created and stored successfully');
        return true;
      }
      debugPrint('AuthService: Response was empty or invalid');
      return false;
    } catch (e) {
      debugPrint('AuthService: Signup error: $e');
      return false;
    }
  }

  Future<bool> loginWithBLE(String deviceId, String deviceName, String deviceMacAddress) async {
    try {
      // TR: Bu BLE cihazıyla kullanıcı ara | EN: Look for user with this BLE device | RU: Найти пользователя с этим BLE устройством
      final response = await SupabaseService().client
          .from('users')
          .select()
          .eq('device_id', deviceId)
          .eq('is_active', true);
      
      // TR: PostgrestList'i List<Map<String, dynamic>> biçimine çevir | EN: Convert PostgrestList to List<Map<String, dynamic>> | RU: Преобразовать PostgrestList в List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        _currentUser = User.fromJson(responseList.first);
        await Storage.setLoggedIn(true);
        await Storage.setUserData(_currentUser!.toJson());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('BLE login error: $e');
      return false;
    }
  }

  Future<bool> registerBLE(String username, String email, String deviceId, String deviceName, String deviceMacAddress) async {
    try {
      // TR: Kullanıcı zaten var mı kontrol et | EN: Check if user already exists | RU: Проверить, существует ли пользователь
      final existingUser = await SupabaseService().client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      
      if (existingUser != null) {
        return false; // User already exists
      }
      
      // TR: BLE cihazıyla yeni kullanıcı oluştur | EN: Create new user with BLE device | RU: Создать нового пользователя с BLE устройством
      final response = await SupabaseService().client
          .from('users')
          .insert({
            'username': username,
            'email': email,
            'device_id': deviceId,
            'device_name': deviceName,
            'device_mac_address': deviceMacAddress,
            'login_method': 'ble',
            'is_active': true,
            'is_verified': false,
            'is_ble_registered': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select();
      
      // TR: PostgrestList'i List<Map<String, dynamic>> biçimine çevir | EN: Convert PostgrestList to List<Map<String, dynamic>> | RU: Преобразовать PostgrestList в List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        _currentUser = User.fromJson(responseList.first);
        await Storage.setLoggedIn(true);
        await Storage.setUserData(_currentUser!.toJson());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('BLE registration error: $e');
      return false;
    }
  }

  Future<void> loginSucceeded() async {
    await Storage.setLoggedIn(true);
    if (_currentUser != null) {
      await Storage.setUserData(_currentUser!.toJson());
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _userSerialHash = null;
    await Storage.clear();
  }
  
  /// TR: Mevcut kullanıcı için seri numara hash'i ayarlar | EN: Set serial number hash for current user | RU: Устанавливает хэш серийного номера для текущего пользователя
  Future<void> setSerialNumber(String serialNumber) async {
    _userSerialHash = SerialHash.createHash(serialNumber);
    await Storage.setString('user_serial_hash', _userSerialHash!);
  }
  
  /// TR: Mevcut kullanıcının seri numara hash'ini getirir | EN: Get serial number hash for current user | RU: Возвращает хэш серийного номера текущего пользователя
  String? getSerialHash() {
    return _userSerialHash;
  }
  
  /// TR: Verilen seri numara ile kullanıcı var mı kontrol eder | EN: Check if user exists with given serial | RU: Проверяет, есть ли пользователь с указанным серийным номером
  Future<bool> userExistsBySerial(String serialNumber) async {
    try {
      final serialHash = SerialHash.createHash(serialNumber);
      final response = await SupabaseService().client
          .from('users')
          .select('id')
          .eq('device_id', serialHash)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }
  
  /// TR: Kullanıcıya ait sonuçları getirir | EN: Get user results | RU: Получает результаты пользователя
  Future<List<Map<String, dynamic>>> getUserResults() async {
    if (_currentUser == null) return [];
    
    try {
      final response = await SupabaseService().client
          .from('results')
          .select()
          .eq('created_by', _currentUser!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user results: $e');
      return [];
    }
  }
  
  /// TR: Kullanıcıya ait tabloya sonuç ekler | EN: Insert result into shared table | RU: Вставляет результат в общую таблицу
  Future<bool> insertUserResult(Map<String, dynamic> result) async {
    if (_currentUser == null) return false;
    
    try {
      await SupabaseService().client
          .from('results')
          .insert({...result, 'created_by': _currentUser!.id});
      
      return true;
    } catch (e) {
      debugPrint('Error inserting user result: $e');
      return false;
    }
  }

  Future<void> loadUserFromStorage() async {
    try {
      final userData = await Storage.getUserData();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
      
      // TR: Seri hash'i depodan yükle | EN: Load serial hash from storage | RU: Загрузить хэш серийного номера из хранилища
      final serialHash = await Storage.getString('user_serial_hash');
      if (serialHash != null) {
        _userSerialHash = serialHash;
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
