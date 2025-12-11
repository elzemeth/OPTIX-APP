# OPTIX Smart Glasses (Flutter)

This repo contains the Flutter client for OPTIX smart glasses. It uses an MVC-ish layout, Supabase for auth/data, and Flutter Blue Plus for BLE.

## Project Structure
- `lib/mvc/controllers` – services/controllers (auth, BLE, Supabase, storage, utils)
- `lib/mvc/models` – app-level models and constants
- `lib/mvc/views` – UI screens (splash, login/signup, BLE first-time, home, profile, OCR, settings) and shared widgets
- `lib/constants/app_constants.dart` – shared constants (e.g., BLE name prefix)
- `assets/` – 3D assets and sprites

## Core Flows
- **Startup**: `SplashScreen` → checks `Storage.isLoggedIn()` → `/home` if logged in, else `/login`.
- **Login**: Username/password via `AuthService.login()`. If a serial hash is stored, `connectDevice()` is attempted post-login.
- **Signup**: Credentials-only form; on success, user is auto-logged-in and device connect is attempted if a serial hash exists.
- **BLE First-Time**: `/first-time` handles scanning/connecting, extracts serial (or fallback), and decides login/signup based on Supabase lookup.
- **Profile**: Reads/writes Supabase user data (profile, password change, notification settings).
- **OCR Results**: Fetches user-specific tables `user_results_{user_id}`.

## Environment Setup
1) **Flutter**: stable channel; run `flutter --version` to verify.  
2) **Dependencies**: `flutter pub get`.  
3) **Supabase**: Create a project, then set `.env` in repo root:
```
SUPABASE_URL=your-url
SUPABASE_ANON_KEY=your-anon-key
```
Avoid BOM/invalid encoding—keep it UTF-8 plain text.  
4) **Database schema**: apply `supabase_setup.sql` and `supabase_functions.sql` to your Supabase project (SQL editor).  
5) **CSV seeds (optional)**: `users_rows.csv`, `results_rows.csv` can be imported into Supabase for fixtures.

## Running
- Mobile: `flutter run` (select device/emulator).  
- Web: `flutter run -d chrome` (BLE limited).  
- iOS: ensure proper Bluetooth/location entitlements in `ios/Runner/Info.plist`.

## BLE Notes
- Uses Flutter Blue Plus.  
- Permissions:  
  - Android: `location`, `bluetoothScan`, `bluetoothConnect`.  
  - iOS: `location` + `bluetooth` (permission handler’s `Permission.bluetooth`).  
- Scanning includes name/UUID/manufacturer checks for `OPTIX`. Fallback serial is derived from device ID if WiFi service not found.

## Known/Fixed Issues
- **Type cast crash on signup/login**: `preferred_wifi_networks` now parsed as `List<dynamic>` in `User` model, preventing `List<dynamic> is not a subtype of Map` errors.
- **Supabase init failures**: app logs a warning and continues; ensure `.env` is valid UTF-8 with real keys.

## Troubleshooting
- **Login/Signup type errors**: Confirm `.env` loads and Supabase rows include JSON arrays for `preferred_wifi_networks` and JSON objects for `device_settings`.
- **BLE permissions loop on iOS**: Grant both Location and Bluetooth in Settings. On Android, ensure “Nearby devices” and Location are enabled.
- **No services found / fallback serial**: Device may not expose expected UUIDs; fallback serial uses device ID prefix `OPTIX_XXXXXXXX`.

## Developer Tips
- Theme switching uses global `themeMode` (`main.dart`).
- SharedPreferences wrapper is in `mvc/controllers/storage.dart`.
- When adding Supabase queries, always convert `PostgrestList` with `List<Map<String,dynamic>>.from(response)` before parsing.
- User-specific tables: `create_user_table` RPC builds `user_results_{user_id}`; results fetchers in `SupabaseService`/`AuthService`.

## Testing Checklist
- Signup → auto-login succeeds; login works with hashed password.
- Device uniqueness: `isDeviceConnectedToAnotherAccount` blocks duplicate device IDs.
- BLE connect flow: permissions granted → scan → connect → serial stored.
- Profile updates (profile info, password, notification settings) persist in Supabase.
- OCR results list per user/table sorts by `created_at` desc.
