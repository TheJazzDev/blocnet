import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/day_one/day_one_step.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A hunter with no gems: what a gem is, and the two ways to get one.
///
/// Step 2 is only tappable when there is an invite to go to; otherwise it
/// says so in muted text and carries no chevron.
class DayOneCard extends StatelessWidget {
  const DayOneCard({
    super.key,
    required this.onSubmitGem,
    required this.onShowInvites,
  });

  final VoidCallback onSubmitGem;

  /// Null when there are no invites.
  final VoidCallback? onShowInvites;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.reliableTop, AppColors.reliableBottom],
        ),
        border: Border.all(color: AppColors.chainIce.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.chainIce.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: AppColors.chainIce,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're a hunter now",
            style: AppTypography.custom(
              size: 24,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A gem is a project you found and now own. You post it, and you '
            'keep posting every time it moves — that obligation is what '
            'members follow you for.',
            style: HubType.body(AppColors.zincMuted, height: 1.55),
          ),
          const SizedBox(height: 20),
          DayOneStep(
            key: const ValueKey('day-one-submit'),
            number: 1,
            title: 'Submit your first gem',
            subtitle: 'Diligence, then a first update',
            onTap: onSubmitGem,
          ),
          const SizedBox(height: 10),
          DayOneStep(
            key: const ValueKey('day-one-invite'),
            number: 2,
            title: 'Or accept an invite',
            subtitle: onShowInvites == null
                ? 'No invites yet'
                : 'Co-own a gem already running',
            onTap: onShowInvites,
          ),
        ],
      ),
    );
  }
}
