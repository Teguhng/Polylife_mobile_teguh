# PolyLife Mobile

Flutter app untuk pengguna mobile PolyLife.

## Mode aplikasi

- `uiOnly = false` di `lib/core/config/app_mode.dart`:
  - Login + API aktif (Sanctum token).
- `uiOnly = true`:
  - UI-only tanpa login gate dan tanpa request API.

## Konfigurasi API base URL

Base URL default ada di `lib/core/config/api_config.dart`:

- default: `http://10.0.2.2:8000/api/v1` (Android Emulator ke localhost)

Override saat run/build:

```bash
flutter run --dart-define=POLYLIFE_API_BASE_URL=https://domainkamu.com/api/v1
```

Contoh untuk HP fisik dalam 1 Wi-Fi dengan laptop:

```bash
flutter run --dart-define=POLYLIFE_API_BASE_URL=http://192.168.1.10:8000/api/v1
```

## Endpoint auth yang dipakai

- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`

Semua endpoint berada di prefix `api/v1` dan memakai Sanctum bearer token.
