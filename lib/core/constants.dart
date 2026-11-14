import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'tanyaUMRAH';
  static const String appTagline = 'Your AI Guide to UMRAH Student Services';

  // Default API URL:
  // - Android Emulator: 10.0.2.2 points to host PC localhost
  // - Physical Device: IP address on LAN (e.g. 192.168.x.x)
  // - Web / Desktop / Windows: 127.0.0.1
  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api/v1';
      default:
        return 'http://127.0.0.1:8000/api/v1';
    }
  }

  // UMRAH Theme Palette
  static const Color primaryBlue = Color(0xFF0D47A1);      // Deep UMRAH Navy
  static const Color lightPrimary = Color(0xFF1976D2);     // Bright Blue
  static const Color accentGold = Color(0xFFFFB300);       // Maritime Gold
  static const Color surfaceLight = Color(0xFFF8FAFC);     // Soft background
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Storage Keys
  static const String keyApiUrl = 'tanya_umrah_api_url';
  static const String keyStudentProfile = 'tanya_umrah_student';
  static const String keyChatHistory = 'tanya_umrah_history';
  static const String keyBookmarks = 'tanya_umrah_bookmarks';
  static const String keyDarkMode = 'tanya_umrah_dark_mode';
}
