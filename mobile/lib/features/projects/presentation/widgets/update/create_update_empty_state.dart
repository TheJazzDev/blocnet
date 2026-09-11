import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';

/// Empty state for Create Update when the account has no project it can post
/// to. Explains how a project gets assigned and offers the one action the
/// user can take right now: submitting a new gem.
class CreateUpdateEmptyState extends StatelessWidget {
  const CreateUpdateEmptyState({super.key, required this.isHunterRestricted});

  final bool isHunterRestricted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHunterRestricted
                ? 'No projects are assigned to your hunter account yet.'
                : 'No project is available for updates yet.',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'An admin assigns projects to hunters from the console. If you '
            'have found a project worth tracking, submit it as a new gem and '
            'it can be assigned to you once approved.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.submitProject),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(42),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
              ),
              icon: const Icon(Icons.diamond_outlined, size: AppIcon.md),
              label: const Text('Submit a new gem'),
            ),
          ),
        ],
      ),
    );
  }
}
