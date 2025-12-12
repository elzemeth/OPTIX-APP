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

// TR: Global tema modu bildiricisi | EN: Global theme mode notifier | RU: Глобальный нотификатор режима темы
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseService().init();
  } catch (e) {
    // TR: Supabase başlatma hatalarını yumuşak şekilde ele al | EN: Handle Supabase initialization errors gracefully | RU: Аккуратно обрабатывай ошибки инициализации Supabase
    debugPrint('Warning: Supabase initialization failed: $e');
    // TR: Supabase başarısız olsa bile uygulamayı başlatmaya devam et | EN: Continue app startup even if Supabase fails | RU: Продолжай запуск приложения даже при ошибке Supabase
  }
  
  // TR: Kullanıcı verisini depodan yükle | EN: Load user data from storage | RU: Загрузить данные пользователя из хранилища
  try {
    await AuthService().loadUserFromStorage();
  } catch (e) {
    debugPrint('Warning: Failed to load user data: $e');
  }
  
  // TR: Konum izni durumunu başlangıçta kontrol et (istek göndermeden) | EN: Check location permission status on startup (without forcing request) | RU: Проверить статус разрешения на геолокацию при старте (без запроса)
  try {
    final currentStatus = await Permission.location.status;
    debugPrint('Current location permission status: $currentStatus');
    
    // TR: Sadece durumu logla, burada izin isteme | EN: Only log status, do not request here | RU: Только логируй статус, не запрашивай здесь
    // TR: İzin isteğini gerektiğinde BLE servisi yönetsin | EN: Let BLE service handle permission requests when needed | RU: Разрешения запрашивает BLE-сервис при необходимости
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
