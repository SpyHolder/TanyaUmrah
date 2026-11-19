import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'tanyaUMRAH';
  static const String appTagline =
      'Asisten Informasi Akademik Resmi Mahasiswa UMRAH';

  // UMRAH Maritime Light Theme Palette
  static const Color primaryBlue = Color(0xFF0D47A1); // Deep UMRAH Navy
  static const Color primaryDark = Color(0xFF082E6B); // Darker Maritime Navy
  static const Color primaryNavy = primaryDark; // Semantic alias
  static const Color lightPrimary = Color(0xFF1976D2); // Ocean Blue
  static const Color softBlue = Color(0xFFEFF6FF); // Soft Blue Tint
  static const Color accentGold = Color(0xFFFFB300); // Maritime Gold
  static const Color softGold = Color(0xFFFFFBEB); // Soft Amber Tint

  // Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color stateSuccess = successGreen; // Semantic alias
  static const Color stateInfo = lightPrimary; // Semantic alias
  static const Color softGreen = Color(0xFFECFDF5);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color stateWarning = warningAmber; // Semantic alias
  static const Color errorRed = Color(0xFFEF4444);
  static const Color stateError = errorRed; // Semantic alias
  static const Color softRed = Color(0xFFFEF2F2);

  // Neutral & Surface Colors
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  // Storage Keys
  static const String keyStudentProfile = 'tanya_umrah_student';
  static const String keyChatHistory = 'tanya_umrah_history';
  static const String keyBookmarks = 'tanya_umrah_bookmarks';
  static const String keyDarkMode = 'tanya_umrah_dark_mode';
}
