import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_boost_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_code_actions.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:flutter/material.dart';

/// The flat card every Earn faster block sits in.
class MineEarnCardFrame extends StatelessWidget {
  const MineEarnCardFrame({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      padding: padding ?? AppSpace.card,
      decoration: mineTileDecoration(),
      child: child,
    );
  }
}

/// Boost, meter, rule, code and Share / Copy.
///
/// [expanded] is the sub-screen version: the rule names the per-friend rate
/// and the cap, and [footer] (the friend-code row) can follow.
class MineEarnFasterCard extends StatelessWidget {
  const MineEarnFasterCard({
    super.key,
    required this.boost,
    required this.code,
    this.expanded = false,
    this.footer,
  });

  final MineBoost boost;
  final String? code;
  final bool expanded;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return MineEarnCardFrame(
      child: Column(
        key: const ValueKey('mine-earn-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MineBoostHeadline(value: boost.percent, caption: boost.boostCaption),
          MineBoostMeter(boost: boost),
          if (expanded)
            MineRuleText(
              ' per active friend, max ${boost.maxPercent}. '
              '${mineActiveRule(boost)}',
              lead: boost.perFriendPercent,
            )
          else
            MineRuleText(mineActiveRule(boost)),
          MineCodeActions(code: code),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// No friends yet: the invitation, in the member's own numbers.
class MineInviteCard extends StatelessWidget {
  const MineInviteCard({
    super.key,
    required this.boost,
    required this.code,
    this.footer,
  });

  final MineBoost boost;
  final String? code;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final withFriend = MineFormat.points(boost.pointsPerCycleWithOneMore());
    return MineEarnCardFrame(
      child: Column(
        key: const ValueKey('mine-invite-card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.sm),
          const Icon(Icons.group_add_outlined,
              size: AppIcon.xl, color: MinePalette.accent),
          const SizedBox(height: AppSpace.md),
          Text(
            'Invite a friend, earn $withFriend BNP ${boost.perCycleUnit}',
            textAlign: TextAlign.center,
            style: AppText.subtitle(MinePalette.white, weight: AppText.bold),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${boost.perFriendRule}.',
            textAlign: TextAlign.center,
            style: AppText.label(MinePalette.faint).copyWith(height: 1.55),
          ),
          MineCodeActions(code: code),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// `120 BNP a day · 5 BNP/hr`, the empty meter and `No boost yet.`
class MineRateNowCard extends StatelessWidget {
  const MineRateNowCard({super.key, required this.boost});

  final MineBoost boost;

  @override
  Widget build(BuildContext context) {
    return MineEarnCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MineBoostHeadline(
            value: '${MineFormat.points(boost.pointsPerCycle())} BNP',
            caption: '${boost.perCycleUnit} · ${boost.baseRate} BNP/hr',
            valueColor: MinePalette.white,
          ),
          MineBoostMeter(boost: boost),
          MineRuleText(boost.hasBoost ? boost.sideLine : 'No boost yet.'),
        ],
      ),
    );
  }
}
