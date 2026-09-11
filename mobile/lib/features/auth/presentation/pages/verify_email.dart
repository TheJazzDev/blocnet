import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _isVerifyingCode = false;
  bool _resentSuccess = false;
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  String _getEmail(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    return (args?['email'] as String?)?.trim() ?? '';
  }

  Future<void> _resendCode() async {
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
          content: Text(authStore.lastError ?? 'Failed to resend code'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _resentSuccess = true);
  }

  Future<void> _verifyCode() async {
    if (_isVerifyingCode) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter your verification code'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final email = _getEmail(context);
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email is missing. Please sign up again.'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isVerifyingCode = true);
    final authStore = context.read<AuthStore>();
    final success = await authStore.verifyEmailWithCode(
      email: email,
      code: code,
    );
    if (!mounted) return;
    setState(() => _isVerifyingCode = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authStore.lastError ?? 'Invalid verification code'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.main,
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _getEmail(context);
    final subtitle = email.isEmpty
        ? 'Enter the 8-digit verification code sent to your email.'
        : 'Enter the 8-digit verification code sent to $email.';

    return AuthScreenShell(
      appBarTitle: '',
      heading: 'Verify your email',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resent success notice
          if (_resentSuccess) ...[
            _ResentBanner(),
            const SizedBox(height: AppSpace.lg),
          ],

          _CodeVerificationCard(
            controller: _codeController,
            focusNode: _codeFocus,
            isLoading: _isVerifyingCode,
            onVerify: _verifyCode,
          ),

          const SizedBox(height: AppSpace.xl),

          // Resend code — secondary action
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive it?",
                  style: TextStyle(
                    color: AppColors.darkGrey500,
                    fontSize: AppText.bodySize,
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                GestureDetector(
                  onTap: _isResending ? null : _resendCode,
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend code',
                    style: TextStyle(
                      color: _isResending
                          ? AppColors.darkGrey400
                          : AppColors.teal400,
                      fontSize: AppText.labelSize,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.md),

          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.signIn,
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                'Back to sign in',
                style: TextStyle(
                  color: AppColors.darkGrey500,
                  fontSize: AppText.bodySize,
                  fontFamily: 'Geist',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeVerificationCard extends StatelessWidget {
  const _CodeVerificationCard({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onVerify,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification code',
            style: TextStyle(
              color: AppColors.darkGrey700,
              fontSize: AppText.bodySize,
              fontWeight: FontWeight.w600,
              fontFamily: 'Geist',
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Paste the 8-digit code from your email to continue in-app.',
            style: TextStyle(
              color: AppColors.darkGrey400,
              fontSize: AppText.bodySize,
              fontFamily: 'Geist',
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onVerify(),
            maxLength: 8,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              color: AppColors.darkGrey700,
              fontSize: AppText.bodySize,
              fontFamily: 'Geist',
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '12345678',
              hintStyle: TextStyle(
                color: AppColors.darkGrey400,
                fontFamily: 'Geist',
              ),
              filled: true,
              fillColor: AppColors.bgSurface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.lg,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                borderSide: BorderSide(color: AppColors.darkGrey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                borderSide: BorderSide(color: AppColors.darkGrey200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                borderSide: BorderSide(color: AppColors.teal400),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: 'Verify code',
            onPressed: isLoading ? null : onVerify,
            isLoading: isLoading,
            fullWidth: true,
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(
          color: AppColors.successColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.successColor,
            size: AppIcon.sm,
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            'Verification link resent',
            style: TextStyle(
              color: AppColors.successColor,
              fontSize: AppText.bodySize,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}
