import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme defines all colors, fonts, and styles globally.
/// Font — Jost: clean, geometric, modern, minimal
/// Color — warm brown and white palette
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────
  // COLORS
  // ─────────────────────────────────────────

  /// Primary brand color — buttons, links, accents
  static const Color primaryBrown = Color(0xFF6B4226);

  /// Secondary brand color — hover states, subtle accents
  static const Color lightBrown = Color(0xFFC8A98A);
  
  /// Earthy warm tones for banners and accents
  static const Color terracotta = Color(0xFFB35C37);
  static const Color warmClay   = Color(0xFF8B5A2B);

  /// Surface color — inside cards and forms
  static const Color background = Color(0xFFFAF7F4);
  static const Color surfaceWhite = Color(0xFFFAF7F4); // alias for background

  /// App background — deep dark behind floating cards
  static const Color appBackground = Color(0xFF2C1A0E);

  /// Primary text — headings and body
  static const Color textDark = Color(0xFF2C1A0E);

  /// Secondary text — hints, subtitles, labels
  static const Color textLight = Color(0xFF6B4A2A);

  /// Error color
  static const Color errorRed = Color(0xFFC0392B);

  /// Success color
  static const Color successGreen = Color(0xFF4CAF50);

  /// Placeholder — logo and image placeholders
  static const Color greyPlaceholder = Color(0xFF9E8E80);

  /// Pure white
  static const Color white = Color(0xFFFFFFFF);

  /// Border and divider lines
  static const Color divider = Color(0xFFE8DDD5);
  static const Color borderColor = Color(0xFFE8DDD5); // alias for divider

  /// Section Backgrounds
  static const Color footerBackground = Color(0xFFF1EDE8);
  static const Color exhibitionBackground = Color(0xFFF7F3EE);
  
  /// Helper colors
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color green = Colors.green;

  // ─────────────────────────────────────────
  // TYPOGRAPHY — Jost
  // ─────────────────────────────────────────

  static TextStyle get displayLarge => GoogleFonts.jost(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.3,
      );

  static TextStyle get displayMedium => GoogleFonts.jost(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.3,
      );

  static TextStyle get headingLarge => GoogleFonts.jost(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0.2,
      );

  static TextStyle get headingMedium => GoogleFonts.jost(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textDark,
        letterSpacing: 0.2,
      );

  static TextStyle get bodyLarge => GoogleFonts.jost(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textDark,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyMedium => GoogleFonts.jost(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textLight,
        letterSpacing: 0.1,
      );

  static TextStyle get bodySmall => GoogleFonts.jost(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: textLight,
        letterSpacing: 0.1,
      );

  static TextStyle get labelLarge => GoogleFonts.jost(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: white,
        letterSpacing: 1.5,
      );

  static TextStyle get errorText => GoogleFonts.jost(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: errorRed,
        letterSpacing: 0.1,
      );

  // ─────────────────────────────────────────
  // INPUT DECORATION
  // ─────────────────────────────────────────

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.jost(
        fontSize: 13,
        color: textLight,
        letterSpacing: 0.2,
      ),
      hintStyle: GoogleFonts.jost(
        fontSize: 13,
        color: greyPlaceholder,
      ),
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryBrown, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    );
  }

  // ─────────────────────────────────────────
  // THEME DATA
  // ─────────────────────────────────────────

  static ThemeData get themeData => ThemeData(
        scaffoldBackgroundColor: background,
        primaryColor: primaryBrown,
        colorScheme: ColorScheme.light(
          primary: primaryBrown,
          secondary: lightBrown,
          error: errorRed,
          background: background,
        ),
        textTheme: GoogleFonts.jostTextTheme(),
        useMaterial3: true,
      );
}