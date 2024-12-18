import 'package:blocknet/app/theme.dart';
import 'package:blocknet/shared/styled/primary_button.dart';
import 'package:blocknet/shared/styled/secondary_button.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signin'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey50,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledTitleLarge('Welcome to Sign in screen'),
              const SizedBox(height: 24),
              Row(
                children: [
                  SecondaryButton(
                    title: 'Sign up',
                    isEnabled: true,
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    title: 'Go home',
                    isEnabled: true,
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
