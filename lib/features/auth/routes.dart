import 'package:blocknet/constants/app_routes.dart';
import 'package:flutter/material.dart';

import 'presentation/pages/forgot_password.dart';
import 'presentation/pages/reset_password.dart';
import 'presentation/pages/sign_in.dart';
import 'presentation/pages/sign_up.dart';
import 'presentation/pages/verify_email.dart';

class AuthRoutes {
  static const String signin = AppRoutes.signIn;
  static const String signup = AppRoutes.signUp;
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
