import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class AppColors {
  // ── Brand primary — bright cyan (#0deef2) ────────────────────────────────
  static Color primary50 = const Color(0xFFECFEFF);
  static Color primary75 = const Color(0xFFCFFAFE);
  static Color primary100 = const Color(0xFFA5F3FC);
  static Color primary200 = const Color(0xFF67E8F9);
  static Color primary300 = const Color(0xFF22D3EE);
  static Color primary400 = const Color(0xFF0deef2);
  static Color primary500 = const Color(0xFF0deef2);
  static Color primary600 = const Color(0xFF0891B2);
  static Color primary700 = const Color(0xFF0E7490);
  static Color primary800 = const Color(0xFF155E75);
  static Color primary900 = const Color(0xFF164E63);
  static Color primary950 = const Color(0xFF083344);

  // ── Cyan glow (for shadows / glows) ──────────────────────────────────────
  static Color cyanGlow = const Color(0xFF0deef2).withValues(alpha: 0.25);

  // ── Secondary accent ─────────────────────────────────────────────────────
  static const Color secondary500 = Color(0xFF2563EB);

  // ── Teal aliases (mapped to cyan primary) ─────────────────────────────────
  static Color teal300 = const Color(0xFF67E8F9);
  static Color teal400 = const Color(0xFF0deef2);
  static Color teal500 = const Color(0xFF0deef2);

  // ── Surfaces — zinc/near-black design system ──────────────────────────────
  /// Page / scaffold background — near black (#09090b)
  static const Color bgBase = Color(0xFF09090b);

  /// Cards, panels, dialogs — zinc-900 (#18181b)
  static const Color bgSurface = Color(0xFF18181b);

  /// Inputs, nested elements — zinc-800 (#27272a)
  static const Color bgElevated = Color(0xFF27272a);

  /// Subtle borders — zinc-800 (#27272a)
  static const Color borderSubtle = Color(0xFF27272a);

  /// Slightly visible borders — zinc-700 (#3f3f46)
  static const Color borderMuted = Color(0xFF3f3f46);

  // ── Text ──────────────────────────────────────────────────────────────────
  /// #FAFAFA — zinc-50
  static Color textPrimary = const Color(0xFFFAFAFA);

  /// Brightened for better readability on dark backgrounds.
  static Color textSecondary = const Color(0xFFC7CBD5);
  static Color textMuted = const Color(0xFFA5ADBA);
  static Color textFaint = const Color(0xFF7D8797);

  // ── Status ────────────────────────────────────────────────────────────────
  static Color error500 = const Color(0xFFCB1A14);
  static Color error900 = const Color(0xFF591000);
  static Color warning500 = const Color(0xFFDD900D);
  static Color warning900 = const Color(0xFF523300);
  static Color successColor = const Color(0xFF10B981);

  // ── Signal / tag palette ──────────────────────────────────────────────────
  /// ALPHA tag — green
  static const Color tagAlpha = Color(0xFF10B981);
  static const Color tagAlphaBg = Color(0x1A10B981);
  static const Color tagAlphaBorder = Color(0x3310B981);

  /// PARTNERSHIP — purple
  static const Color tagPartnership = Color(0xFFA855F7);
  static const Color tagPartnershipBg = Color(0x1AA855F7);
  static const Color tagPartnershipBorder = Color(0x33A855F7);

  /// WARNING / RUG — red
  static const Color tagWarning = Color(0xFFEF4444);
  static const Color tagWarningBg = Color(0x1AEF4444);
  static const Color tagWarningBorder = Color(0x33EF4444);

  /// GENERAL — neutral
  static const Color tagGeneral = Color(0xFF94A3B8);
  static const Color tagGeneralBg = Color(0x1A94A3B8);
  static const Color tagGeneralBorder = Color(0x3394A3B8);

  /// AIRDROP — orange
  static const Color tagAirdrop = Color(0xFFF97316);
  static const Color tagAirdropBg = Color(0x1AF97316);
  static const Color tagAirdropBorder = Color(0x33F97316);

  // ── Hype score colors ─────────────────────────────────────────────────────
  static Color hypeHigh = const Color(0xFF10B981);
  static Color hypeMid = const Color(0xFF0deef2);
  static Color hypeLow = const Color(0xFF52525B);

  // ── Legacy aliases ────────────────────────────────────────────────────────
  static Color textColor = const Color(0xFFA1A1AA);
  static Color titleColor = const Color(0xFFFAFAFA);
  static Color priorityHigh = const Color(0xFFEF4444);
  static Color priorityMid = const Color(0xFFF59E0B);
  static Color priorityLow = const Color(0xFF10B981);

  // ── Grey scale (legacy) ───────────────────────────────────────────────────
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
}

ThemeData primaryTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary500,
    brightness: Brightness.dark,
  ),

  scaffoldBackgroundColor: AppColors.bgBase,

  // Cards — rounded-2xl (24px) matching design
  cardTheme: CardThemeData(
    color: AppColors.bgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AppColors.borderSubtle, width: 1),
    ),
  ),

  // Bottom sheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.bgSurface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
  ),

  // AppBar — bgBase with blur effect handled in custom widgets
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgBase,
    foregroundColor: AppColors.textSecondary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: AppTypography.headlineSmall(AppColors.textPrimary),
    iconTheme: IconThemeData(color: AppColors.textSecondary, size: 20),
  ),

  // Bottom nav bar (custom nav used — this is fallback)
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.bgSurface,
    selectedItemColor: AppColors.teal400,
    unselectedItemColor: AppColors.textMuted,
    elevation: 0,
    type: BottomNavigationBarType.fixed,
  ),

  // Divider
  dividerTheme: DividerThemeData(
    color: AppColors.borderSubtle,
    thickness: 1,
    space: 1,
  ),

  // Input fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.bgElevated,
    labelStyle: AppTypography.bodyMedium(AppColors.textMuted),
    floatingLabelStyle: AppTypography.labelLarge(AppColors.teal400),
    hintStyle: AppTypography.bodyMedium(AppColors.textFaint),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.teal500, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error500),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error500, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  // Text theme — using centralized AppTypography
  textTheme: TextTheme(
    // Display styles
    displayLarge: AppTypography.displayLarge(AppColors.primary500),
    displayMedium: AppTypography.displayMedium(AppColors.primary400),
    displaySmall: AppTypography.displaySmall(AppColors.primary300),

    // Headlines
    headlineLarge: AppTypography.headlineLarge(AppColors.textPrimary),
    headlineMedium: AppTypography.headlineMedium(AppColors.textPrimary),
    headlineSmall: AppTypography.headlineSmall(AppColors.textPrimary),

    // Titles
    titleLarge: AppTypography.titleLarge(AppColors.textPrimary),
    titleMedium: AppTypography.titleMedium(AppColors.textPrimary),
    titleSmall: AppTypography.titleSmall(AppColors.textPrimary),

    // Body
    bodyLarge: AppTypography.bodyLarge(AppColors.textSecondary),
    bodyMedium: AppTypography.bodyMedium(AppColors.textSecondary),
    bodySmall: AppTypography.bodySmall(AppColors.textMuted),

    // Labels
    labelLarge: AppTypography.labelLarge(AppColors.teal400),
    labelMedium: AppTypography.labelMedium(AppColors.textMuted),
    labelSmall: AppTypography.labelSmall(AppColors.textFaint),
  ),
);
