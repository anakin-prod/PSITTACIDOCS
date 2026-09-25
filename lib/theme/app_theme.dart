import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette et typographie de Psittacidocs, reprises de l'identité visuelle
/// définie pour l'appli (pione aux ailes de bronze).
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0E2254);
  static const blue = Color(0xFF1F4BA8);
  static const bronze = Color(0xFFC39463);
  static const bronzeDark = Color(0xFF8A5A2B);
  static const rose = Color(0xFFE8A7AD);
  static const rosePale = Color(0xFFFBF2F1);
  static const line = Color(0xFFF0DAD8);
  static const red = Color(0xFFD7141F);
  static const mute = Color(0xFF5B6280);
  static const chipBg = Color(0xFFF6E3E1);
  static const chipText = Color(0xFF6B3B3F);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.bronze,
        error: AppColors.red,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.rosePale,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: AppColors.navy, displayColor: AppColors.navy)
        .copyWith(
          headlineSmall: GoogleFonts.lora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          headlineMedium: GoogleFonts.lora(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          titleLarge: GoogleFonts.lora(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
          titleMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.navy,
          ),
          bodyMedium: GoogleFonts.poppins(fontSize: 13, color: AppColors.navy),
          bodySmall: GoogleFonts.poppins(fontSize: 12, color: AppColors.mute),
          labelSmall: GoogleFonts.robotoMono(
            fontSize: 11,
            color: AppColors.bronzeDark,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.chipBg,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.chipText,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navy,
        selectedItemColor: AppColors.bronze,
        unselectedItemColor: Color(0xFF9FA8CF),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerColor: AppColors.line,
    );
  }
}
