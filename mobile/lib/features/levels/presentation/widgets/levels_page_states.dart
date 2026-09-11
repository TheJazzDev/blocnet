import 'package:blocnet/app/theme.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error500),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
          size: 13,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
