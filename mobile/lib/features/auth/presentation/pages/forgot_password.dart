import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_validators.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authStore = context.read<AuthStore>();
    final success = await authStore.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      showAuthMessage(
        context,
        authErrorText(authStore.lastError, 'Could not send the reset link.'),
      );
      return;
    }

    setState(() => _linkSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;

    return AuthScreenShell(
      appBarTitle: '',
      heading: 'Reset your password',
      subtitle: 'We will email you a link to set a new one.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthInputField(
              controller: _emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              validator: validateEmail,
            ),

            // Success confirmation card
            if (_linkSent) ...[
              AppSpace.gapMd,
              AuthNotice.success(
                message: 'If ${_emailController.text.trim()} has an account, '
                    'the link is on its way.',
              ),
            ],

            AppSpace.gapLg,
            AppButton(
              label: _linkSent ? 'Resend link' : 'Send reset link',
              onPressed:
                  !isBusy && authStore.isSupabaseConfigured ? _submit : null,
              isLoading: isBusy,
              fullWidth: true,
            ),

            AppSpace.gapSm,
            Align(
              alignment: Alignment.centerLeft,
              child: AuthTextLink(
                label: 'Back to sign in',
                onTap: () => Navigator.maybePop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
