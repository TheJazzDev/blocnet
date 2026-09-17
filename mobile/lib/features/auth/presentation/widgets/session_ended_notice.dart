import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:flutter/material.dart';

/// Banner on the sign-in screen after the auth server ended the session.
class SessionEndedNotice extends StatelessWidget {
  const SessionEndedNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AuthNotice(
      message: message,
      color: AppColors.warning500,
      icon: Icons.lock_clock_outlined,
    );
  }
}
