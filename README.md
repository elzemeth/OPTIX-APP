# OPTIX Smart Glasses – Full System README

End-to-end guide for the OPTIX smart glasses stack: Flutter mobile app, Raspberry Pi Zero 2W device software, and Supabase backend. Covers tech choices, critical flows, setup, and troubleshooting.

---

## 1) High-Level Overview
- **Mobile (Flutter/Dart)**: Discovers the OPTIX device via BLE, writes WiFi credentials to the device over SSH/SFTP, and handles user auth/registration against Supabase.
- **Device (Pi Zero 2W / Python)**: Runs a unified service (`optix_smart_glasses.py`) that exposes a BLE GATT service, watches `/tmp/wifi_credentials.json`, configures WiFi, manages advertising watchdog, and stubs camera/auth hooks.
- **Backend (Supabase/Postgres)**: Stores users/results. RLS is disabled for development in `supabase_setup.sql` to avoid signup/insert errors.

---

## 2) Tech Stack
**Flutter/Dart**
- State/UI: Flutter (Material 3), MVC-ish layout under `lib/mvc`.
- BLE: `flutter_blue_plus`
- SSH/SFTP: `ssh2`
- Auth/DB: `supabase_flutter`, `shared_preferences`, `flutter_dotenv`
- Permissions: `permission_handler`
- Crypto: `crypto` (SHA-256 for passwords)
- 3D/Assets: `flutter_3d_controller`, bundled assets under `assets/`

**Python (Pi)**
- BLE / D-Bus: BlueZ GATT + advertising via `dbus`/`gi.repository`
- File watching: `watchdog` (fallback stubs if missing)
- System utils: `subprocess`, `iwgetid/iwlist`, `systemd` units

**Infrastructure**
- Supabase project (URL + anon key from `.env`)
- Systemd services on Pi (`smart-glasses.service`, optional `wifi-watcher.service`)

---

## 3) Repository Structure (essentials)
- `lib/mvc/controllers/`
  - `ble_service.dart`: Scan/connect OPTIX BLE, robust name/UUID/manufacturer matching, retries for service discovery, `autoConnect: false` to avoid iOS pairing loops.
  - `pi_service.dart`: SSH/SFTP write of WiFi credentials to Pi.
  - `auth_service.dart`: Credential signup/login, device binding, SHA-256 hashing, Supabase CRUD.
  - `supabase.dart`: Initializes Supabase from `.env`.
  - `storage.dart`, `utils/serial_hash.dart`: local persistence + serial hashing.
- `lib/mvc/views/`: Screens (splash, login/signup/onboarding, first-time BLE, home, profile, OCR, settings, modals, widgets).
- `lib/mvc/models/`: `user.dart`, `stats.dart`, UI strings/theme/constants.
- `pi_zero_2w_setup/`
  - `optix_smart_glasses.py`: Unified device service (BLE GATT, advertising watchdog, WiFi file watcher, WiFi configure).
  - `gatt_server.py`, `wifi_file_watcher.py`: Legacy/split scripts; logic merged into main script.
  - `install_optix_unified.sh`, `smart-glasses.service`, `wifi-watcher.service`: Installation and systemd.
  - `README_OPTIX_UNIFIED.md`: Pi-specific notes.
- `supabase_setup.sql`, `supabase_functions.sql`: Schema, policies (RLS disabled for dev).
- `USER_STORIES.md`: End-to-end flow from splash → BLE → WiFi → signup/login.

---

## 4) Core Flows (mobile)
1) **Startup**: `SplashScreen` checks `Storage.isLoggedIn()` → route to `/home` or `/login`.
2) **Login**: Username/password hashed with SHA-256; if a stored serial hash exists, `connectDevice()` tries to bind device.
3) **Signup**: Creates user, auto-login, then binds device if serial hash exists.
4) **First-time / BLE**: Scan → connect (single lock to avoid parallel connects) → fetch serial via GATT → ask WiFi SSID/pass → send to Pi over SSH/SFTP → decide signup/login based on Supabase lookup.
5) **WiFi provisioning**: App writes JSON to Pi `/tmp/wifi_credentials.json` (sudo write first, SFTP fallback). Pi watcher applies config and restarts `dhcpcd`.
6) **Results/Profile**: Reads/writes Supabase; results ordered by `created_at` desc.

---

## 5) BLE & WiFi Provisioning Details
**BLE identification**
- Device name contains `OPTIX` (case-insensitive) or known keywords.
- Service UUIDs checked (with/without dashes):  
  - WiFi Service: `12345678-1234-5678-9abc-123456789abc`  
  - Credential Char: `87654321-4321-4321-4321-cba987654321`  
  - Status Char: `11111111-2222-3333-4444-555555555555`  
  - Command Char: `66666666-7777-8888-9999-aaaaaaaaaaaa`
