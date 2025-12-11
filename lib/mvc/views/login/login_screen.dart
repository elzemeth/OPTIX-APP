import 'package:flutter/material.dart';
import '../../controllers/auth_service.dart';
import 'package:design/config/app_config.dart';
import '../../models/app_strings.dart';
import '../../models/app_theme.dart';
import '../widgets/constants/widget_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePwd = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _tryLogin() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _auth.login(_username.text, _password.text);
    if (!mounted) return;
    if (ok) {
      // Check if user has a serial number hash (from BLE connection)
      final serialHash = AuthService().getSerialHash();
      if (serialHash != null) {
        // User has connected device, create their table if needed
        await AuthService().createUserTable();
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppConfig.homeRoute);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(AppStrings.invalidCredentials)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradColors = isDark ? AppTheme.darkGradientColors : AppTheme.lightGradientColors;
    final cardBg = isDark ? cs.surface.withValues(alpha: 0.1) : cs.surface.withValues(alpha: 0.1);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.login),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradColors[0], gradColors[1], cs.surface],
            stops: const [0.0, 0.55, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                color: cardBg.withValues(alpha: isDark ? 0.70 : 0.88),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: WidgetConstants.iconSizeXLarge,
                        color: cs.primary,
                      ),
                      SizedBox(height: WidgetConstants.spacingLarge),
                      Text(
                        AppStrings.login,
                        style: AppTheme.headlineMedium.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: WidgetConstants.spacingSmall),
                      Text(
                        AppStrings.appDescription,
                        style: AppTheme.bodyMedium.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Username field
                      TextField(
                        controller: _username,
                        decoration: AppTheme.inputDecoration(
                          labelText: AppStrings.username,
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: WidgetConstants.spacingMedium),
                      
                      // Password field
                      TextField(
                        controller: _password,
                        obscureText: _obscurePwd,
                        decoration: AppTheme.inputDecoration(
                          labelText: AppStrings.password,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: WidgetConstants.buttonHeightMedium,
                        child: ElevatedButton(
                          onPressed: _tryLogin,
                          style: AppTheme.primaryButtonStyle,
                          child: Text(
                            AppStrings.login,
                            style: AppTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // TR: Kayıt bağlantısı | EN: Sign up link | RU: Ссылка регистрации
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FirstTimeUserScreen(signupPreferred: true),
                            ),
                          );
                        },
                        child: Text(AppStrings.dontHaveAccount),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}