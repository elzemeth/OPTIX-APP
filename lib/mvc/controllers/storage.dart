import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kLoggedIn = 'logged_in';
  static const _kOnboarded = 'onboarded';
  static const _kUserData = 'user_data';

  static Future<void> setLoggedIn(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, v);
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUserData, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final p = await SharedPreferences.getInstance();
    final userDataString = p.getString(_kUserData);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kUserData);
    await p.remove('user_serial_hash');
  }

  static Future<void> setOnboarded(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, v);
  }

  static Future<bool> isOnboarded() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }

  static Future<void> setString(String key, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(key);
  }
}
