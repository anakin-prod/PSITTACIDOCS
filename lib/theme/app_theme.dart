import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette de Psittacidocs (pione aux ailes de bronze), direction « Nuit & Bronze ».
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0E2254);
  static const blue = Color(0xFF1F4BA8);
  static const bronze = Color(0xFFC39463);
  static const bronzeDark = Color(0xFF8A5A2B);
  static const bronzeOnNavy = Color(0xFFE2BE92);
  static const rose = Color(0xFFE8A7AD);
  static const rosePale = Color(0xFFFBF2F1);
  static const line = Color(0xFFF0DAD8);
  static const pillBorder = Color(0xFFEAD6D3);
  static const red = Color(0xFFD7141F);
  static const redText = Color(0xFFB01019);
  static const mute = Color(0xFF5B6280);
  static const onNavyMuted = Color(0xFFC9D1EA);
  static const navInactive = Color(0xFFAEB6D6);
  static const chevron = Color(0xFFAEB6D6);
  static const chipBg = Color(0xFFF6E3E1);
  static const chipText = Color(0xFF6B3B3F);

  // Pastilles porteuses de sens (fond, texte)
  static const femaleBg = Color(0xFFFBE4E6);
  static const femaleFg = Color(0xFF9A3A47);
  static const maleBg = Color(0xFFE3EBFB);
  static const maleFg = Color(0xFF1F4BA8);
  static const neutralBg = Color(0xFFEEF0F6);
  static const neutralFg = Color(0xFF3E4566);
  static const orangeBg = Color(0xFFFCEBD9);
  static const orangeFg = Color(0xFFA65E13);
  static const bronzeBg = Color(0xFFF6EADC);
  static const goodBg = Color(0xFFE4F4EA);
  static const goodFg = Color(0xFF1F6B3A);
}

/// Décors réutilisables : cartes blanches à ombre douce, sans liseré.
class AppDecor {
  AppDecor._();

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0F0E2254), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0E2254), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> shadowLight = [
    BoxShadow(color: Color(0x0D0E2254), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowStrong = [
    BoxShadow(color: Color(0x470E2254), blurRadius: 30, offset: Offset(0, 12)),
  ];

  static BoxDecoration card({double radius = 20, Color color = Colors.white}) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), boxShadow: shadow);

  static BoxDecoration tile({double radius = 18}) =>
      BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius), boxShadow: shadowLight);
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
          headlineMedium: GoogleFonts.lora(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.navy),
          headlineSmall: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.navy),
          titleLarge: GoogleFonts.lora(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.navy),
          titleMedium: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
          bodyMedium: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.navy),
          bodySmall: GoogleFonts.poppins(fontSize: 12, color: AppColors.mute),
        );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEFE2E0)),
    );

    return base.copyWith(
      textTheme: textTheme,
      // Les sous-écrans ont une barre discrète, sur le fond de l'appli.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.rosePale,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.navy),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.mute),
        hintStyle: const TextStyle(color: AppColors.mute),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.pillBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.bronzeDark,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy : null),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.navy),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: AppColors.line,
    );
  }
}
