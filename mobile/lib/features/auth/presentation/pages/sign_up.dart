import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_google_button.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_navigation.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_validators.dart';
import 'package:blocnet/features/auth/presentation/widgets/sign_up/username_availability.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
  final _referralController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _referralFocus = FocusNode();

  bool _isSubmitting = false;
  bool _isGoogleSigningUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _apiClient = ApiClient();
  late final _username = UsernameAvailability(apiClient: _apiClient);
  final _referralRegExp = RegExp(r'^[A-Z0-9]{8}$');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onUsernameChanged);
    _username.addListener(_rebuild);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = context.read<AuthStore>().pendingReferralCode;
      if (pending != null &&
          pending.isNotEmpty &&
          _referralController.text.trim().isEmpty) {
        _referralController.text = pending;
      }
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_onUsernameChanged);
    _username
      ..removeListener(_rebuild)
      ..dispose();
    for (final c in [
      _nameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _referralController,
    ]) {
      c.dispose();
    }
    for (final f in [
      _nameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmFocus,
      _referralFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onUsernameChanged() => _username.onChanged(_nameController.text);

  /// Checks an entered referral code with the backend. Returns false (and
  /// says why) when sign-up should stop.
  Future<bool> _referralIsValid(String code) async {
    try {
      final result = await _apiClient.get(
        '/referrals/validate',
        query: {'code': code},
      );
      final valid = result is Map<String, dynamic> && result['valid'] == true;
      if (!valid && mounted) {
        showAuthMessage(context, 'Referral code is invalid');
      }
      return valid;
    } catch (_) {
      if (mounted) {
        showAuthMessage(
            context, 'Could not check the referral code. Try again.');
      }
      return false;
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_username.isAvailable) {
      showAuthMessage(
        context,
        _username.status == UsernameStatus.taken
            ? 'That username is already taken'
            : 'Still checking that username',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authStore = context.read<AuthStore>();
    final referralCode = _referralController.text.trim().toUpperCase();

    if (referralCode.isNotEmpty && !await _referralIsValid(referralCode)) {
      if (mounted) setState(() => _isSubmitting = false);
      return;
    }

    final success = await authStore.signUpWithEmailPassword(
      username: _nameController.text.trim().toLowerCase(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      referralCode: referralCode.isEmpty ? null : referralCode,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      handleAuthFailure(context, authStore, 'Sign up failed. Try again.');
      return;
    }

    if (authStore.isAuthenticated) {
      enterApp(context);
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.verifyEmail,
      arguments: {'email': _emailController.text.trim()},
    );
  }

  Future<void> _continueWithGoogle() async {
    if (_isSubmitting || _isGoogleSigningUp) return;
    FocusScope.of(context).unfocus();
    final authStore = context.read<AuthStore>();

    final referralCode = _referralController.text.trim().toUpperCase();
    if (referralCode.isNotEmpty) {
      await authStore.setPendingReferralCode(referralCode);
    }
    if (!mounted) return;

    setState(() => _isGoogleSigningUp = true);
    final signedIn = await authStore.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSigningUp = false);

    if (!signedIn) {
      handleAuthFailure(context, authStore, 'Google sign-up failed.');
      return;
    }
    // The native Google flow returns a live session, so go straight in.
    enterApp(context);
  }

  /// Sign-up is usually pushed from sign-in; a deep link can open it alone.
  void _backToSignIn() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.signIn);
    }
  }

  String? _validateUsername(String? value) {
    final username = (value ?? '').trim().toLowerCase();
    if (username.isEmpty) return 'Username is required';
    if (!UsernameAvailability.pattern.hasMatch(username)) {
      return 'Use 3–24 chars: lowercase letters, numbers, underscore only';
    }
    if (_username.status == UsernameStatus.taken) {
      return 'Username is already taken';
    }
    return null;
  }

  String? _validateReferral(String? value) {
    final code = (value ?? '').trim().toUpperCase();
    if (code.isEmpty) return null;
    if (!_referralRegExp.hasMatch(code)) {
      return 'Referral code must be 8 letters/numbers';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final isBusy = _isSubmitting || authStore.isSubmitting;
    final isAnyBusy = isBusy || _isGoogleSigningUp;
    final configured = authStore.isSupabaseConfigured;
    final canSubmit = !isAnyBusy && configured && _username.isAvailable;

    return AuthScreenShell(
      appBarTitle: '',
      heading: 'Join Blocnet',
      subtitle: 'Create an account to follow gems.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthGoogleButton(
              label: 'Sign up with Google',
              isEnabled: !isAnyBusy && configured,
              isLoading: _isGoogleSigningUp,
              onPressed: _continueWithGoogle,
            ),
            AppSpace.gapLg,
            const AuthOrDivider(label: 'or use email'),
            AppSpace.gapLg,
            AuthInputField(
              controller: _nameController,
              label: 'Username',
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_emailFocus),
              validator: _validateUsername,
            ),
            UsernameHint(status: _username.status),
            AppSpace.gapMd,
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_confirmFocus),
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscurePassword,
                onTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: validatePassword,
            ),
            AppSpace.gapMd,
            AuthInputField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              obscureText: _obscureConfirmPassword,
              focusNode: _confirmFocus,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_referralFocus),
              suffixIcon: PasswordVisibilityToggle(
                isObscured: _obscureConfirmPassword,
                onTap: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator:
                  confirmPasswordValidator(() => _passwordController.text),
            ),
            AppSpace.gapMd,
            AuthInputField(
              controller: _referralController,
              label: 'Referral code (optional)',
              focusNode: _referralFocus,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _submit(),
              validator: _validateReferral,
            ),
            AppSpace.gapXl,
            AppButton(
              label: 'Create account',
              onPressed: canSubmit ? _submit : null,
              isLoading: isBusy,
              fullWidth: true,
            ),
            AppSpace.gapMd,
            AuthLinkRow(
              prompt: 'Have an account?',
              action: 'Sign in',
              onTap: isAnyBusy ? null : _backToSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
