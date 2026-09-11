import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_requirement.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_requirement_row.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_status_chip.dart';
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LevelDetailSheet(
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpace.md),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
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
                    const SizedBox(height: AppSpace.lg),
                    if (level.description.isNotEmpty) ...[
                      _DescriptionBox(text: level.description),
                      const SizedBox(height: AppSpace.lg),
                    ],
                    _RequirementsTitle(
                      isCurrent: isCurrent,
                      isLocked: isLocked,
                      metCount: metCount,
                      total: requirements.length,
                      tierColor: tierColor,
                    ),
                    const SizedBox(height: AppSpace.md),
                    if (requirements.isEmpty)
                      const _NoRequirements()
                    else
                      for (final requirement in requirements)
                        LevelRequirementRow(
                          requirement: requirement,
                          tierColor: tierColor,
                        ),
                    const SizedBox(height: AppSpace.md),
                    _CloseButton(tierColor: tierColor),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.name,
                style: AppTypography.custom(
                  color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.hair),
              Text(
                'Level ${level.level} · ${level.tier.name} tier',
                style: AppTypography.custom(
                  color: tierColor,
                  size: AppText.captionSize,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              _statusChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    if (isCurrent) {
      return LevelStatusChip(label: 'YOUR CURRENT LEVEL', color: tierColor);
    }
    if (isLocked) {
      return LevelStatusChip(
        label: 'LOCKED',
        color: AppColors.textMuted,
        filled: false,
        icon: Icons.lock_outline_rounded,
      );
    }
    return LevelStatusChip(
      label: 'UNLOCKED',
      color: tierColor,
      filled: false,
      icon: Icons.check_rounded,
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  const _DescriptionBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
      ),
      child: Text(
        text,
        style: AppTypography.custom(
          color: AppColors.textSecondary,
          size: AppText.bodySize,
          weight: FontWeight.w400,
          height: 1.45,
        ),
      ),
    );
  }
}

class _RequirementsTitle extends StatelessWidget {
  const _RequirementsTitle({
    required this.isCurrent,
    required this.isLocked,
    required this.metCount,
    required this.total,
    required this.tierColor,
  });

  final bool isCurrent;
  final bool isLocked;
  final int metCount;
  final int total;
  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final title = isLocked
        ? 'Requirements to unlock'
        : isCurrent
            ? 'What got you here'
            : 'Requirements';

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
        if (total > 0)
          Text(
            '$metCount/$total met',
            style: AppTypography.custom(
              color: metCount >= total ? tierColor : AppColors.textMuted,
              size: AppText.captionSize,
              weight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _NoRequirements extends StatelessWidget {
  const _NoRequirements();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No requirements — this is where everyone starts.',
        style: AppTypography.custom(
          color: AppColors.textMuted,
          size: AppText.labelSize,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.tierColor});

  final Color tierColor;

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundOn(tierColor);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: tierColor,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
          ),
        ),
        child: Text(
          'Close',
          style: AppTypography.custom(
            color: foreground,
            size: AppText.labelSize,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