- Manufacturer data also inspected for `optix`.
- `autoConnect: false` to reduce iOS pairing loops; 2s delay after connect for service readiness; discovery retried up to 5 times.

**Serial number fetch**
- GATT `get_serial` command on Command Char, response via Status Char notifications.
- Fallback serial derived from device ID prefix `OPTIX_XXXXXXXX` if service/char not found.

**WiFi credential path**
- Target on Pi: `/tmp/wifi_credentials.json` (watched).
- App primary path: sudo write (base64 → file) using `ssh2` with `optix/1821`.
- Fallback: SFTP upload to `/home/optix/wifi_credentials_temp_<ts>.json` then `sudo mv` to target.
- Pi watcher debounces writes, skips if already connected to target SSID, then rewrites `wpa_supplicant.conf` and restarts `dhcpcd`.

---

## 6) Supabase Model (dev mode)
- Tables: `users`, `results` (plus optional user-specific result tables via RPC).
- RLS: Disabled for `users` and `results` in `supabase_setup.sql` to unblock signup/login during development.
- Passwords: Stored as SHA-256 hashes (no salt; dev only).
- Device binding: `device_id` holds hashed serial; uniqueness enforced in app logic before binding.

---

## 7) Configuration
**Root `.env` (mobile)**
```
SUPABASE_URL=your-url
SUPABASE_ANON_KEY=your-anon-key
```
- Keep UTF-8, no BOM. Do not commit real keys.

**Pi connection (mobile)**
- `lib/mvc/controllers/pi_service.dart`: `piHost`, `piUser`, `piPassword`, `piPort`. Update to your LAN IP and credentials.

**Pi services (device)**
- Systemd units in `pi_zero_2w_setup/`. Enable after copying scripts to Pi:
  - `sudo systemctl enable smart-glasses.service && sudo systemctl start smart-glasses.service`
  - Optional watcher unit if split.

**Database**
- Apply `supabase_setup.sql` then `supabase_functions.sql` in Supabase SQL editor.
- Optional fixtures: import `users_rows.csv`, `results_rows.csv`.

---

## 8) Setup & Run
**Mobile**
1) `flutter pub get`
2) Add `.env` with Supabase keys.
3) Run: `flutter run` (choose device). For web: `flutter run -d chrome` (BLE limited).  
4) iOS: ensure Bluetooth + Location entitlements in `ios/Runner/Info.plist`.

**Pi**
1) Requirements: Python 3, BlueZ with D-Bus, `pip install -r requirements` (dbus-python, pygobject, watchdog, requests).  
2) Copy `pi_zero_2w_setup/` to Pi.  
3) Make scripts executable: `chmod +x install_optix_unified.sh`.  
4) Enable service: `sudo systemctl enable --now smart-glasses.service`.  
5) Verify advertising: `bluetoothctl show` (ActiveInstances > 0) or logs `journalctl -u smart-glasses.service -f`.

---

## 9) Files to Know (quick map)
- Mobile logic: `lib/mvc/controllers/ble_service.dart`, `pi_service.dart`, `auth_service.dart`, `supabase.dart`
- UI entry: `lib/main.dart`, `lib/mvc/views/first_time_user_screen.dart`, `login/signup/splash/home/profile/ocr/...`
- Device: `pi_zero_2w_setup/optix_smart_glasses.py`, `smart-glasses.service`
- Backend schema: `supabase_setup.sql`, `supabase_functions.sql`
- Documentation: `USER_STORIES.md`, `pi_zero_2w_setup/README_OPTIX_UNIFIED.md`

---

## 10) Troubleshooting
- **Device not visible over BLE**: Restart `bluetooth` + service on Pi (`sudo systemctl restart bluetooth smart-glasses.service`). Advertising watchdog in Python will attempt restarts, but adapter issues may need manual reset.
- **Repeated pairing popups (iOS)**: Already mitigated with `autoConnect: false` and scan-stop-before-connect. Ensure you stop scanning before connect.
- **WiFi credentials not applied**: Confirm `/tmp/wifi_credentials.json` exists on Pi and contains SSID; check `journalctl -u smart-glasses.service -f`. Ensure sudo password/IP in `pi_service.dart` match the Pi.
- **Supabase unauthorized/RLS errors**: RLS is disabled in `supabase_setup.sql` for dev. Reapply script if policies were added back.
- **Env not loading**: `.env` must sit at repo root, UTF-8, no quotes around values.

---

## 11) Security Notes (dev assumptions)
- Supabase anon key and Pi SSH password are stored in plain text for development. Replace with secrets management before production.
- Password hashing is unsalted SHA-256; upgrade to a salted KDF (e.g., bcrypt/argon2) for production.
- RLS is disabled for `users`/`results`; re-enable and add proper policies before production.

---

## 12) Comment/Log Conventions
- Code comments use `TR | EN | RU` tri-language format across Dart/Python.
- Logs and comments avoid emojis; plain text for reliability in parsers/log viewers.
