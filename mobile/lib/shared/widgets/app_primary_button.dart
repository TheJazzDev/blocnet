import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.title,
    required this.isEnabled,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String title;
  final bool isEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled && !isLoading ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.teal400,
                      AppColors.primary500,
                    ],
                  )
                : null,
            color: isEnabled ? null : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? AppColors.teal400.withValues(alpha: 0.3)
                  : AppColors.borderSubtle,
              width: 1.5,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.teal400.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  ),
                )
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isEnabled ? Colors.black : AppColors.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Geist',
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
