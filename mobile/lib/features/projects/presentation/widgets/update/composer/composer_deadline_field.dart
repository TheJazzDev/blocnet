import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';

/// Picks the moment a window closes, and shows it back in the same words the
/// feed will use, so a hunter sees what members will read.
class ComposerDeadlineField extends StatelessWidget {
  const ComposerDeadlineField({
    super.key,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final at = value;
    final tone = at == null ? AppColors.textFaint : AppColors.textSecondary;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onPick,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md,
                vertical: AppSpace.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgBase,
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: AppIcon.sm, color: tone),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      at == null
                          ? 'No closing window'
                          : describeDeadline(at, DateTime.now()).label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        color: tone,
                        size: AppText.bodySize,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (at != null) ...[
          const SizedBox(width: AppSpace.sm),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.close_rounded,
                size: AppIcon.sm,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Date then time. Two steps rather than one, because a window that "closes
/// Friday" and one that "closes Friday 18:00 UTC" are different promises and
/// the hunter should have to state which they mean.
Future<DateTime?> pickComposerDeadline(
  BuildContext context,
  DateTime? current,
) async {
  final now = DateTime.now();
  final seed = current ?? now.add(const Duration(days: 1));
  final date = await showDatePicker(
    context: context,
    initialDate: seed,
    // A past window is legitimate to report, so yesterday is selectable.
    firstDate: now.subtract(const Duration(days: 30)),
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(seed),
  );
  return DateTime(
    date.year,
    date.month,
    date.day,
    time?.hour ?? 23,
    time?.minute ?? 59,
  );
}
