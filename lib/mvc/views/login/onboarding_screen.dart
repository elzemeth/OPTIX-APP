import 'package:flutter/material.dart';
import '../../controllers/storage.dart';
import '../../../constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnbPage(
      icon: Icons.visibility_outlined,
      title: 'Welcome to ${AppConstants.brandName}',
      desc: 'SA HOCAM',
    ),
    _OnbPage(
      icon: Icons.bluetooth_searching,
      title: 'Cihaz Eşleme (Tasarım)',
      desc: 'Gerçek BLE yok. Tasarımda sahte liste ile akışı gör.',
    ),
    _OnbPage(
      icon: Icons.lock_outline,
      title: 'PIN ile Giriş',
      desc: 'Demo PIN: 1234',
    ),
  ];

  Future<void> _finish() async {
    await Storage.setOnboarded(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_index + 1) / _pages.length),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Atla'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(_index == _pages.length - 1 ? 'Başla' : 'İleri'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _OnbPage({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: cs.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
