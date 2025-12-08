import 'package:flutter/material.dart';
import 'mvc/models/app_theme.dart';
import 'mvc/views/splash_screen.dart';
import 'mvc/views/first_time_user_screen.dart';
import 'mvc/views/login/onboarding_screen.dart';
import 'mvc/views/login/login_screen.dart';
import 'mvc/views/login/signup_screen.dart';
import 'mvc/views/home/home_screen.dart';
import 'mvc/views/profile/profile_screen.dart';
import 'mvc/views/settings/settings_screen.dart';
import 'mvc/views/ocr/raw_screen.dart';
import 'mvc/controllers/supabase.dart';
import 'mvc/controllers/auth_service.dart';
import 'mvc/views/ocr/results.dart';
import 'package:permission_handler/permission_handler.dart';

// Global theme mode notifier
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseService().init();
  } catch (e) {
    // Handle Supabase initialization errors gracefully
    debugPrint('Warning: Supabase initialization failed: $e');
    // Continue app startup even if Supabase fails
  }
  
  // Load user data from storage
  try {
    await AuthService().loadUserFromStorage();
  } catch (e) {
    debugPrint('Warning: Failed to load user data: $e');
  }
  
  // Check location permission status on app startup (but don't force request)
  try {
    final currentStatus = await Permission.location.status;
    debugPrint('Current location permission status: $currentStatus');
    
    // Only log the status, don't force request here
    // Let the BLE service handle permission requests when needed
  } catch (e) {
    debugPrint('Warning: Failed to check location permission: $e');
  }
  
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OPTIX (Design Only)',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/first-time': (_) => const FirstTimeUserScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login' : (_) => const LoginScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/home'  : (_) => const HomeScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/ocr/results': (_) => const Results(),
            '/ocr/raw': (_) => const RawScreen(),
          },
        );
      },
    );
  }
}
