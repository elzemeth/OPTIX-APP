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

      // TR: SFTP ile dosyaya yaz (daha güvenilir) | EN: Write to file using SFTP (more reliable) | RU: Записать в файл через SFTP (более надежно)
      try {
        // TR: SFTP bağlantısı kur | EN: Connect SFTP | RU: Подключить SFTP
        final sftpResult = await client.connectSFTP();
        if (sftpResult != "sftp_connected") {
          debugPrint('SFTP connection failed: $sftpResult');
          // TR: SFTP başarısız olursa echo komutu ile dene | EN: If SFTP fails, try with echo command | RU: Если SFTP не удался, попробовать с командой echo
          return await _writeWithEcho(client, jsonContent, ssid);
        }

        debugPrint('SFTP connected successfully');

        // TR: Geçici dosya oluştur | EN: Create temporary file | RU: Создать временный файл
        final tempFile = File('${Directory.systemTemp.path}/wifi_credentials_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsString(jsonContent);

        // TR: SFTP ile dosyayı yükle | EN: Upload file via SFTP | RU: Загрузить файл через SFTP
        final uploadResult = await client.sftpUpload(
          path: tempFile.path,
          toPath: wifiCredentialsPath,
        );

        // TR: Geçici dosyayı sil | EN: Delete temporary file | RU: Удалить временный файл
        await tempFile.delete();

        if (uploadResult == null || uploadResult.toString().contains('failed')) {
          debugPrint('SFTP upload failed: $uploadResult');
          await client.disconnectSFTP();
          return await _writeWithEcho(client, jsonContent, ssid);
        }

        debugPrint('✅ WiFi credentials uploaded via SFTP');
        await client.disconnectSFTP();
        await client.disconnect();
        return true;
      } catch (e) {
        debugPrint('SFTP error: $e, trying echo method...');
        return await _writeWithEcho(client, jsonContent, ssid);
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

  /// TR: Echo komutu ile dosyaya yaz (fallback) | EN: Write to file using echo command (fallback) | RU: Записать в файл с помощью команды echo (резервный метод)
  Future<bool> _writeWithEcho(SSHClient client, String jsonContent, String ssid) async {
    try {
      // TR: JSON içeriğini base64 encode et (özel karakter sorunlarını önlemek için) | EN: Base64 encode JSON content (to avoid special char issues) | RU: Кодировать содержимое JSON в base64 (чтобы избежать проблем со спецсимволами)
      final base64Content = base64Encode(utf8.encode(jsonContent));
      
      // TR: Base64 decode ile dosyaya yaz | EN: Write to file using base64 decode | RU: Записать в файл с помощью декодирования base64
      final writeCommand = "echo '$base64Content' | base64 -d > $wifiCredentialsPath";
      final writeResult = await client.execute(writeCommand);
      
      debugPrint('Write command result: $writeResult');
      
      // TR: Eğer yazma başarısız olursa sudo ile dene | EN: If write fails, try with sudo | RU: Если запись не удалась, попробовать с sudo
      if (writeResult == null || writeResult.contains('Permission denied')) {
        debugPrint('Write failed, trying with sudo...');
        // TR: Sudo ile dene | EN: Try with sudo | RU: Попробовать с sudo
        final sudoCommand = "echo '$piPassword' | sudo -S sh -c \"echo '$base64Content' | base64 -d > $wifiCredentialsPath\"";
        final sudoResult = await client.execute(sudoCommand);
        debugPrint('Sudo write result: $sudoResult');
        
        if (sudoResult == null || sudoResult.contains('Permission denied') || sudoResult.contains('Sorry')) {
          debugPrint('Sudo write failed');
          await client.disconnect();
          return false;
        }
      }

      // TR: Dosyanın yazıldığını doğrula | EN: Verify file was written | RU: Проверить, что файл записан
      await Future.delayed(const Duration(milliseconds: 500));
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
      debugPrint('Error in _writeWithEcho: $e');
      await client.disconnect();
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

