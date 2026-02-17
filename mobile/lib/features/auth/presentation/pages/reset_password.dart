import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authStore = context.read<AuthStore>();
    final success = await authStore.updatePassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authStore.lastError ?? 'Password update failed'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password updated successfully'),
        backgroundColor: AppColors.darkGrey200,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;

    return AuthScreenShell(
      appBarTitle: 'Reset Password',
      heading: 'Set a new password',
      subtitle: 'Choose a strong password to secure your account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInputField(
              controller: _passwordController,
              label: 'New password',
              obscureText: _obscurePassword,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscurePassword,
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthInputField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              obscureText: _obscureConfirmPassword,
              focusNode: _confirmFocus,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscureConfirmPassword,
                onTap: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                PrimaryButton(
                  title: 'Update password',
                  isEnabled: !isBusy && authStore.isSupabaseConfigured,
                  isLoading: isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
