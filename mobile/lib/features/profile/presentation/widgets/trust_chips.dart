import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/data/models/public_profile_model.dart';
import 'package:flutter/material.dart';

class TrustChips extends StatelessWidget {
  const TrustChips({super.key, required this.trust});

  final PublicProfileTrust trust;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TrustChip(
            label: 'Updates (7d)',
            value: '${trust.updatesLast7d}',
          ),
          TrustChip(
            label: 'Updates (30d)',
            value: '${trust.updatesLast30d}',
          ),
          TrustChip(
            label: 'High-Urgency Share',
            value: '${trust.highUrgencyShare30d.toStringAsFixed(0)}%',
          ),
          TrustChip(
            label: 'Median Posting Interval',
            value: trust.medianHoursBetweenUpdates == null
                ? 'N/A'
                : '${trust.medianHoursBetweenUpdates!.toStringAsFixed(1)}h',
          ),
        ],
      ),
    );
  }
}

class TrustChip extends StatelessWidget {
  const TrustChip({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.custom(
            size: 10,
            weight: FontWeight.w400,
            color: AppColors.textFaint,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: AppColors.textFaint),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
