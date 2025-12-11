import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ssh2/ssh2.dart';

/// TR: Raspberry Pi ile SSH üzerinden iletişim servisi | EN: Service for SSH communication with Raspberry Pi | RU: Сервис для SSH связи с Raspberry Pi
class PiService {
  static final PiService _instance = PiService._internal();
  factory PiService() => _instance;
  PiService._internal();

  // TR: Pi bağlantı bilgileri | EN: Pi connection info | RU: Информация о подключении к Pi
  static const String piHost = '192.168.1.137';
  static const String piUser = 'optix';
  static const String piPassword = '1821';
  static const int piPort = 22;
  
  // TR: WiFi credentials dosya yolu | EN: WiFi credentials file path | RU: Путь к файлу учетных данных WiFi
  static const String wifiCredentialsPath = '/tmp/wifi_credentials.json';

  /// TR: WiFi bilgilerini Pi'ye dosya olarak yaz | EN: Write WiFi credentials to Pi as file | RU: Записать учетные данные WiFi в Pi как файл
  Future<bool> writeWifiCredentials(String ssid, String password) async {
    SSHClient? client;
    try {
      debugPrint('Connecting to Pi at $piHost...');
      
      // TR: SSH bağlantısı oluştur | EN: Create SSH connection | RU: Создать SSH соединение
      client = SSHClient(
        host: piHost,
        port: piPort,
        username: piUser,
        passwordOrKey: piPassword,
      );

      // TR: Bağlan | EN: Connect | RU: Подключиться
      final result = await client.connect();
      if (result != "session_connected") {
        debugPrint('SSH connection failed: $result');
        return false;
      }

      debugPrint('SSH connected successfully');

      // TR: WiFi bilgilerini JSON formatında hazırla | EN: Prepare WiFi credentials in JSON format | RU: Подготовить учетные данные WiFi в формате JSON
      final credentials = {
        'ssid': ssid,
        'password': password,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final jsonContent = jsonEncode(credentials);

      // TR: JSON içeriğini escape et (tek tırnak ve özel karakterler için) | EN: Escape JSON content (for single quotes and special chars) | RU: Экранировать содержимое JSON (для одинарных кавычек и спецсимволов)
      final escapedContent = jsonContent.replaceAll("'", "'\"'\"'");

      // TR: Dosyaya yaz | EN: Write to file | RU: Записать в файл
      // TR: echo komutu ile dosyaya yaz (sudo gerekebilir) | EN: Write to file using echo command (sudo may be needed) | RU: Записать в файл с помощью команды echo (может потребоваться sudo)
      final writeCommand = "echo '$escapedContent' > $wifiCredentialsPath";
      final writeResult = await client.execute(writeCommand);
      
      debugPrint('Write command result: $writeResult');
      
      // TR: Eğer yazma başarısız olursa sudo ile dene | EN: If write fails, try with sudo | RU: Если запись не удалась, попробовать с sudo
      if (writeResult == null || writeResult.isEmpty || writeResult.contains('Permission denied')) {
        debugPrint('Write failed, trying with sudo...');
        // TR: Sudo ile dene | EN: Try with sudo | RU: Попробовать с sudo
        final sudoCommand = "echo '$piPassword' | sudo -S sh -c \"echo '$escapedContent' > $wifiCredentialsPath\"";
        final sudoResult = await client.execute(sudoCommand);
        debugPrint('Sudo write result: $sudoResult');
        
        if (sudoResult == null || sudoResult.contains('Permission denied') || sudoResult.contains('Sorry')) {
          debugPrint('Sudo write failed');
          await client.disconnect();
          return false;
        }
      }

      // TR: Dosyanın yazıldığını doğrula | EN: Verify file was written | RU: Проверить, что файл записан
      await Future.delayed(const Duration(milliseconds: 500)); // TR: Dosyanın yazılması için bekle | EN: Wait for file to be written | RU: Ждать записи файла
      final verifyCommand = 'cat $wifiCredentialsPath';
      final verifyResult = await client.execute(verifyCommand);
      
      if (verifyResult != null && verifyResult.contains(ssid)) {
        debugPrint('✅ WiFi credentials written successfully');
        await client.disconnect();
        return true;
      } else {
        debugPrint('❌ WiFi credentials verification failed');
        debugPrint('Verification result: $verifyResult');
        await client.disconnect();
        return false;
      }
    } catch (e) {
      debugPrint('Error writing WiFi credentials: $e');
      if (client != null) {
        try {
          await client.disconnect();
        } catch (_) {}
      }
      return false;
    }
  }

  /// TR: Pi'ye bağlantıyı test et | EN: Test connection to Pi | RU: Проверить подключение к Pi
  Future<bool> testConnection() async {
    SSHClient? client;
    try {
      client = SSHClient(
        host: piHost,
        port: piPort,
        username: piUser,
        passwordOrKey: piPassword,
      );

      final result = await client.connect();
      if (result == "session_connected") {
        await client.disconnect();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      if (client != null) {
        try {
          await client.disconnect();
        } catch (_) {}
      }
      return false;
    }
  }
}

