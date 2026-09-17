import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_requirement_row.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Bottom sheet with a level's description and all of its unlock criteria,
/// compared against the user's raw metrics. Opens for any level, locked or
/// not.
class LevelDetailSheet extends StatelessWidget {
  const LevelDetailSheet({
    super.key,
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.myProgress,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final UserLevelProgressModel? myProgress;

  static void show(
    BuildContext context, {
    required UserLevelModel level,
    required bool isCurrent,
    required bool isLocked,
    required UserLevelProgressModel? myProgress,
  }) {
    AppSheet.show<void>(
      context: context,
      title: 'Level ${level.level}',
      icon: Icons.military_tech_outlined,
      builder: (_) => LevelDetailSheet(
        level: level,
        isCurrent: isCurrent,
        isLocked: isLocked,
        myProgress: myProgress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = level.tierColor;
    final requirements = requirementsFor(level, metrics: myProgress?.metrics);
    final metCount = requirements.where((r) => r.isComplete).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            level: level,
            tierColor: tierColor,
            isCurrent: isCurrent,
            isLocked: isLocked,
          ),
          if (level.description.isNotEmpty) ...[
            AppSpace.gapLg,
            Text(
              level.description,
              style: AppText.body(AppColors.textSecondary),
            ),
          ],
          AppSpace.gapXl,
          _RequirementsCard(
            title: isLocked
                ? 'Requirements to unlock'
                : isCurrent
                    ? 'What got you here'
                    : 'Requirements',
            metCount: metCount,
            requirements: requirements,
            tierColor: tierColor,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.level,
    required this.tierColor,
    required this.isCurrent,
    required this.isLocked,
  });

  final UserLevelModel level;
  final Color tierColor;
  final bool isCurrent;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Opacity(
          opacity: isLocked ? 0.5 : 1,
          child: LevelBadge(
            level: level,
            size: LevelBadgeSize.large,
            showName: false,
            showLevelNumber: false,
          ),
        ),
        AppSpace.wGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subtitle(
                  isLocked ? AppColors.textMuted : AppColors.textPrimary,
                  weight: AppText.bold,
                ),
              ),
              AppSpace.gapXs,
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  LevelStatusChip(
                    label: level.tier.name,
                    color: tierColor,
                    filled: false,
                  ),
                  _statusChip(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    if (isCurrent) {
      return LevelStatusChip(
        label: 'Current',
        color: AppColors.successColor,
        filled: false,
      );
    }
    if (isLocked) {
      return LevelStatusChip(
        label: 'Locked',
        color: AppColors.textMuted,
        filled: false,
        icon: Icons.lock_outline_rounded,
      );
    }
    return LevelStatusChip(
      label: 'Unlocked',
      color: AppColors.successColor,
      filled: false,
      icon: Icons.check_rounded,
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({
    required this.title,
    required this.metCount,
    required this.requirements,
    required this.tierColor,
  });

  final String title;
  final int metCount;
  final List<LevelRequirement> requirements;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final total = requirements.length;
    return AppSurface.flush(
      tone: AppSurfaceTone.base,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppText.caption(
                      AppColors.textFaint,
                      weight: AppText.bold,
                    ).copyWith(letterSpacing: 1.0),
                  ),
                ),
                if (total > 0)
                  Text(
                    '$metCount/$total met',
                    style: AppText.caption(
                      metCount >= total
                          ? AppColors.successColor
                          : AppColors.textMuted,
                      weight: AppText.semibold,
                    ),
                  ),
              ],
            ),
          ),
          if (requirements.isEmpty)
            Padding(
              padding: AppSpace.row,
              child: Text(
                'None. Everyone starts here.',
                style: AppText.label(AppColors.textMuted),
              ),
            )
          else
            for (var i = 0; i < requirements.length; i++) ...[
              if (i > 0) Divider(height: 1, color: AppColors.borderSubtle),
              LevelRequirementRow(
                requirement: requirements[i],
                tierColor: tierColor,
              ),
            ],
        ],
      ),
    );
  }
}
