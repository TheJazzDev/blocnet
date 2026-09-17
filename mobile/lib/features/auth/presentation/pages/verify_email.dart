import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_navigation.dart';
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
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) return '';
    return (args['email'] as String?)?.trim() ?? '';
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
      showAuthMessage(
        context,
        authErrorText(authStore.lastError, 'Could not send a new code.'),
      );
      return;
    }

    setState(() => _resentSuccess = true);
  }

  Future<void> _verifyCode() async {
    if (_isVerifyingCode) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showAuthMessage(context, 'Enter your verification code');
      return;
    }

    final email = _getEmail(context);
    if (email.isEmpty) {
      showAuthMessage(context, 'Email is missing. Please sign up again.');
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
      showAuthMessage(
        context,
        authErrorText(authStore.lastError, 'That code did not work.'),
      );
      return;
    }
    enterApp(context);
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
        ? 'We sent an 8-digit code to your email.'
        : 'We sent an 8-digit code to $email.';

    return AuthScreenShell(
      appBarTitle: '',
      heading: 'Verify your email',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_resentSuccess) ...[
            AuthNotice.success(message: 'New code sent'),
            AppSpace.gapLg,
          ],
          const AppSectionHeader(
            title: 'Verification code',
            icon: Icons.pin_outlined,
            padding: EdgeInsets.zero,
          ),
          AppSpace.gapSm,
          _CodeField(
            controller: _codeController,
            focusNode: _codeFocus,
            onSubmitted: _verifyCode,
          ),
          AppSpace.gapLg,
          AppButton(
            label: 'Verify code',
            onPressed: _isVerifyingCode ? null : _verifyCode,
            isLoading: _isVerifyingCode,
            fullWidth: true,
          ),
          AppSpace.gapMd,
          AuthLinkRow(
            prompt: 'No code?',
            action: _isResending ? 'Sending…' : 'Send a new one',
            onTap: _isResending ? null : _resendCode,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AuthTextLink(
              label: 'Back to sign in',
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.signIn,
                (Route<dynamic> route) => false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: color),
        );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppText.subtitle(AppColors.textPrimary)
          .copyWith(letterSpacing: 4)
          .merge(AppText.tabular),
      decoration: InputDecoration(
        counterText: '',
        hintText: '12345678',
        hintStyle:
            AppText.subtitle(AppColors.textFaint, weight: AppText.regular)
                .copyWith(letterSpacing: 4),
        isDense: true,
        filled: true,
        fillColor: AppColors.bgElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md + 2,
          vertical: AppSpace.md + 2,
        ),
        border: border(AppColors.borderMuted),
        enabledBorder: border(AppColors.borderMuted),
        focusedBorder: border(AppColors.primary400),
      ),
    );
  }
}
