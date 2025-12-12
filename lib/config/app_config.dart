import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../mvc/models/app_theme.dart';

class AppConfig {
  // TR: Singleton deseni | EN: Singleton pattern | RU: Паттерн синглтон
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // TR: Uygulama bilgileri | EN: App information | RU: Информация о приложении
  String get appName => AppConstants.appName;
  String get appVersion => AppConstants.appVersion;
  String get appDescription => AppConstants.appDescription;

  // TR: Tema yapılandırması | EN: Theme configuration | RU: Настройки темы
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppTheme.lightColorScheme,
    textTheme: _buildTextTheme(AppTheme.lightColorScheme),
    appBarTheme: AppTheme.appBarTheme(AppTheme.lightColorScheme),
    cardTheme: AppTheme.cardTheme,
    bottomNavigationBarTheme: AppTheme.bottomNavTheme(AppTheme.lightColorScheme),
    drawerTheme: AppTheme.drawerTheme(AppTheme.lightColorScheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppTheme.primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppTheme.secondaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppTheme.textButtonStyle,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: AppTheme.darkColorScheme,
    textTheme: _buildTextTheme(AppTheme.darkColorScheme),
    appBarTheme: AppTheme.appBarTheme(AppTheme.darkColorScheme),
    cardTheme: AppTheme.cardTheme,
    bottomNavigationBarTheme: AppTheme.bottomNavTheme(AppTheme.darkColorScheme),
    drawerTheme: AppTheme.drawerTheme(AppTheme.darkColorScheme),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: AppTheme.primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppTheme.secondaryButtonStyle,
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppTheme.textButtonStyle,
    ),
  );

  // TR: Metin teması oluşturucu | EN: Text theme builder | RU: Построитель текстовой темы
  TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: AppTheme.headlineLarge.copyWith(color: colorScheme.onSurface),
      headlineMedium: AppTheme.headlineMedium.copyWith(color: colorScheme.onSurface),
      headlineSmall: AppTheme.headlineSmall.copyWith(color: colorScheme.onSurface),
      titleLarge: AppTheme.titleLarge.copyWith(color: colorScheme.onSurface),
      titleMedium: AppTheme.titleMedium.copyWith(color: colorScheme.onSurface),
      titleSmall: AppTheme.titleSmall.copyWith(color: colorScheme.onSurface),
      bodyLarge: AppTheme.bodyLarge.copyWith(color: colorScheme.onSurface),
      bodyMedium: AppTheme.bodyMedium.copyWith(color: colorScheme.onSurface),
      bodySmall: AppTheme.bodySmall.copyWith(color: colorScheme.onSurface),
      labelLarge: AppTheme.labelLarge.copyWith(color: colorScheme.onSurface),
      labelMedium: AppTheme.labelMedium.copyWith(color: colorScheme.onSurface),
      labelSmall: AppTheme.labelSmall.copyWith(color: colorScheme.onSurface),
    );
  }

  // TR: Rota isimleri | EN: Route names | RU: Имена маршрутов
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String firstTimeRoute = '/first-time';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String resultsRoute = '/results';
  static const String ocrRoute = '/ocr';

  // TR: Animasyon süreleri | EN: Animation durations | RU: Длительности анимаций
  Duration get shortAnimation => AppConstants.shortAnimation;
  Duration get mediumAnimation => AppConstants.mediumAnimation;
  Duration get longAnimation => AppConstants.longAnimation;

  // TR: Arayüz sabitleri | EN: UI constants | RU: Константы интерфейса
  double get defaultPadding => AppConstants.defaultPadding;
  double get smallPadding => AppConstants.smallPadding;
  double get largePadding => AppConstants.largePadding;
  double get borderRadius => AppConstants.borderRadius;
  double get cardElevation => AppConstants.cardElevation;

  // TR: Doğrulama kuralları | EN: Validation rules | RU: Правила валидации
  int get minPasswordLength => AppConstants.minPasswordLength;
  int get maxUsernameLength => AppConstants.maxUsernameLength;
  int get maxEmailLength => AppConstants.maxEmailLength;

  // TR: BLE yapılandırması | EN: BLE configuration | RU: Настройки BLE
  String get deviceName => AppConstants.deviceName;
  String get serviceUuid => AppConstants.serviceUuid;
  String get credentialUuid => AppConstants.credentialUuid;
  String get statusUuid => AppConstants.statusUuid;
  String get commandUuid => AppConstants.commandUuid;

  // TR: Metin türleri | EN: Text types | RU: Типы текста
  List<String> get textTypes => [
    AppConstants.textTypeRaw,
    AppConstants.textTypeCharacterCorrected,
    AppConstants.textTypeMeaningCorrected,
  ];

  // TR: Zaman dilimleri | EN: Time buckets | RU: Временные интервалы
  List<int> get timeBuckets => AppConstants.timeBuckets;

  // TR: Depolama anahtarları | EN: Storage keys | RU: Ключи хранения
  String get userDataKey => AppConstants.userDataKey;
  String get loginStatusKey => AppConstants.loginStatusKey;
  String get onboardingKey => AppConstants.onboardingKey;
  String get serialHashKey => AppConstants.serialHashKey;

  // TR: Ortam yapılandırması | EN: Environment configuration | RU: Настройки окружения
  bool get isDebug => const bool.fromEnvironment('dart.vm.product') == false;
  bool get isRelease => const bool.fromEnvironment('dart.vm.product') == true;

  // TR: Özellik bayrakları | EN: Feature flags | RU: Флаги возможностей
  bool get enableBLE => true;
  bool get enableOCR => true;
  bool get enableResults => true;
  bool get enableProfile => true;
  bool get enableSettings => true;

  // TR: API yapılandırması | EN: API configuration | RU: Настройки API
  String get supabaseUrlKey => AppConstants.supabaseUrl;
  String get supabaseAnonKey => AppConstants.supabaseAnonKey;
}
