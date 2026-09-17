import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/pages/closed_alpha_screen.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';

/// After a failed sign-in or sign-up: opens the closed-alpha screen when the
/// email was turned away by the tester list, otherwise shows [fallback]
/// (or the store's readable error) as a snackbar.
void handleAuthFailure(
  BuildContext context,
  AuthStore authStore,
  String fallback,
) {
  final rejected = authStore.closedAlphaRejectedEmail;
  if (rejected != null) {
    Navigator.of(context).pushNamed(
      ClosedAlphaScreen.routeName,
      arguments: {'email': rejected},
    );
    return;
  }
  // Closing the Google account picker is a choice, not a failure.
  if (authStore.lastError?.toLowerCase().contains('cancelled') ?? false) {
    return;
  }
  showAuthMessage(context, authErrorText(authStore.lastError, fallback));
}

/// Signed in: replace the whole stack with the app shell.
void enterApp(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.main,
    (Route<dynamic> route) => false,
  );
}
