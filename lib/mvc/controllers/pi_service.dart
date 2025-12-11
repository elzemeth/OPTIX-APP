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

      // TR: Önce SFTP ile yazmayı dene, başarısız olursa sudo ile yaz (arka planda otomatik) | EN: Try writing with SFTP first, if fails use sudo (automatic in background) | RU: Сначала попробовать записать через SFTP, если не удалось - использовать sudo (автоматически в фоне)
      final sftpSuccess = await _writeWithSFTP(client, jsonContent, ssid);
      if (sftpSuccess) {
        return true;
      }
      
      // TR: SFTP başarısız olursa sudo ile yaz (arka planda, kullanıcı görmez) | EN: If SFTP fails, write with sudo (in background, user doesn't see) | RU: Если SFTP не удался, записать с sudo (в фоне, пользователь не видит)
      return await _writeWithSudo(client, jsonContent, ssid);
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

  /// TR: SFTP ile dosyaya yaz (ilk deneme) | EN: Write to file using SFTP (first attempt) | RU: Записать в файл через SFTP (первая попытка)
  Future<bool> _writeWithSFTP(SSHClient client, String jsonContent, String ssid) async {
    try {
      debugPrint('Attempting to write via SFTP...');
      
      // TR: SFTP bağlantısı kur | EN: Connect SFTP | RU: Подключить SFTP
      final sftpResult = await client.connectSFTP();
      if (sftpResult != "sftp_connected") {
        debugPrint('SFTP connection failed: $sftpResult');
        return false;
      }

      debugPrint('SFTP connected successfully');

      // TR: Geçici dosya oluştur | EN: Create temporary file | RU: Создать временный файл
      final tempFile = File('${Directory.systemTemp.path}/wifi_credentials_${DateTime.now().millisecondsSinceEpoch}.json');
      await tempFile.writeAsString(jsonContent);

      // TR: SFTP ile önce home dizinine yükle (izin hatalarını azaltır) | EN: Upload to home via SFTP first (avoid permission issues) | RU: Сначала загрузить в домашний каталог (уменьшает ошибки прав)
      const tempRemotePath = '/home/optix/wifi_credentials_temp.json';
      final uploadResult = await client.sftpUpload(
        path: tempFile.path,
        toPath: tempRemotePath,
      );

      // TR: Geçici dosyayı sil | EN: Delete temporary file | RU: Удалить временный файл
      await tempFile.delete();

      if (uploadResult != null && uploadResult.toString().contains('failed')) {
        debugPrint('SFTP upload failed: $uploadResult');
        await client.disconnectSFTP();
        return false;
      }

      // TR: Yüklenen dosyayı sudo ile hedefe taşı | EN: Move uploaded file to target with sudo | RU: Переместить загруженный файл в целевой с sudo
      final moveResult = await client.execute("echo '$piPassword' | sudo -S mv $tempRemotePath $wifiCredentialsPath");
      debugPrint('Move result: $moveResult');

      debugPrint('✅ WiFi credentials uploaded via SFTP');
      await client.disconnectSFTP();
      
      // TR: Dosyanın yazıldığını doğrula | EN: Verify file was written | RU: Проверить, что файл записан
      await Future.delayed(const Duration(milliseconds: 300));
      final verifyCommand = 'cat $wifiCredentialsPath';
      final verifyResult = await client.execute(verifyCommand);
      
      if (verifyResult != null && verifyResult.contains(ssid)) {
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('SFTP error: $e');
      try {
        await client.disconnectSFTP();
      } catch (_) {}
      return false;
    }
  }

  /// TR: Sudo ile dosyaya yaz (arka planda otomatik, kullanıcı görmez) | EN: Write to file with sudo (automatic in background, user doesn't see) | RU: Записать в файл с sudo (автоматически в фоне, пользователь не видит)
  Future<bool> _writeWithSudo(SSHClient client, String jsonContent, String ssid) async {
    try {
      debugPrint('Writing with sudo (automatic, in background)...');
      
      // TR: JSON içeriğini base64 encode et (özel karakter sorunlarını önlemek için) | EN: Base64 encode JSON content (to avoid special char issues) | RU: Кодировать содержимое JSON в base64 (чтобы избежать проблем со спецсимволами)
      final base64Content = base64Encode(utf8.encode(jsonContent));
      
      // TR: Arka planda sudo ile yaz (kullanıcı görmez) | EN: Write with sudo in background (user doesn't see) | RU: Записать с sudo в фоне (пользователь не видит)
      final sudoCommand = "echo '$piPassword' | sudo -S bash -c 'echo \"$base64Content\" | base64 -d > $wifiCredentialsPath'";
      final sudoResult = await client.execute(sudoCommand);
      
      // TR: Eğer başarısız olursa alternatif yöntem dene | EN: If failed, try alternative method | RU: Если не удалось, попробовать альтернативный метод
      if (sudoResult != null && (sudoResult.contains('Permission denied') || sudoResult.contains('Sorry') || sudoResult.contains('incorrect') || sudoResult.contains('password') || sudoResult.contains('try again'))) {
        debugPrint('Sudo write failed, trying alternative method...');
        // TR: Heredoc kullanarak dene | EN: Try using heredoc | RU: Попробовать используя heredoc
        final altCommand = "echo '$piPassword' | sudo -S bash -c 'cat > $wifiCredentialsPath <<EOF\n$jsonContent\nEOF'";
        final altResult = await client.execute(altCommand);
        
        if (altResult != null && (altResult.contains('Permission denied') || altResult.contains('Sorry'))) {
          debugPrint('All methods failed');
          return false;
        }
      }

      // TR: Dosyanın yazıldığını doğrula | EN: Verify file was written | RU: Проверить, что файл записан
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyCommand = 'cat $wifiCredentialsPath';
      final verifyResult = await client.execute(verifyCommand);
      
      if (verifyResult != null && verifyResult.contains(ssid)) {
        debugPrint('✅ WiFi credentials written successfully');
        return true;
      } else {
        debugPrint('❌ WiFi credentials verification failed');
        return false;
      }
    } catch (e) {
      debugPrint('Error in _writeWithSudo: $e');
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

