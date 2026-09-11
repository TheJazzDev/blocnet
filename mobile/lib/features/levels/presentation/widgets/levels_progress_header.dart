import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_progress_card.dart';
import 'package:flutter/material.dart';

/// Top-of-page block for the user's own progress. Wraps [LevelProgressCard]
/// with loading and error placeholders so the tier list below is never
/// blocked on the progress request.
class LevelsProgressHeader extends StatelessWidget {
  const LevelsProgressHeader({
    super.key,
    required this.progress,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onTap,
  });

  final UserLevelProgressModel? progress;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    if (progress != null) {
      return LevelProgressCard(progress: progress, onTap: onTap);
    }
    if (isLoading) return const _Placeholder();
    if (error != null) return _ErrorRow(message: error!, onRetry: onRetry);
    return const SizedBox.shrink();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error500.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
