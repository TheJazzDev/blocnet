import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_progress_card.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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

  /// Opens the current level. Only used once progress has loaded.
  final ValueChanged<UserLevelModel> onTap;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    if (progress != null) {
      return LevelProgressCard(
        progress: progress,
        onTap: () => onTap(progress.currentLevel),
      );
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
    return AppSurface.flush(
      height: 76,
      child: Center(
        child: SizedBox(
          width: AppIcon.md,
          height: AppIcon.md,
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
    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppIcon.sm,
            color: AppColors.error500,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              progressErrorText(
                message,
                fallback: 'Could not load your progress.',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(AppColors.textMuted),
            ),
          ),
          AppButton(
            label: 'Retry',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
