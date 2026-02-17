import 'package:flutter/material.dart';

class AppColors {
  // ── Brand blue ────────────────────────────────────────────────────────────
  static Color primary50 = const Color(0xFFE6F3FF);
  static Color primary75 = const Color(0xFFC9E5FF);
  static Color primary100 = const Color(0xFFB0D9FF);
  static Color primary200 = const Color(0xFF8AC6FF);
  static Color primary300 = const Color(0xFF54ADFF);
  static Color primary400 = const Color(0xFF339DFF);
  static Color primary500 = const Color(0xFF0084FF);
  static Color primary600 = const Color(0xFF0078E8);
  static Color primary700 = const Color(0xFF005EB5);
  static Color primary800 = const Color(0xFF00498C);
  static Color primary900 = const Color(0xFF00376B);
  static Color primary950 = const Color(0xFF012657);

  // ── Brand teal — extracted from logo gradient ─────────────────────────────
  static Color teal300 = const Color(0xFF4DFFD6);
  static Color teal400 = const Color(0xFF00E5B8);
  static Color teal500 = const Color(0xFF00C9A0);

  // ── Grey scale (legacy — kept for compatibility) ──────────────────────────
  static Color darkGrey50 = const Color(0xFF0A0A0A);
  static Color darkGrey75 = const Color(0xFF141414);
  static Color darkGrey100 = const Color(0xFF171717);
  static Color darkGrey200 = const Color(0xFF262626);
  static Color darkGrey300 = const Color(0xFF404040);
  static Color darkGrey400 = const Color(0xFF525252);
  static Color darkGrey500 = const Color(0xFF737373);
  static Color darkGrey600 = const Color(0xFFA3A3A3);
  static Color darkGrey700 = const Color(0xFFD4D4D4);
  static Color darkGrey800 = const Color(0xFFE5E5E5);
  static Color darkGrey900 = const Color(0xFFF5F5F5);
  static Color darkGrey950 = const Color(0xFFFAFAFA);

  // ── Semantic surface tokens (new design system) ───────────────────────────
  /// Page / scaffold background
  static const Color bgBase = Color(0xFF060810);
  /// Cards, panels, dialogs
  static const Color bgSurface = Color(0xFF0D1120);
  /// Inputs, nested elements inside cards
  static const Color bgElevated = Color(0xFF131829);
  /// Subtle borders between surfaces
  static const Color borderSubtle = Color(0xFF1E2A45);
  /// Slightly visible borders
  static const Color borderMuted = Color(0xFF243050);

  // ── Semantic text tokens ──────────────────────────────────────────────────
  static Color textPrimary = const Color(0xFFE5E5E5);
  static Color textSecondary = const Color(0xFFA3A3A3);
  static Color textMuted = const Color(0xFF737373);
  static Color textFaint = const Color(0xFF525252);

  // ── Semantic status colors ────────────────────────────────────────────────
  static Color error500 = const Color(0xFFCB1A14);
  static Color error900 = const Color(0xFF591000);
  static Color warning500 = const Color(0xFFDD900D);
  static Color warning900 = const Color(0xFF523300);
  static Color successColor = const Color(0xFF0FA968);

  // ── Legacy aliases (kept so existing code doesn't break) ─────────────────
  static Color textColor = const Color(0xFFA3A3A3);
  static Color titleColor = const Color(0xFFD4D4D4);

  // ── Priority colors ───────────────────────────────────────────────────────
  static Color priorityHigh = const Color(0xFF00C9A0);   // teal
  static Color priorityMid = const Color(0xFF0084FF);    // blue
  static Color priorityLow = const Color(0xFF525252);    // muted
}

ThemeData primaryTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary600,
    brightness: Brightness.dark,
  ),

  scaffoldBackgroundColor: AppColors.bgBase,

  // Cards use bgSurface
  cardTheme: CardThemeData(
    color: AppColors.bgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.borderSubtle, width: 1),
    ),
  ),

  // Bottom sheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF0D1120),
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgBase,
    foregroundColor: AppColors.textSecondary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      fontFamily: 'Geist',
    ),
    iconTheme: IconThemeData(color: AppColors.textSecondary, size: 20),
  ),

  // Bottom nav bar
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.bgSurface,
    selectedItemColor: AppColors.teal400,
    unselectedItemColor: AppColors.textMuted,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      fontFamily: 'Geist',
    ),
    unselectedLabelStyle: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      fontFamily: 'Geist',
    ),
  ),

  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.borderSubtle,
    thickness: 1,
    space: 1,
  ),

  // Input fields (global fallback — auth screens override with AuthInputField)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgElevated,
    labelStyle: TextStyle(color: AppColors.textMuted, fontFamily: 'Geist'),
    floatingLabelStyle: TextStyle(color: AppColors.teal400, fontFamily: 'Geist'),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.teal500, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error500),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.error500, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  // Text theme
  textTheme: TextTheme(
    bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist'),
    titleSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist'),
    titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Geist'),
    titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Britti'),
    labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Britti'),
    headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Geist'),
    headlineMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Geist'),
    headlineSmall: TextStyle(
        color: AppColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Geist'),
    bodyLarge: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist'),
    bodyMedium: TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist'),
    labelMedium: TextStyle(
        color: AppColors.teal400,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Geist'),
    labelSmall: TextStyle(
        color: AppColors.primary400,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'Geist'),
    displayLarge: TextStyle(
        color: AppColors.primary500,
        fontSize: 56,
        fontWeight: FontWeight.bold,
        fontFamily: 'Geist'),
    displayMedium: TextStyle(
        color: AppColors.primary400,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        fontFamily: 'Geist'),
    displaySmall: TextStyle(
        color: AppColors.primary300,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Geist'),
  ),
);
