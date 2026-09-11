import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';

class PageNotFoundScreen extends StatelessWidget {
  const PageNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final canGoBack = navigator.canPop();

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMuted),
        title: Text(
          'Page Not Found',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: AppText.subtitleSize,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textMuted),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Oops! The page you are looking for does not exist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppText.bodySize,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.main,
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.teal500, AppColors.primary500],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    ),
                    child: Text(
                      'Go to Home',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppText.bodySize,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    navigator.pushNamedAndRemoveUntil(
                      AppRoutes.signIn,
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Go to Sign In',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppText.bodySize,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
