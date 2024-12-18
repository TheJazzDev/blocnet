import 'package:blocknet/features/auth/presentation/pages/forgot_password.dart';
import 'package:blocknet/features/auth/presentation/pages/reset_password.dart';
import 'package:blocknet/features/auth/presentation/pages/sign_in.dart';
import 'package:blocknet/features/auth/presentation/pages/sign_up.dart';
import 'package:blocknet/features/auth/presentation/pages/verify_email.dart';
import 'package:flutter/material.dart';

class AuthRoutes {
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static Map<String, WidgetBuilder> getAll() {
    return {
      signin: (context) => const SignInScreen(),
      signup: (context) => const SignUpScreen(),
      verifyEmail: (context) => const VerifyEmailScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      resetPassword: (context) => const ResetPasswordScreen(),
    };
  }
}
