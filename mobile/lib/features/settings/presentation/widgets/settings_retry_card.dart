import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:flutter/material.dart';

/// Shown in place of the notification sections when they fail to load.
class SettingsRetryCard extends StatelessWidget {
  const SettingsRetryCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ProfileRowGroup(
      children: [
        Padding(
          padding: AppSpace.card,
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: AppIcon.md, color: AppColors.textFaint),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  'Could not load notification settings',
                  style: AppText.body(AppColors.textSecondary,
                      weight: AppText.medium),
                ),
              ),
              AppSpace.wGapSm,
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderMuted),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.md),
                  ),
                  child: Text(
                    'Retry',
                    style: AppText.label(AppColors.primary400,
                        weight: AppText.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
