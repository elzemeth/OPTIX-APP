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

  /// Check if a device is already connected to another account
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
        // Check if it's not the current user
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

  /// Connect a device to the current user account
  Future<bool> connectDevice(String deviceId, String deviceName, String deviceMacAddress) async {
    try {
      if (_currentUser == null) {
        debugPrint('No current user to connect device to');
        return false;
      }

      // Check if device is already connected to another account
      if (await isDeviceConnectedToAnotherAccount(deviceId)) {
        debugPrint('Device is already connected to another account');
        return false;
      }

      // Update user with device information
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
      
      // Update local user data
      _currentUser = _currentUser!.copyWith(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceMacAddress: deviceMacAddress,
        isBleRegistered: true,
        updatedAt: DateTime.now(),
      );
      
      // Save updated user data
      await Storage.setUserData(_currentUser!.toJson());
      
      debugPrint('Device connected successfully to user: ${_currentUser!.username}');
      return true;
    } catch (e) {
      debugPrint('Error connecting device: $e');
      return false;
    }
  }

  /// Disconnect device from current user
  Future<bool> disconnectDevice() async {
    try {
      if (_currentUser == null) {
        debugPrint('No current user to disconnect device from');
        return false;
      }

      // Update user to remove device information
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
      
      // Update local user data
      _currentUser = _currentUser!.copyWith(
        deviceId: null,
        deviceName: null,
        deviceMacAddress: null,
        isBleRegistered: false,
        updatedAt: DateTime.now(),
      );
      
      // Save updated user data
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
      // Hash the password
      final passwordHash = hashPassword(password);
      
      // Query the database for user
      final response = await SupabaseService().client
          .from('users')
          .select()
          .eq('username', username)
          .eq('password_hash', passwordHash)
          .eq('is_active', true);
      
      // Convert PostgrestList to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response);
      
      if (responseList.isNotEmpty) {
        _currentUser = User.fromJson(responseList.first);
        await Storage.setLoggedIn(true);
        await Storage.setUserData(_currentUser!.toJson());
        
        // Check if user has a serial number hash (from BLE connection)
        final serialHash = getSerialHash();
        if (serialHash != null) {
          // Try to connect the device to this user account
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
      
      // Check if user already exists
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
      
      // Check if email already exists
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
      
      // Hash the password
      final passwordHash = hashPassword(password);
      debugPrint('AuthService: Password hashed');
      
      // Create new user
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
      
      // Convert PostgrestList to List<Map<String, dynamic>>
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
        
        // Check if user has a serial number hash (from BLE connection)
        final serialHash = getSerialHash();
        if (serialHash != null) {
          // Try to connect the device to this new user account
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
      // Look for user with this BLE device
      final response = await SupabaseService().client
          .from('users')
          .select()
          .eq('device_id', deviceId)
          .eq('is_active', true);
      
      // Convert PostgrestList to List<Map<String, dynamic>>
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
      // Check if user already exists
      final existingUser = await SupabaseService().client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();
      
      if (existingUser != null) {
        return false; // User already exists
      }
      
      // Create new user with BLE device
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
      
      // Convert PostgrestList to List<Map<String, dynamic>>
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
  
  /// Set the serial number hash for the current user
  Future<void> setSerialNumber(String serialNumber) async {
    _userSerialHash = SerialHash.createHash(serialNumber);
    await Storage.setString('user_serial_hash', _userSerialHash!);
  }
  
  /// Get the serial number hash for the current user
  String? getSerialHash() {
    return _userSerialHash;
  }
  
  /// Check if a user exists with the given serial number
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
  
  /// Create a user-specific table for results
  Future<bool> createUserTable() async {
    if (_currentUser == null) return false;
    
    try {
      final userId = _currentUser!.id;
      final tableName = 'user_results_$userId';
      
      // Create table with user-specific data structure
      await SupabaseService().client.rpc('create_user_table', params: {
        'table_name': tableName,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error creating user table: $e');
      return false;
    }
  }
  
  /// Get user-specific results
  Future<List<Map<String, dynamic>>> getUserResults() async {
    if (_currentUser == null) return [];
    
    try {
      final userId = _currentUser!.id;
      final tableName = 'user_results_$userId';
      final response = await SupabaseService().client
          .from(tableName)
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user results: $e');
      return [];
    }
  }
  
  /// Insert result into user-specific table
  Future<bool> insertUserResult(Map<String, dynamic> result) async {
    if (_currentUser == null) return false;
    
    try {
      final userId = _currentUser!.id;
      final tableName = 'user_results_$userId';
      await SupabaseService().client
          .from(tableName)
          .insert(result);
      
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
      
      // Load serial hash from storage
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
