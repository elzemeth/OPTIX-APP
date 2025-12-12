import 'dart:convert';
import 'package:crypto/crypto.dart';

class SerialHash {
  // TR: Seri numarasından tablo adı için hash üretir | EN: Creates a hash of the serial number for table naming | RU: Создает хеш серийного номера для имени таблицы
  static String createHash(String serialNumber) {
    var bytes = utf8.encode(serialNumber);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // TR: Gösterim için kısaltılmış hash üretir | EN: Creates a shorter hash for display purposes | RU: Создает укороченный хеш для отображения
  static String createShortHash(String serialNumber) {
    var bytes = utf8.encode(serialNumber);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  // TR: Hash seri numarasıyla eşleşiyor mu doğrular | EN: Validates if a hash matches a serial number | RU: Проверяет, соответствует ли хеш серийному номеру
  static bool validateHash(String serialNumber, String hash) {
    return createHash(serialNumber) == hash;
  }
}
