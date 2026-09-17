import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Grab handle (as a sheet), title and close button.
class PublicProfileHeader extends StatelessWidget {
  const PublicProfileHeader({super.key, required this.asSheet});

  final bool asSheet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (asSheet)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.md),
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.borderMuted,
                borderRadius: AppRadius.full,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.xs, AppSpace.xs, AppSpace.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Profile',
                  style: AppText.subtitle(AppColors.textPrimary,
                      weight: AppText.bold),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `120 followers · 34 updates · 5 gems`.
class PublicProfileCounts extends StatelessWidget {
  const PublicProfileCounts({
    super.key,
    required this.followers,
    required this.updates,
    required this.gems,
  });

  final int followers;
  final int updates;
  final int gems;

  static String _count(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  @override
  Widget build(BuildContext context) {
    return Text(
      [
        _count(followers, 'follower', 'followers'),
        _count(updates, 'update', 'updates'),
        _count(gems, 'gem', 'gems'),
      ].join(' · '),
      style: AppText.label(AppColors.textMuted, weight: AppText.medium),
    );
  }
}
