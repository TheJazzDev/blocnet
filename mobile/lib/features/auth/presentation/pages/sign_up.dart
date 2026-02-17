import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
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
    final success = await authStore.signUpWithEmailPassword(
      username: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authStore.lastError ?? 'Sign up failed'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (authStore.isAuthenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.main,
        (Route<dynamic> route) => false,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.verifyEmail,
      arguments: {'email': _emailController.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;

    return AuthScreenShell(
      appBarTitle: 'Create Account',
      heading: 'Join Blocnet',
      subtitle: 'Create your account to start following projects.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthInputField(
              controller: _nameController,
              label: 'Username',
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthInputField(
              controller: _emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email is required';
                if (!email.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthInputField(
              controller: _passwordController,
              label: 'Password',
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

            // Primary CTA
            Row(
              children: [
                PrimaryButton(
                  title: 'Create account',
                  isEnabled: !isBusy && authStore.isSupabaseConfigured,
                  isLoading: isBusy,
                  onPressed: _submit,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Back to sign in
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: AppColors.darkGrey500,
                      fontSize: 13,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: isBusy ? null : () => Navigator.pop(context),
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        color: AppColors.teal400,
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
      ),
    );
  }
}
