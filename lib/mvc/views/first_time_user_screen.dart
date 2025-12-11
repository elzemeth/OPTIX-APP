import 'package:flutter/material.dart';
import '../controllers/pi_service.dart';
import 'login/login_screen.dart';

class FirstTimeUserScreen extends StatefulWidget {
  final bool signupPreferred;

  const FirstTimeUserScreen({super.key, this.signupPreferred = false});

  @override
  State<FirstTimeUserScreen> createState() => _FirstTimeUserScreenState();
}

class _FirstTimeUserScreenState extends State<FirstTimeUserScreen> {
  final PiService _piService = PiService();

  Future<bool> _promptWifiCredentials() async {
    final ssidController = TextEditingController();
    final passController = TextEditingController();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('WiFi Bağlantısı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidController,
                decoration: const InputDecoration(
                  labelText: 'WiFi SSID',
                  prefixIcon: Icon(Icons.wifi),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'WiFi Şifresi',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: Text('Vazgeç', style: TextStyle(color: cs.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => navigator.pop(true),
              child: const Text('Bağlan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    final ssid = ssidController.text.trim();
    final password = passController.text;

    if (ssid.isEmpty || password.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('SSID ve şifre gerekli.')));
      return false;
    }

    // TR: WiFi bilgilerini Pi'ye dosya olarak yaz (SSH ile) | EN: Write WiFi credentials to Pi as file (via SSH) | RU: Записать учетные данные WiFi в Pi как файл (через SSH)
    messenger.showSnackBar(
      const SnackBar(content: Text('WiFi bilgileri Pi\'ye gönderiliyor...')),
    );
    
    final ok = await _piService.writeWifiCredentials(ssid, password);
    if (!mounted) return false;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'WiFi bilgileri Pi\'ye gönderildi. Pi WiFi\'yi yapılandırıyor...'
            : 'WiFi bilgileri gönderilemedi. Pi bağlantısını kontrol edin.'),
        duration: Duration(seconds: ok ? 3 : 5),
      ),
    );
    
    return ok;
  }


  Future<void> _handleContinue() async {
    // TR: WiFi bilgilerini sor ve gönder | EN: Ask for WiFi credentials and send | RU: Спросить учетные данные WiFi и отправить
    final wifiSent = await _promptWifiCredentials();
    
    // TR: WiFi gönderildiyse navigasyonu yap | EN: If WiFi sent, navigate | RU: Если WiFi отправлен, навигация
    if (!mounted || !wifiSent) return;
    
    if (widget.signupPreferred) {
      // TR: Kullanıcı kayıt olmak istiyor | EN: User wants to sign up | RU: Пользователь хочет зарегистрироваться
      Navigator.pushReplacementNamed(context, '/signup');
    } else {
      // TR: Login ekranına git | EN: Go to login screen | RU: Перейти на экран входа
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPTIX Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.smart_toy,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Welcome to OPTIX!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WiFi bilgilerinizi girin ve Pi\'ye gönderin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // WiFi bilgilerini gönder butonu
            ElevatedButton.icon(
              onPressed: _handleContinue,
              icon: const Icon(Icons.wifi),
              label: const Text('WiFi Bilgilerini Gönder'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
