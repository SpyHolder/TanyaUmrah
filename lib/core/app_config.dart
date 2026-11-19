import 'package:flutter/foundation.dart';

/// Edit these URLs here, then rebuild the app. No URL is read from device storage.
class AppConfig {
  // Android Studio emulator -> localhost on the development computer.
  // For a physical phone, replace this with the computer's actual LAN IPv4.
  static const androidApiBaseUrl = 'http://192.168.110.185:8000/api/v1';
  static const desktopApiBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // When hosted, set this to your HTTPS API URL (including /api/v1).
  // A nonempty value overrides both local URLs on every platform.
  static const hostedApiBaseUrl = '';

  static String get apiBaseUrl {
    if (hostedApiBaseUrl.isNotEmpty) return hostedApiBaseUrl;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? androidApiBaseUrl
        : desktopApiBaseUrl;
  }

  // Web Client ID (OAuth 2.0 Web client, client_type: 3 in google-services.json)
  // Required by GoogleSignIn on Android to request Google ID Tokens for backend auth.
  static const googleServerClientId =
      '375977508318-tilnotulovuh3u0kg9ak2oopn2l07tsr.apps.googleusercontent.com';

  static const studentDomain = 'student.umrah.ac.id';
  static const requestTimeout = Duration(seconds: 20);
  static const streamIdleTimeout = Duration(seconds: 90);

  static bool isStudentEmail(String? email) =>
      email != null &&
      RegExp(r'^[0-9]{1,20}@student\.umrah\.ac\.id$').hasMatch(email);
}
