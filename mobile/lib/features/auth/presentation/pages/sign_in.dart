import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:blocnet/shared/widgets/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authStore = context.read<AuthStore>();
    final success = await authStore.signInWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authStore.lastError ?? 'Sign in failed')),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.main,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;

    return AuthScreenShell(
      appBarTitle: 'Sign In',
      showBack: false,
      heading: 'Welcome back',
      subtitle: 'Sign in with your email and password.',
      notice: !authStore.isSupabaseConfigured
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning900.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning500.withValues(alpha: 0.6),
                ),
              ),
              child: const StyledBodyText500(
                'Supabase config missing. Add SUPABASE_URL and SUPABASE_ANON_KEY in --dart-define.',
                size: 12,
              ),
            )
          : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppColors.darkGrey700),
              decoration: _fieldDecoration('Email'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email is required';
                if (!email.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: AppColors.darkGrey700),
              decoration: _fieldDecoration('Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.darkGrey500,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary400,
                        fontFamily: 'Geist',
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SecondaryButton(
                  title: 'Sign up',
                  isEnabled: !isBusy,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.signUp);
                  },
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  title: isBusy ? 'Signing in...' : 'Sign in',
                  isEnabled: !isBusy && authStore.isSupabaseConfigured,
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.darkGrey500),
      filled: true,
      fillColor: AppColors.darkGrey100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.darkGrey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.darkGrey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary500),
      ),
    );
  }
}
