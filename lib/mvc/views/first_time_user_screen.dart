import 'package:flutter/material.dart';
import '../controllers/ble_service.dart';
import '../controllers/auth_service.dart';
import '../controllers/pi_service.dart';
import 'login/login_screen.dart';

class FirstTimeUserScreen extends StatefulWidget {
  final bool signupPreferred;

  const FirstTimeUserScreen({super.key, this.signupPreferred = false});

  @override
  State<FirstTimeUserScreen> createState() => _FirstTimeUserScreenState();
}

class _FirstTimeUserScreenState extends State<FirstTimeUserScreen> {
  final BleService _bleService = BleService();
  final AuthService _authService = AuthService();
  final PiService _piService = PiService();
  
  bool _scanning = false;
  List<BleDevice> _devices = [];
  String _status = 'Tap "Search Devices" to find your OPTIX glasses';

  @override
  void initState() {
    super.initState();
    _listenToDevices();
  }

  Future<void> _promptWifiCredentials(BleDevice device) async {
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

    if (confirmed != true) return;

    final ssid = ssidController.text.trim();
    final password = passController.text;

    if (ssid.isEmpty || password.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('SSID ve şifre gerekli.')));
      return;
    }

    // TR: WiFi bilgilerini Pi'ye dosya olarak yaz (SSH ile) | EN: Write WiFi credentials to Pi as file (via SSH) | RU: Записать учетные данные WiFi в Pi как файл (через SSH)
    messenger.showSnackBar(
      const SnackBar(content: Text('WiFi bilgileri Pi\'ye gönderiliyor...')),
    );
    
    final ok = await _piService.writeWifiCredentials(ssid, password);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'WiFi bilgileri Pi\'ye gönderildi. Pi WiFi\'yi yapılandırıyor...'
            : 'WiFi bilgileri gönderilemedi. Pi bağlantısını kontrol edin.'),
        duration: Duration(seconds: ok ? 3 : 5),
      ),
    );
  }

  void _listenToDevices() {
    _bleService.devicesStream.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _status = 'Searching for OPTIX devices...';
    });

    try {
      await _bleService.startScan();
    } catch (e) {
      setState(() {
        _status = 'Scan failed: $e';
        _scanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    setState(() {
      _scanning = false;
    });
    _bleService.stopScan();
  }

  Future<void> _connectDevice(BleDevice device) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _bleService.connectToDevice(device);
      if (result != null && result['connected'] == true) {
        // Extract serial number from connection result
        final serialNumber = result['serialNumber'];
        if (serialNumber != null) {
          // Set the serial number hash for the user
          await _authService.setSerialNumber(serialNumber);
          debugPrint('Serial number set: $serialNumber');
          
          // Ask for WiFi credentials right after connection
          await _promptWifiCredentials(device);
          
          // Decide navigation based on intent
          if (!mounted) return;
          if (widget.signupPreferred) {
            // User deliberately came here to sign up
            Navigator.pushReplacementNamed(context, '/signup');
          } else {
            // Auto-route: if device already has an account → login, else signup
            final userExists = await _authService.userExistsBySerial(serialNumber);
            if (!mounted) return;
            if (userExists) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            } else {
              Navigator.pushReplacementNamed(context, '/signup');
            }
          }
        } else {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('Serial number not found. Please try again.')),
          );
        }
      } else {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Connection failed: ${device.name}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
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
                      'First, let\'s connect your smart glasses to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Scan button
            ElevatedButton.icon(
              onPressed: _scanning ? null : _startScan,
              icon: _scanning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
              label: Text(_scanning ? 'Searching...' : 'Search Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            if (_scanning) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _stopScan,
                child: const Text('Stop Search'),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Device list
            Expanded(
              child: _devices.isEmpty
                ? const Center(
                    child: Text(
                      'No devices found yet.\nMake sure your OPTIX glasses are turned on and nearby.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.smart_toy),
                          title: Text(device.name),
                          subtitle: Text('ID: ${device.id}'),
                          trailing: ElevatedButton(
                            onPressed: () => _connectDevice(device),
                            child: const Text('Connect'),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
