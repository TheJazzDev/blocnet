import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_input_field.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

enum _UsernameStatus { idle, checking, available, taken, invalid }

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  Timer? _usernameDebounce;
  final _apiClient = ApiClient();
  final _usernameRegExp = RegExp(r'^[a-z0-9_]{3,24}$');
  final _referralRegExp = RegExp(r'^[A-Z0-9]{8}$');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onUsernameChanged);

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
    _usernameDebounce?.cancel();
    _nameController.removeListener(_onUsernameChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _referralFocus.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final raw = _nameController.text.trim().toLowerCase();

    _usernameDebounce?.cancel();

    if (raw.isEmpty) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }

    if (!_usernameRegExp.hasMatch(raw)) {
      setState(() => _usernameStatus = _UsernameStatus.invalid);
      return;
    }

    setState(() => _usernameStatus = _UsernameStatus.checking);

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(raw);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      final response = await _apiClient.get(
        '/users/check-username',
        query: {'username': username},
      );
      if (!mounted) return;
      if (response is Map<String, dynamic>) {
        final available = response['available'] == true;
        setState(() {
          _usernameStatus =
              available ? _UsernameStatus.available : _UsernameStatus.taken;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _usernameStatus = _UsernameStatus.idle);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_usernameStatus != _UsernameStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _usernameStatus == _UsernameStatus.taken
                ? 'That username is already taken'
                : 'Please wait for username availability check',
          ),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authStore = context.read<AuthStore>();
    final referralCode = _referralController.text.trim().toUpperCase();

    if (referralCode.isNotEmpty) {
      try {
        final result = await _apiClient.get(
          '/referrals/validate',
          query: {'code': referralCode},
        );
        final valid = result is Map<String, dynamic> && result['valid'] == true;
        if (!valid) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Referral code is invalid'),
              backgroundColor: AppColors.darkGrey200,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to validate referral code right now'),
            backgroundColor: AppColors.darkGrey200,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
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

  Future<void> _continueWithGoogle() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    final authStore = context.read<AuthStore>();

    final referralCode = _referralController.text.trim().toUpperCase();
    if (referralCode.isNotEmpty) {
      await authStore.setPendingReferralCode(referralCode);
    }
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    final started = await authStore.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authStore.lastError ?? 'Google sign-up failed'),
          backgroundColor: AppColors.darkGrey200,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Continue with Google in your browser'),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUsernameHint() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Checking availability…',
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 11,
                fontFamily: 'Geist',
              ),
            ),
          ],
        );
      case _UsernameStatus.available:
        return Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 12, color: AppColors.teal400),
            const SizedBox(width: 4),
            Text(
              'Username is available',
              style: TextStyle(
                color: AppColors.teal400,
                fontSize: 11,
                fontFamily: 'Geist',
              ),
            ),
          ],
        );
      case _UsernameStatus.taken:
        return Row(
          children: [
            const Icon(Icons.cancel_outlined,
                size: 12, color: Colors.redAccent),
            const SizedBox(width: 4),
            Text(
              'Username is already taken',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontFamily: 'Geist',
              ),
            ),
          ],
        );
      case _UsernameStatus.invalid:
      case _UsernameStatus.idle:
        return Text(
          'Username must be unique and cannot be changed later.',
          style: TextStyle(
            color: AppColors.textFaint,
            fontSize: 11,
            fontFamily: 'Geist',
          ),
        );
    }
  }

  String? _validateUsername(String? value) {
    final username = (value ?? '').trim().toLowerCase();
    if (username.isEmpty) return 'Username is required';
    if (!_usernameRegExp.hasMatch(username)) {
      return 'Use 3–24 chars: lowercase letters, numbers, underscore only';
    }
    if (_usernameStatus == _UsernameStatus.taken) {
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
    final canSubmit = !isBusy &&
        authStore.isSupabaseConfigured &&
        _usernameStatus == _UsernameStatus.available;

    return AuthScreenShell(
      appBarTitle: '',
      heading: 'Join Blocnet',
      subtitle: 'Create your account to start following projects.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoogleAuthButton(
              label: 'Sign up with Google',
              isEnabled: !isBusy && authStore.isSupabaseConfigured,
              isLoading: false,
              onPressed: _continueWithGoogle,
            ),
            const SizedBox(height: 14),
            const _OrDivider(label: 'or sign up with email'),
            const SizedBox(height: 18),
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
            const SizedBox(height: 4),
            _buildUsernameHint(),
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
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthInputField(
              controller: _referralController,
              label: 'Referral code (optional)',
              focusNode: _referralFocus,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onFieldSubmitted: (_) => _submit(),
              validator: _validateReferral,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                PrimaryButton(
                  title: 'Create account',
                  isEnabled: canSubmit,
                  isLoading: isBusy,
                  onPressed: _submit,
                ),
              ],
            ),
            const SizedBox(height: 20),
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

class _GoogleAuthButton extends StatelessWidget {
  const _GoogleAuthButton({
    required this.label,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary400,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google_g.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderSubtle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 12,
              fontFamily: 'Geist',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.bgElevated,
          ),
        ),
      ],
    );
  }
}
