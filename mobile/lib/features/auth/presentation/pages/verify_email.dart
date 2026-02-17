import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _resentSuccess = false;

  String _getEmail(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    return (args?['email'] as String?)?.trim() ?? '';
  }

  Future<void> _resendLink() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _resentSuccess = false;
    });

    final email = _getEmail(context);
    final authStore = context.read<AuthStore>();
    final success = await authStore.resendVerificationEmail(email);
    if (!mounted) return;
    setState(() => _isResending = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authStore.lastError ?? 'Failed to resend link'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _resentSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    final email = _getEmail(context);
    final subtitle = email.isEmpty
        ? 'We sent a verification link to your email address.'
        : 'We sent a verification link to $email.';

    return AuthScreenShell(
      appBarTitle: 'Verify Email',
      heading: 'Check your inbox',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email illustration card
          _EmailIllustrationCard(email: email),

          const SizedBox(height: 24),

          // Resent success notice
          if (_resentSuccess) ...[
            _ResentBanner(),
            const SizedBox(height: 16),
          ],

          // Primary CTA
          Row(
            children: [
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

          const SizedBox(height: 20),

          // Resend link — secondary action
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive it?",
                  style: TextStyle(
                    color: AppColors.darkGrey500,
                    fontSize: 13,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _isResending ? null : _resendLink,
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend link',
                    style: TextStyle(
                      color: _isResending
                          ? AppColors.darkGrey400
                          : AppColors.teal400,
                      fontSize: 13,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailIllustrationCard extends StatelessWidget {
  const _EmailIllustrationCard({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkGrey200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon with glow
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teal500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal500.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: AppColors.teal400,
              size: 24,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Verification email sent',
            style: TextStyle(
              color: AppColors.darkGrey700,
              fontSize: 15,
              fontFamily: 'Britti',
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          if (email.isNotEmpty)
            Text(
              email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.teal400,
                fontSize: 12,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 8),

          Text(
            'Click the link in the email to verify your account before signing in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkGrey400,
              fontSize: 12,
              fontFamily: 'Geist',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.successColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.successColor,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            'Verification link resent',
            style: TextStyle(
              color: AppColors.successColor,
              fontSize: 12,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
