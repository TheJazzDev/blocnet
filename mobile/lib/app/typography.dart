import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle _appFontFamily(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    // Try to get system font family (respects user's accessibility settings)
    final textStyle = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

    // If user has custom system font, it will be used automatically
    // Otherwise, fall back to Inter
    try {
      return GoogleFonts.inter(
        textStyle: textStyle,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } catch (e) {
      // If GoogleFonts fails (offline, etc.), return base TextStyle
      return textStyle;
    }
  }

  // Display styles
  static TextStyle displayLarge(Color color) => _appFontFamily(
        57,
        FontWeight.w700,
        color,
        height: 1.12,
        letterSpacing: -0.25,
      );

  static TextStyle displayMedium(Color color) => _appFontFamily(
        45,
        FontWeight.w700,
        color,
        height: 1.16,
      );

  static TextStyle displaySmall(Color color) => _appFontFamily(
        36,
        FontWeight.w600,
        color,
        height: 1.22,
      );

  // Headline styles
  static TextStyle headlineLarge(Color color) => _appFontFamily(
        32,
        FontWeight.w700,
        color,
        height: 1.25,
      );

  static TextStyle headlineMedium(Color color) => _appFontFamily(
        28,
        FontWeight.w600,
        color,
        height: 1.29,
      );

  static TextStyle headlineSmall(Color color) => _appFontFamily(
        24,
        FontWeight.w600,
        color,
        height: 1.33,
      );

  // Title styles
  static TextStyle titleLarge(Color color) => _appFontFamily(
        22,
        FontWeight.w600,
        color,
        height: 1.27,
      );

  static TextStyle titleMedium(Color color) => _appFontFamily(
        16,
        FontWeight.w600,
        color,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle titleSmall(Color color) => _appFontFamily(
        14,
        FontWeight.w600,
        color,
        height: 1.43,
        letterSpacing: 0.1,
      );

  // Body styles
  static TextStyle bodyLarge(Color color) => _appFontFamily(
        16,
        FontWeight.w400,
        color,
        height: 1.5,
        letterSpacing: 0.5,
      );

  static TextStyle bodyMedium(Color color) => _appFontFamily(
        14,
        FontWeight.w400,
        color,
        height: 1.43,
        letterSpacing: 0.25,
      );

  static TextStyle bodySmall(Color color) => _appFontFamily(
        12,
        FontWeight.w400,
        color,
        height: 1.33,
        letterSpacing: 0.4,
      );

  // Label styles
  static TextStyle labelLarge(Color color) => _appFontFamily(
        14,
        FontWeight.w600,
        color,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium(Color color) => _appFontFamily(
        12,
        FontWeight.w600,
        color,
        height: 1.33,
        letterSpacing: 0.5,
      );

  static TextStyle labelSmall(Color color) => _appFontFamily(
        11,
        FontWeight.w600,
        color,
        height: 1.45,
        letterSpacing: 0.5,
      );

  // Custom style with full control
  static TextStyle custom({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) =>
      _appFontFamily(
        size,
        weight,
        color,
        height: height,
        letterSpacing: letterSpacing,
      );
}
