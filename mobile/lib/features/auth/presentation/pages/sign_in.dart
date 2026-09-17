import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_google_button.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_navigation.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_validators.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isSubmitting = false;
  bool _isGoogleSigningIn = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
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
      handleAuthFailure(context, authStore, 'Sign in failed. Try again.');
      return;
    }
    enterApp(context);
  }

  Future<void> _continueWithGoogle() async {
    if (_isGoogleSigningIn) return;
    FocusScope.of(context).unfocus();

    setState(() => _isGoogleSigningIn = true);
    final authStore = context.read<AuthStore>();
    final success = await authStore.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSigningIn = false);

    if (!success) {
      handleAuthFailure(context, authStore, 'Google sign-in failed.');
      return;
    }
    enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;
    final isAnyBusy = isBusy || _isGoogleSigningIn;
    final configured = authStore.isSupabaseConfigured;

    return AuthScreenShell(
      appBarTitle: '',
      showBack: false,
      heading: 'Sign in to Blocnet',
      subtitle: 'Follow your gems and their hunters.',
      notice: configured
          ? null
          : AuthNotice(
              message: 'Supabase config missing. Add SUPABASE_URL and '
                  'PUBLISHABLE_KEY via --dart-define.',
              color: AppColors.warning500,
              icon: Icons.warning_amber_rounded,
            ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthGoogleButton(
              label: 'Continue with Google',
              isEnabled: !isAnyBusy && configured,
              isLoading: _isGoogleSigningIn,
              onPressed: _continueWithGoogle,
            ),
            AppSpace.gapLg,
            const AuthOrDivider(label: 'or use email'),
            AppSpace.gapLg,
            AuthInputField(
              controller: _emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              validator: validateEmail,
            ),
            AppSpace.gapMd,
            AuthInputField(
              controller: _passwordController,
              label: 'Password',
              obscureText: _obscurePassword,
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscurePassword,
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: validatePassword,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AuthTextLink(
                label: 'Forgot password?',
                onTap: isAnyBusy
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
              ),
            ),
            AppSpace.gapXs,
            AppButton(
              label: 'Sign in',
              onPressed: !isAnyBusy && configured ? _submit : null,
              isLoading: isBusy,
              fullWidth: true,
            ),
            AppSpace.gapMd,
            AuthLinkRow(
              prompt: 'New here?',
              action: 'Create account',
              onTap: isAnyBusy
                  ? null
                  : () => Navigator.pushNamed(context, AppRoutes.signUp),
            ),
          ],
        ),
      ),
    );
  }
}
