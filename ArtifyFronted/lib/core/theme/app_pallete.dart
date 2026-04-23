// lib/core/theme/app_pallete.dart
import 'package:flutter/material.dart';

class Pallete {
  // ─── BASE ──────────────────────────────────────────────────────────────────
  static const Color backgroundColor    = Color(0xFF050712); // sfondo globale
  static const Color surfacePrimary     = Color(0xFF0B0F1E); // card principali
  static const Color surfaceSecondary   = Color(0xFF141927); // card secondarie

  // ─── BRAND / ACCENT ───────────────────────────────────────────────────────
  static const Color primary            = Color(0xFF8B5CF6); // violet neon
  static const Color primarySoft        = Color(0xFF6D28D9);
  static const Color accentCyan         = Color(0xFF38BDF8);
  static const Color accentPink         = Color(0xFFEC4899);

  // gradient “Artify”
  static const Color gradient1          = Color(0xFF6D28D9);
  static const Color gradient2          = Color(0xFF8B5CF6);
  static const Color gradient3          = Color(0xFFEC4899);

  // ─── TESTI ────────────────────────────────────────────────────────────────
  static const Color whiteColor         = Colors.white;
  static const Color subtitleText       = Color(0xFFA1A1AA); // grigio caldo
  static const Color mutedText          = Color(0xFF6B7280);

  // ─── COMPONENTI ───────────────────────────────────────────────────────────
  static const Color cardColor          = surfacePrimary;
  static const Color borderColor        = Color(0xFF1F2933);
  static const Color inactiveSeekColor  = Colors.white24;
  static const Color inactiveBottomBarItemColor = Color(0xFF6B7280);

  static const Color successColor       = Color(0xFF22C55E);
  static const Color errorColor         = Color(0xFFF97373);
  static const Color warningColor       = Color(0xFFFBBF24);

  static const Color transparentColor   = Colors.transparent;
  static const Color overlayDark        = Color(0x99000000); // 60% black
}
