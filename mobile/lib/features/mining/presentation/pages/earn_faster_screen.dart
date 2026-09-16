import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_boost_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_earn_faster_cards.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_friends_list.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sub_header.dart';
import 'package:blocnet/features/mining/presentation/widgets/referral_bind_sheet.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Earn faster: the boost, the member's code, the friend-code row while it
/// is open, and the friends list. Also served at `/referral-code`.
class EarnFasterScreen extends StatefulWidget {
  const EarnFasterScreen({super.key});

  @override
  State<EarnFasterScreen> createState() => _EarnFasterScreenState();
}

class _EarnFasterScreenState extends State<EarnFasterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<MiningStore>();
      unawaited(store.loadSnapshot());
      unawaited(store.loadReferralSummary(force: true));
      // The friends list belongs to this screen, not every Mine refresh.
      unawaited(store.loadDownline(force: true));
    });
  }

  Future<void> _enterCode(MiningStore store) async {
    final bound = await showReferralBindSheet(context, store);
    if (!mounted || !bound) return;
    AppSnackbar.showSuccess(context, 'Friend linked');
  }

  Future<void> _refresh(MiningStore store) async {
    await Future.wait([
      store.loadReferralSummary(force: true),
      store.loadDownline(force: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MiningStore>();
    final config = store.snapshot?.config;
    final referral = store.referralSummary;
    final now = store.serverNow();

    return Scaffold(
      backgroundColor: MinePalette.ground,
      appBar: const MineSubHeader(title: 'Earn faster'),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () => _refresh(store),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpace.xxl),
          children: config == null
              ? [
                  if (store.isLoadingSnapshot)
                    const Padding(
                      padding: EdgeInsets.all(AppSpace.xxxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ]
              : _content(store, config, referral, now),
        ),
      ),
    );
  }

  List<Widget> _content(
    MiningStore store,
    MiningConfigModel config,
    ReferralSummaryModel? referral,
    DateTime now,
  ) {
    final friends = store.downline;
    final total = referral?.totalDirectReferrals ?? friends.length;
    final active = referral?.activeDirectReferrals ??
        friends.where((friend) => friend.isActive).length;
    final boost = MineBoost.forFriends(config, active);
    final canBind =
        referral != null && referral.bindWindowOpen && !referral.isBound;
    final codeRow = canBind
        ? MineFriendCodeRow(
            until: referral.canBindUntil,
            now: now,
            onTap: () => _enterCode(store),
          )
        : null;
    final hasFriends = total > 0 || friends.isNotEmpty;

    if (!hasFriends) {
      return [
        const SizedBox(height: AppSpace.xs),
        MineInviteCard(boost: boost, code: referral?.code, footer: codeRow),
        const MineSectionHeader(
            icon: Icons.bolt_rounded, title: 'Your rate now'),
        MineRateNowCard(boost: boost),
      ];
    }

    return [
      const SizedBox(height: AppSpace.xs),
      MineEarnFasterCard(
        boost: boost,
        code: referral?.code,
        expanded: true,
        footer: codeRow,
      ),
      MineSectionHeader(
        icon: Icons.groups_outlined,
        title: 'Your friends',
        trailing: '$active of $total active',
      ),
      if (friends.isNotEmpty)
        MineFriendsList(
          friends: friends,
          perFriendPercent: boost.perFriendPercent,
          now: now,
        )
      else if (store.isLoadingDownline)
        const Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        )
      else if (store.downlineError != null)
        MineEarnCardFrame(
          child: MineRuleText("Couldn't load your friends. Pull to retry."),
        ),
    ];
  }
}
