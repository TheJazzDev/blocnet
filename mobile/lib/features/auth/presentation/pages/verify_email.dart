import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;

  Future<void> _resendLink() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final email = (args?['email'] as String?)?.trim() ?? '';
    final authStore = context.read<AuthStore>();
    final success = await authStore.resendVerificationEmail(email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authStore.lastError ?? 'Failed to resend link')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification link resent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final email = (args?['email'] as String?)?.trim();

    return AuthScreenShell(
      appBarTitle: 'Verify Email',
      heading: 'Check your inbox',
      subtitle: email == null || email.isEmpty
          ? 'We sent a verification link to your email address.'
          : 'We sent a verification link to $email.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SecondaryButton(
                title: _isResending ? 'Resending...' : 'Resend link',
                isEnabled: !_isResending,
                onPressed: _resendLink,
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                title: 'Continue to sign in',
                isEnabled: true,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.signIn,
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
