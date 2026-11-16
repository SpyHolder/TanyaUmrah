# tanyaUMRAH

Aplikasi asisten informasi akademik UMRAH berbasis Flutter dan backend FastAPI.

## Konfigurasi proyek

Ikuti **`../PANDUAN_FIREBASE_DAN_LOKAL.md`** untuk membuat proyek Firebase, mengaktifkan Google Sign-In khusus akun student, memasang konfigurasi client/service-account backend, dan menjalankan server lokal.

- URL backend hanya diatur melalui `lib/core/app_config.dart`; tidak ada pengaturan IP dalam tampilan.
- `lib/firebase_options.dart` adalah stub sampai diganti oleh `flutterfire configure` menggunakan proyek Firebase Anda.
- Jangan memasukkan service-account JSON backend ke aplikasi ini.
- Login manual/demo telah dihapus; sesi wajib diverifikasi backend.

## Pemeriksaan

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
