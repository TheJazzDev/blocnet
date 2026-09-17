import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/widgets/main_tab_scope.dart';
import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_history.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_card.dart';
import 'package:blocnet/features/mining/presentation/widgets/earn_faster/mine_earn_faster_cards.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_preview.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_notices.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';

/// The Mine tab, top to bottom, once a snapshot exists.
class MineTabBody extends StatelessWidget {
  const MineTabBody({
    super.key,
    required this.store,
    required this.snapshot,
    required this.phase,
    required this.dismissedExpired,
    required this.onStart,
    required this.onClaim,
    required this.onDismissExpired,
  });

  final MiningStore store;
  final MiningSnapshot snapshot;
  final MineCyclePhase phase;
  final Set<String> dismissedExpired;
  final VoidCallback onStart;
  final VoidCallback onClaim;
  final ValueChanged<String> onDismissExpired;

  @override
  Widget build(BuildContext context) {
    final referral = store.referralSummary;
    final activeFriends = referral?.activeDirectReferrals ?? 0;
    final boost = MineBoost.forFriends(snapshot.config, activeFriends);
    final expired = snapshot.lastExpiredCycle;
    final showExpired = expired != null &&
        MineExpiredNotice.isCurrent(snapshot) &&
        !dismissedExpired.contains(expired.sessionId);
    final groups = MineHistory.group(
      snapshot.hourlyHistory,
      currentSessionId: snapshot.session.isRunning ? snapshot.session.id : null,
    );
    final history = _history(context, groups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.xs),
        if (showExpired)
          MineExpiredNotice(
            cycle: expired,
            claimWindowHours: snapshot.config.claimWindowHours,
            onDismiss: () => onDismissExpired(expired.sessionId),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: MineCycleCard(
            snapshot: snapshot,
            activeFriends: activeFriends,
            serverNow: store.serverNow,
            onStart: onStart,
            onClaim: onClaim,
            isStarting: store.isStarting,
            isClaiming: store.isClaiming,
            onCycleEnd: store.refreshAtCycleEnd,
          ),
        ),
        const MineSectionHeader(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Balance',
        ),
        MineBalanceCard(
          balance: snapshot.balance.claimedTotalPoints,
          onOpenWallet: () =>
              MainTabScope.maybeOf(context)?.selectTab(MainTabScope.walletTab),
        ),
        // D2: while a lost cycle is being reported, its record comes first.
        if (showExpired) ...history,
        if (snapshot.config.referralsEnabled) ...[
          MineSectionHeader(
            icon: Icons.trending_up_rounded,
            title: 'Earn faster',
            trailing: boost.hasBoost ? boost.percent : null,
          ),
          _earnFaster(context, boost, referral?.code),
        ],
        if (store.leaderboardTop.isNotEmpty || store.leaderboardMe != null)
          MineLeaderboardPreview(
            top: store.leaderboardTop,
            me: store.leaderboardMe,
            onOpen: () =>
                Navigator.of(context).pushNamed(AppRoutes.miningLeaderboard),
          ),
        if (!showExpired) ...history,
        const SizedBox(height: AppSpace.xxl),
      ],
    );
  }

  /// D1: the full card only when the cycle card has no primary button.
  Widget _earnFaster(BuildContext context, MineBoost boost, String? code) {
    if (phase == MineCyclePhase.running) {
      return MineEarnFasterCard(boost: boost, code: code);
    }
    final paused = phase == MineCyclePhase.paused;
    final hasFriends = boost.activeFriends > 0;
    return MineLinkRow(
      key: const ValueKey('mine-earn-row'),
      icon: Icons.group_add_outlined,
      title: hasFriends ? boost.rowTitle : 'Invite friends',
      subtitle: paused && hasFriends
          ? 'Applies when mining is back'
          : hasFriends
              ? boost.perFriendRule
              : '${boost.perFriendPercent} per active friend',
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.miningEarnFaster),
    );
  }

  List<Widget> _history(BuildContext context, List<MineHistoryGroup> groups) {
    final summary = MineHistory.summary(groups);
    if (summary == null) return const [];
    return [
      const MineSectionHeader(
        icon: Icons.schedule_rounded,
        title: 'Hourly history',
      ),
      MineLinkRow(
        key: const ValueKey('mine-history-row'),
        icon: Icons.history_rounded,
        title: 'Last 2 days',
        subtitle: summary,
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.miningHourlyHistory),
      ),
    ];
  }
}
