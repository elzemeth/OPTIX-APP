import 'package:flutter/material.dart';
import 'helpers.dart';
import 'ble_device_carousel.dart';
import '../../controllers/ble_service.dart';

class SignUpView extends StatelessWidget {
  // --- SignUp form props ---
  final Future<void> Function() signUp;
  final TextEditingController suUsername;
  final TextEditingController suEmail;
  final TextEditingController suPassword;
  final TextEditingController suConfirm;
  final bool suObscure1, suObscure2;
  final VoidCallback toggle1, toggle2;

  // --- BLE props ---
  final bool scanning;
  final String? status;
  final List<BleDevice> devices;
  final Future<void> Function() startScan;
  final Future<void> Function() stopScan;
  final Future<void> Function(BleDevice) connectDevice;
  final VoidCallback openSettings;

  // --- Tema ---
  final ColorScheme cs;
  final Color cardBg;

  const SignUpView({
    required super.key,
    required this.signUp,
    required this.suUsername,
    required this.suEmail,
    required this.suPassword,
    required this.suConfirm,
    required this.suObscure1,
    required this.suObscure2,
    required this.toggle1,
    required this.toggle2,
    required this.scanning,
    required this.status,
    required this.devices,
    required this.startScan,
    required this.stopScan,
    required this.connectDevice,
    required this.openSettings,
    required this.cs,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return _TwoPaneScrollAndCarousel(
      top: (context) => Column(
        children: [
          // FORM
          FilledField(
            key: const ValueKey('signup_username'),
            controller: suUsername,
            label: 'USERNAME',
            hint: 'örn. hakan',
            icon: Icons.person_outline,
            bg: cardBg,
          ),
          const SizedBox(height: 10),
          FilledField(
            key: const ValueKey('signup_email'),
            controller: suEmail,
            label: 'EMAIL',
            hint: 'örn. hakan@example.com',
            icon: Icons.email_outlined,
            bg: cardBg,
          ),
          const SizedBox(height: 10),
          FilledField(
            key: const ValueKey('signup_password'),
            controller: suPassword,
            label: 'PASSWORD',
            hint: 'en az 4 karakter',
            icon: Icons.lock_outline,
            obscure: suObscure1,
            trailing: IconButton(
              onPressed: toggle1,
              icon: Icon(suObscure1 ? Icons.visibility_off : Icons.visibility),
            ),
            bg: cardBg,
          ),
          const SizedBox(height: 10),
          FilledField(
            key: const ValueKey('signup_confirm_password'),
            controller: suConfirm,
            label: 'CONFIRM PASSWORD',
            hint: 'şifreyi tekrar gir',
            icon: Icons.lock_outline,
            obscure: suObscure2,
            trailing: IconButton(
              onPressed: toggle2,
              icon: Icon(suObscure2 ? Icons.visibility_off : Icons.visibility),
            ),
            bg: cardBg,
            onSubmit: (_) => signUp(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50, // buton asla küçülmez
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: signUp,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Hesap Oluştur'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // BLE üst info + butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'BLE ile direkt kayıt olmak için cihazınızı seçin',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: scanning ? null : startScan,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Taramayı Başlat'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanning ? stopScan : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Durdur'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status!, style: const TextStyle(color: Colors.white70)),
                  if (status!.contains('permission') || status!.contains('denied')) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: openSettings,
                      child: const Text('Open Settings', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
  
        ],
      ),

      bottom: (context) => BleDeviceCarousel(
        devices: devices,
        cardBg: cardBg,
        cs: cs,
        onConnect: connectDevice,
      ),
    );
  }
}

class _TwoPaneScrollAndCarousel extends StatelessWidget {
  final WidgetBuilder top;
  final WidgetBuilder bottom;
  const _TwoPaneScrollAndCarousel({
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight.isFinite ? c.maxHeight : MediaQuery.of(context).size.height;
      final topH = (h * 0.54).clamp(220.0, (h - 180.0).clamp(220.0, double.infinity));
      final bottomH = h - topH;
      return Column(
        children: [
          SizedBox(
            height: topH,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: top(context),
            ),
          ),
          SizedBox(
            height: bottomH,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: bottom(context),
            ),
          ),
        ],
      );
    });
  }
}
