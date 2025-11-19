import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      print('📱 [UI] Google Sign-In button pressed');
      await context.read<AuthProvider>().signInWithGoogle();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(RouteNames.main);
    } catch (e) {
      print('📱 [UI] Google Sign-In error caught in UI: $e');
      if (!mounted) return;

      String errorMessage = 'Google sign-in failed';
      if (e.toString().contains('PlatformException')) {
        errorMessage = 'Google sign-in not configured. Missing google-services files.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else {
        errorMessage = 'Google sign-in failed: ${e.toString()}';
      }

      Helpers.showError(context, errorMessage);
      // Show in SnackBar as well for visibility
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Copy Error',
            textColor: Colors.white,
            onPressed: () {
              // Could add clipboard copy here
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final email = _emailController.text.trim();
      print('📱 [UI] Sending email link to: $email');

      // Save email for later verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signin_email', email);

      await context.read<AuthProvider>().sendSignInLinkToEmail(email);

      setState(() {
        _emailSent = true;
      });

      if (!mounted) return;

      Helpers.showSuccess(
        context,
        'Sign in link sent! Check your email.',
      );
    } catch (e) {
      print('📱 [UI] Email sign-in error caught in UI: $e');
      if (!mounted) return;

      String errorMessage = 'Failed to send sign-in link';
      if (e.toString().contains('auth/invalid-email')) {
        errorMessage = 'Invalid email address';
      } else if (e.toString().contains('auth/')) {
        // Extract Firebase auth error
        errorMessage = 'Authentication error: ${e.toString().split('auth/').last}';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else {
        errorMessage = 'Failed to send link: ${e.toString()}';
      }

      Helpers.showError(context, errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFF8F9FA),
                    const Color(0xFFE9ECEF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Title Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/img/logo.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.currency_bitcoin,
                            size: 80,
                            color: theme.primaryColor,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome to BlocNet',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Never miss important crypto project updates',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Auth Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_emailSent) ...[
                            GoogleSignInButton(
                              onPressed: _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Sign in with Email',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.email_outlined, color: theme.primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                                ),
                                validator: Validators.validateEmail,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  height: 54,
                                  child: ElevatedButton.icon(
                                    onPressed: authProvider.isLoading ? null : _handleEmailSignIn,
                                    icon: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                    label: Text(
                                      authProvider.isLoading ? 'Sending...' : 'Send Magic Link',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'We\'ll send you a secure link to sign in without a password',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.shade200, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 56,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Check your email!',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We sent a magic link to',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _emailController.text,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Click the link in your email to sign in\nIt may take a few minutes to arrive',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _emailSent = false;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Use different email'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Text(
                      'By signing in, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
