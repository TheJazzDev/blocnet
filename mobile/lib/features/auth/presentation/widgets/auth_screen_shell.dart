import 'package:blocnet/app/theme.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.appBarTitle,
    required this.heading,
    required this.subtitle,
    required this.child,
    this.showBack = true,
    this.notice,
  });

  final String appBarTitle;
  final String heading;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey50,
        automaticallyImplyLeading: showBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkGrey200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(
                          'assets/img/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const StyledTitleLarge('Blocnet'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkGrey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledLabelLarge(heading),
                    const SizedBox(height: 8),
                    StyledBodyText500(subtitle),
                    if (notice != null) ...[
                      const SizedBox(height: 12),
                      notice!,
                    ],
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
