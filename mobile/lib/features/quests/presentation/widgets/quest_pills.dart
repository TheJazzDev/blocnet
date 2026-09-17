import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Presentation colours and icons for [QuestStatus], on [AppColors].
extension QuestStatusStyle on QuestStatus {
  Color get tone => switch (this) {
        QuestStatus.notStarted => AppColors.tagGeneral,
        QuestStatus.inProgress => AppColors.tagInfo,
        QuestStatus.pendingVerification => AppColors.warning500,
        QuestStatus.completed => AppColors.successColor,
      };

  /// The short word a status pill carries.
  String get pillLabel => switch (this) {
        QuestStatus.notStarted => 'New',
        QuestStatus.inProgress => 'In progress',
        QuestStatus.pendingVerification => 'In review',
        QuestStatus.completed => 'Done',
      };
}

/// "today", "3 days ago", "2 months ago".
String formatQuestAge(DateTime date, {DateTime? now}) {
  final days = (now ?? DateTime.now()).difference(date).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  if (days < 30) return '${days ~/ 7}w ago';
  return '${days ~/ 30}mo ago';
}

/// `250 BNP` in the reward colour.
class QuestPointsPill extends StatelessWidget {
  const QuestPointsPill({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: '$points BNP',
      color: AppColors.warning500,
      icon: Icons.stars_rounded,
      dense: true,
    );
  }
}

/// `IN REVIEW`, `DONE`, … in the status colour.
class QuestStatusPill extends StatelessWidget {
  const QuestStatusPill({super.key, required this.status});

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: status.pillLabel,
      color: status.tone,
      dense: true,
      uppercase: true,
    );
  }
}

/// A grey pill naming how the quest is done (`SOCIAL MEDIA`).
class QuestTypePill extends StatelessWidget {
  const QuestTypePill({super.key, required this.type});

  final QuestType type;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: type.displayName,
      color: AppColors.textMuted,
      icon: type.iconData,
      dense: true,
      uppercase: true,
    );
  }
}
