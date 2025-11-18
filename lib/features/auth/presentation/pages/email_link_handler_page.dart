import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class EmailLinkHandlerPage extends StatefulWidget {
  final String emailLink;

  const EmailLinkHandlerPage({
    super.key,
    required this.emailLink,
  });

  @override
  State<EmailLinkHandlerPage> createState() => _EmailLinkHandlerPageState();
}

class _EmailLinkHandlerPageState extends State<EmailLinkHandlerPage> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _handleEmailLink();
  }

  Future<void> _handleEmailLink() async {
    try {
      final authProvider = context.read<AuthProvider>();

      // Check if this is a valid sign in link
      if (!authProvider.isSignInWithEmailLink(widget.emailLink)) {
        throw Exception('Invalid sign in link');
      }

      // Get saved email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('signin_email');

      if (email == null) {
        throw Exception('Email not found');
      }

      // Sign in with email link
      await authProvider.signInWithEmailLink(email, widget.emailLink);

      // Clear saved email
      await prefs.remove('signin_email');

      if (!mounted) return;

      // Navigate to main screen
      Navigator.of(context).pushReplacementNamed(RouteNames.main);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      Helpers.showError(
        context,
        'Failed to sign in. Please try again.',
      );

      // Navigate back to sign in
      Navigator.of(context).pushReplacementNamed(RouteNames.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Signing you in...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sign in failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
