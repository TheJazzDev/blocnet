import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_pills.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A finished quest: a flat row with a green tick and when it was done.
class QuestCompletedCard extends StatelessWidget {
  const QuestCompletedCard({super.key, this.completedAt});

  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final at = completedAt;
    return AppSurface(
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.successColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              Icons.check_rounded,
              size: AppIcon.md,
              color: AppColors.successColor,
            ),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed',
                  style:
                      AppText.body(AppColors.textPrimary, weight: AppText.bold),
                ),
                Text(
                  at == null
                      ? 'Reward added'
                      : 'Reward added · ${formatQuestAge(at)}',
                  style: AppText.label(AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted hint under a manual quest that has no proof yet.
class QuestManualHint extends StatelessWidget {
  const QuestManualHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Send proof above to finish this quest.',
      style: AppText.label(AppColors.textFaint),
    );
  }
}

/// Outcome of a verify attempt, as a plain dialog.
Future<void> showQuestResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  required bool isSuccess,
  String closeLabel = 'Close',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: AppIcon.md,
            color: isSuccess ? AppColors.successColor : AppColors.warning500,
          ),
          AppSpace.wGapSm,
          Expanded(
            child: Text(
              title,
              style:
                  AppText.subtitle(AppColors.textPrimary, weight: AppText.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(message, style: AppText.body(AppColors.textSecondary)),
      ),
      actions: [
        AppButton(
          label: closeLabel,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
