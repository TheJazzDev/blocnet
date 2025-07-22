import 'package:blocnet/app/theme.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey50,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: StyledTitleLarge('Welcome to Sign up screen'),
        ),
      ),
    );
  }
}
