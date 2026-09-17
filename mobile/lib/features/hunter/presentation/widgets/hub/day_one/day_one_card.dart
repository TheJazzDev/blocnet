import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/day_one/day_one_step.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A hunter with no gems: what a gem is, and the two ways to get one.
///
/// A flat, left-aligned card with a small icon beside its title.
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
      margin: const EdgeInsets.fromLTRB(
        HubInsets.gutter,
        AppSpace.xs,
        HubInsets.gutter,
        0,
      ),
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: AppIcon.md,
                color: HubTone.accent,
              ),
              AppSpace.wGapSm,
              Expanded(
                child: Text(
                  "You're a hunter now",
                  style: AppText.title(AppColors.textPrimary),
                ),
              ),
            ],
          ),
          AppSpace.gapSm,
          Text(
            'A gem is a project you found and now own. You post it, and you '
            'keep posting every time it moves — that obligation is what '
            'members follow you for.',
            style: HubType.body(AppColors.textMuted),
          ),
          AppSpace.gapLg,
          DayOneStep(
            key: const ValueKey('day-one-submit'),
            number: 1,
            title: 'Submit your first gem',
            subtitle: 'Diligence, then a first update',
            onTap: onSubmitGem,
          ),
          AppSpace.gapSm,
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
