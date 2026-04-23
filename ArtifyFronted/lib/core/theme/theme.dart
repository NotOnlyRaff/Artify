// lib/core/theme/theme.dart
import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(12),
      );

  static ThemeData get darkThemeMode {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: Pallete.whiteColor,
      displayColor: Pallete.whiteColor,
    );

    return base.copyWith(
      // lascio lo sfondo trasparente: dietro ci sarà SpaceBackground
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,

      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: Pallete.primary,
        secondary: Pallete.accentCyan,
        surface: Pallete.surfaceSecondary,
        error: Pallete.errorColor,
      ),

      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Pallete.whiteColor,
        ),
        iconTheme: IconThemeData(color: Pallete.whiteColor),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: Pallete.whiteColor,
        unselectedItemColor: Pallete.inactiveBottomBarItemColor,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      cardColor: Pallete.cardColor,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          backgroundColor: Pallete.gradient2,
          foregroundColor: Pallete.whiteColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Pallete.accentCyan,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        filled: true,
        fillColor: Pallete.surfaceSecondary.withOpacity(0.9),
        enabledBorder: _border(Pallete.borderColor),
        focusedBorder: _border(Pallete.primary),
        errorBorder: _border(Pallete.errorColor),
        focusedErrorBorder: _border(Pallete.errorColor),
        hintStyle: const TextStyle(
          color: Pallete.subtitleText,
          fontSize: 14,
        ),
      ),

      iconTheme: const IconThemeData(
        color: Pallete.whiteColor,
      ),
      dialogTheme: DialogThemeData(backgroundColor: Pallete.surfacePrimary),
    );
  }
}
