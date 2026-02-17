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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.teal500,
                      AppColors.primary500,
                    ],
                  )
                : null,
            color: isEnabled ? null : AppColors.darkGrey200,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.primary500.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.white
                        : AppColors.darkGrey500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
