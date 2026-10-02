import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────
///  KUTHAKA DESIGN SYSTEM: "KERALA NOIR"
///  Dark-first glassmorphic design with Kerala emerald + gold accents
/// ─────────────────────────────────────────────────────────────────────

class KuthakaColors {
  // ── DARK MODE ──
  static const darkBg = Color(0xFF0C0C12);
  static const darkSurface = Color(0xFF16161F);
  static const darkCard = Color(0xFF1E1E2A);
  static const darkCardAlt = Color(0xFF252533);
  static const darkBorder = Color(0xFF2A2A3A);
  static const darkBorderSubtle = Color(0xFF222230);
  static const darkTextPrimary = Color(0xFFF1F5F9);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF64748B);

  // ── LIGHT MODE ──
  static const lightBg = Color(0xFFF7F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF8F9FA);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightBorderSubtle = Color(0xFFEEF0F4);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFF94A3B8);

  // ── BRAND ACCENTS (shared) ──
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF047857);
  static const emeraldMuted = Color(0xFF065F46);
  static const emeraldSurface = Color(0xFF0D3B2E);
  static const emeraldSurfaceLight = Color(0xFFECFDF5);

  static const gold = Color(0xFFF59E0B);
  static const goldDark = Color(0xFFD97706);
  static const goldMuted = Color(0xFFB45309);
  static const goldSurface = Color(0xFF3D2E0A);
  static const goldSurfaceLight = Color(0xFFFEF3C7);

  static const crimson = Color(0xFFEF4444);
  static const crimsonDark = Color(0xFFDC2626);
  static const crimsonSurface = Color(0xFF3B1010);
  static const crimsonSurfaceLight = Color(0xFFFEF2F2);

  static const azure = Color(0xFF3B82F6);
  static const azureDark = Color(0xFF2563EB);
  static const azureSurface = Color(0xFF0F1E3D);
  static const azureSurfaceLight = Color(0xFFEFF6FF);
}

/// Extension helpers that resolve colors based on brightness
extension KuthakaThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get bgColor => isDark ? KuthakaColors.darkBg : KuthakaColors.lightBg;
  Color get surfaceColor => isDark ? KuthakaColors.darkSurface : KuthakaColors.lightSurface;
  Color get cardColor => isDark ? KuthakaColors.darkCard : KuthakaColors.lightCard;
  Color get cardAltColor => isDark ? KuthakaColors.darkCardAlt : KuthakaColors.lightCardAlt;

  // Borders
  Color get borderColor => isDark ? KuthakaColors.darkBorder : KuthakaColors.lightBorder;
  Color get borderSubtle => isDark ? KuthakaColors.darkBorderSubtle : KuthakaColors.lightBorderSubtle;

  // Text
  Color get textPrimary => isDark ? KuthakaColors.darkTextPrimary : KuthakaColors.lightTextPrimary;
  Color get textSecondary => isDark ? KuthakaColors.darkTextSecondary : KuthakaColors.lightTextSecondary;
  Color get textMuted => isDark ? KuthakaColors.darkTextMuted : KuthakaColors.lightTextMuted;

  // Brand accent surfaces
  Color get emeraldBg => isDark ? KuthakaColors.emeraldSurface : KuthakaColors.emeraldSurfaceLight;
  Color get goldBg => isDark ? KuthakaColors.goldSurface : KuthakaColors.goldSurfaceLight;
  Color get crimsonBg => isDark ? KuthakaColors.crimsonSurface : KuthakaColors.crimsonSurfaceLight;
  Color get azureBg => isDark ? KuthakaColors.azureSurface : KuthakaColors.azureSurfaceLight;

  // Glass effect
  Color get glassColor => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.75);
  Color get glassBorder => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFE2E8F0);

  // Elevated container shadow
  List<BoxShadow> get cardShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];

  // Subtle shadow
  List<BoxShadow> get subtleShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
}

class KuthakaTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KuthakaColors.darkBg,
      colorSchemeSeed: KuthakaColors.emerald,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: KuthakaColors.darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: KuthakaColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: KuthakaColors.darkTextPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        color: KuthakaColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KuthakaColors.darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KuthakaColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: KuthakaColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KuthakaColors.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KuthakaColors.darkTextPrimary,
          side: const BorderSide(color: KuthakaColors.darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KuthakaColors.darkCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.emerald, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KuthakaColors.darkCard,
        contentTextStyle: GoogleFonts.outfit(color: KuthakaColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: KuthakaColors.darkBorder,
      dividerTheme: const DividerThemeData(color: KuthakaColors.darkBorder),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: KuthakaColors.lightBg,
      colorSchemeSeed: KuthakaColors.emeraldDark,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: KuthakaColors.lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: KuthakaColors.lightTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: KuthakaColors.lightTextPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        color: KuthakaColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: KuthakaColors.lightBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KuthakaColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: KuthakaColors.lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KuthakaColors.emeraldDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KuthakaColors.lightTextPrimary,
          side: const BorderSide(color: KuthakaColors.lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KuthakaColors.lightCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KuthakaColors.emeraldDark, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KuthakaColors.lightSurface,
        contentTextStyle: GoogleFonts.outfit(color: KuthakaColors.lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: KuthakaColors.lightBorder,
      dividerTheme: const DividerThemeData(color: KuthakaColors.lightBorder),
    );
  }
}
