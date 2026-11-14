import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryBlue,
      scaffoldBackgroundColor: AppConstants.surfaceLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryBlue,
        primary: AppConstants.primaryBlue,
        secondary: AppConstants.accentGold,
        surface: AppConstants.cardLight,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppConstants.textDark),
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppConstants.textDark),
        headlineSmall: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppConstants.textDark),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppConstants.textDark),
        titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppConstants.textDark),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.poppins(
          color: AppConstants.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppConstants.textDark),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppConstants.lightPrimary,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppConstants.lightPrimary,
        primary: AppConstants.lightPrimary,
        secondary: AppConstants.accentGold,
        surface: const Color(0xFF1E293B),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
