import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class PageNotFoundScreen extends StatelessWidget {
  const PageNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final canGoBack = navigator.canPop();

    return Scaffold(
      appBar: AppBar(
        title: const StyledHeading('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (canGoBack) {
              navigator.pop();
            } else {
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.main,
                (Route<dynamic> route) => false,
              );
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StyledBodyText400(
                'Oops! The page you are looking for does not exist.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.main,
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Go to Home'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.signIn,
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Go to Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
