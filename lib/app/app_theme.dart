import 'package:flutter/material.dart';

class AppColors {
  // static Color primaryColor = const Color(0xFF0078E8);
  // static Color primaryAccent = const Color.fromRGBO(120, 14, 14, 1);
  // static Color secondaryColor = const Color(0xFF0078E8);
  // static Color secondaryAccent = const Color(0xFF0078E8);

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

  static Color error500 = const Color(0xFFCB1A14);
  static Color textColor = const Color(0xFFA3A3A3);
  static Color titleColor = const Color(0xFFD4D4D4);
  static Color warning500 = const Color(0xFFDD900D);
  static Color successColor = const Color(0xFF0FA968);
}

ThemeData primaryTheme = ThemeData(
  // seed color theme
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary600,
  ),

  // scaffold color
  scaffoldBackgroundColor: AppColors.darkGrey50,

  // app bar theme colors
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkGrey50,
    foregroundColor: AppColors.textColor,
    surfaceTintColor: Colors.transparent, 
    centerTitle: true,
  ),

  // text theme
  textTheme: const TextTheme().copyWith(
    bodyMedium: TextStyle(
      color: AppColors.textColor,
      fontSize: 12,
      letterSpacing: 1,
      // fontWeight: FontWeight(),
    ),
    bodySmall: TextStyle(
      color: AppColors.darkGrey600,
      fontSize: 12,
      letterSpacing: 1,
    ),
    headlineMedium: TextStyle(
      color: AppColors.titleColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
    ),
    titleMedium: TextStyle(
      color: AppColors.titleColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
    ),
  ),
);
