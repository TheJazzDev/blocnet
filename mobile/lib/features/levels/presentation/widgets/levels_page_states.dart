import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Full-body loading spinner for the levels page.
class LevelsLoadingState extends StatelessWidget {
  const LevelsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primary500),
    );
  }
}

/// Full-body error message with a retry button.
class LevelsErrorState extends StatelessWidget {
  const LevelsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: AppIcon.xxl, color: AppColors.error500),
            const SizedBox(height: AppSpace.md),
            Text(
              message,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.md),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-body empty state when the server returns no levels.
class LevelsEmptyState extends StatelessWidget {
  const LevelsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No levels available',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.labelSize,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
