import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/follow_preference_model.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

Future<void> showFollowPreferenceBottomSheet(
  BuildContext context, {
  required String projectId,
  required String projectName,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FollowPreferenceSheet(
      projectId: projectId,
      projectName: projectName,
    ),
  );
}

class _FollowPreferenceSheet extends StatelessWidget {
  const _FollowPreferenceSheet({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectsStore>();
    final preference = store.preferenceForProject(projectId);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(AppRadius.fullValue),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Alert Preferences',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.subtitleSize,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              projectName,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (final level in FollowAlertLevel.values) ...[
              _PreferenceTile(
                label: level.label,
                selected: preference.alertLevel == level,
                onTap: () => store.updateFollowPreferences(
                  projectId,
                  alertLevel: level,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            const SizedBox(height: AppSpace.sm),
            _MuteTile(
              mutedUntil: preference.mutedUntil,
              onMute: () => store.updateFollowPreferences(
                projectId,
                mutedUntil:
                    DateTime.now().toUtc().add(const Duration(hours: 24)),
              ),
              onUnmute: () =>
                  store.updateFollowPreferences(projectId, clearMute: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.15),
                    AppColors.primary500.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: selected ? null : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.lgValue),
          border: Border.all(
            color: selected
                ? AppColors.primary500.withValues(alpha: 0.3)
                : AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: AppIcon.md,
              color: selected ? AppColors.primary400 : AppColors.textFaint,
            ),
            const SizedBox(width: AppSpace.md),
            Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.bodySize,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuteTile extends StatelessWidget {
  const _MuteTile({
    required this.mutedUntil,
    required this.onMute,
    required this.onUnmute,
  });

  final DateTime? mutedUntil;
  final VoidCallback onMute;
  final VoidCallback onUnmute;

  @override
  Widget build(BuildContext context) {
    final isMuted = mutedUntil != null && mutedUntil!.isAfter(DateTime.now());
    final message = isMuted
        ? 'Muted until ${mutedUntil!.toLocal().toString().substring(0, 16)}'
        : 'Mute alerts for 24 hours';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: isMuted
                  ? AppColors.error500.withValues(alpha: 0.12)
                  : AppColors.primary500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child: Icon(
              isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: AppIcon.md,
              color: isMuted ? AppColors.error500 : AppColors.primary400,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          TextButton(
            onPressed: isMuted ? onUnmute : onMute,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: AppSpace.sm),
              backgroundColor: isMuted
                  ? AppColors.error500.withValues(alpha: 0.12)
                  : AppColors.primary500.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.smValue),
              ),
            ),
            child: Text(
              isMuted ? 'Unmute' : 'Mute',
              style: AppTypography.custom(
                color: isMuted ? AppColors.error500 : AppColors.primary400,
                size: AppText.labelSize,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
