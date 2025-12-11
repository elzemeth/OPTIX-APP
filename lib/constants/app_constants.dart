class AppConstants {
// TR: Uygulama bilgisi | EN: App info | RU: Информация о приложении
  static const String appName = 'OPTIX';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Glasses Companion App';
  
// TR: API ve servisler | EN: API & Services | RU: API и сервисы
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
  
// TR: BLE yapılandırması | EN: BLE configuration | RU: Настройки BLE
  static const String deviceName = 'OPTIX';
  static const String bleDeviceNamePrefix = 'OPTIX';
  static const String serviceUuid = '12345678-1234-5678-9abc-123456789abc';
  static const String credentialUuid = '87654321-4321-4321-4321-cba987654321';
  static const String statusUuid = '11111111-2222-3333-4444-555555555555';
  static const String commandUuid = '66666666-7777-8888-9999-aaaaaaaaaaaa';
  
// TR: Depolama anahtarları | EN: Storage keys | RU: Ключи хранилища
  static const String userDataKey = 'user_data';
  static const String loginStatusKey = 'login_status';
  static const String onboardingKey = 'onboarding_seen';
  static const String serialHashKey = 'user_serial_hash';
  
// TR: Metin türleri | EN: Text types | RU: Типы текста
  static const String textTypeRaw = 'raw';
  static const String textTypeCharacterCorrected = 'character_corrected';
  static const String textTypeMeaningCorrected = 'meaning_corrected';
  
// TR: Zaman aralıkları | EN: Time buckets | RU: Временные интервалы
  static const List<int> timeBuckets = [3, 6, 24];
  
// TR: Animasyon süreleri | EN: Animation durations | RU: Длительности анимаций
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
// TR: Arayüz sabitleri | EN: UI constants | RU: UI константы
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
// TR: Doğrulama | EN: Validation | RU: Валидация
  static const int minPasswordLength = 4;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 255;
  
// TR: Marka | EN: Brand | RU: Бренд
  static const String brandName = 'OPTIX';
}