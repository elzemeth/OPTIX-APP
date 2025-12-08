class AppConstants {
  // App Info
  static const String appName = 'OPTIX';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Glasses Companion App';
  
  // API & Services
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
  
  // BLE Configuration
  static const String deviceName = 'OPTIX';
  static const String bleDeviceNamePrefix = 'OPTIX';
  static const String serviceUuid = '12345678-1234-5678-9abc-123456789abc';
  static const String credentialUuid = '87654321-4321-4321-4321-cba987654321';
  static const String statusUuid = '11111111-2222-3333-4444-555555555555';
  static const String commandUuid = '66666666-7777-8888-9999-aaaaaaaaaaaa';
  
  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String loginStatusKey = 'login_status';
  static const String onboardingKey = 'onboarding_seen';
  static const String serialHashKey = 'user_serial_hash';
  
  // Text Types
  static const String textTypeRaw = 'raw';
  static const String textTypeCharacterCorrected = 'character_corrected';
  static const String textTypeMeaningCorrected = 'meaning_corrected';
  
  // Time Buckets
  static const List<int> timeBuckets = [3, 6, 24];
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Validation
  static const int minPasswordLength = 4;
  static const int maxUsernameLength = 50;
  static const int maxEmailLength = 255;
  
  // Brand
  static const String brandName = 'OPTIX';
}