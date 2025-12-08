import 'dart:convert';
import 'package:crypto/crypto.dart';

class SerialHash {
  /// Creates a hash of the serial number for use as table name
  static String createHash(String serialNumber) {
    var bytes = utf8.encode(serialNumber);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Creates a shorter hash for display purposes
  static String createShortHash(String serialNumber) {
    var bytes = utf8.encode(serialNumber);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  /// Validates if a hash matches a serial number
  static bool validateHash(String serialNumber, String hash) {
    return createHash(serialNumber) == hash;
  }
}
