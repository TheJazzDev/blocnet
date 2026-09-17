import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';

import 'presentation/pages/closed_alpha_screen.dart';
import 'presentation/pages/forgot_password.dart';
import 'presentation/pages/reset_password.dart';
import 'presentation/pages/sign_in.dart';
import 'presentation/pages/sign_up.dart';
import 'presentation/pages/verify_email.dart';

class AuthRoutes {
  static const String signin = AppRoutes.signIn;
  static const String signup = AppRoutes.signUp;
  static const String verifyEmail = AppRoutes.verifyEmail;
  static const String resetPassword = AppRoutes.resetPassword;
  static const String forgotPassword = AppRoutes.forgotPassword;
  static const String closedAlpha = ClosedAlphaScreen.routeName;

  static bool isAuthRoute(String? route) {
    if (route == null) return false;
    return _allRoutes.contains(route);
  }

  static bool isGuestOnlyRoute(String? route) {
    if (route == null) return false;
    return _guestOnlyRoutes.contains(route);
  }

  static Map<String, WidgetBuilder> getAll() {
    return {
      signin: (context) => const SignInScreen(),
      signup: (context) => const SignUpScreen(),
      verifyEmail: (context) => const VerifyEmailScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      resetPassword: (context) => const ResetPasswordScreen(),
      closedAlpha: (context) => const ClosedAlphaScreen(),
    };
  }

  static const Set<String> _allRoutes = {
    signin,
    signup,
    verifyEmail,
    resetPassword,
    forgotPassword,
    closedAlpha,
  };

  static const Set<String> _guestOnlyRoutes = {
    signin,
    signup,
    forgotPassword,
  };
}
