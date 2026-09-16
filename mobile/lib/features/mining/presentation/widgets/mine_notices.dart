import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:flutter/material.dart';

/// `+126 BNP claimed` over `Next cycle started.`, above the card.
class MineClaimReceipt extends StatelessWidget {
  const MineClaimReceipt({
    super.key,
    required this.points,
    required this.nextCycleStarted,
  });

  final int points;
  final bool nextCycleStarted;

  @override
  Widget build(BuildContext context) {
    return _NoticeFrame(
      key: const ValueKey('mine-claim-receipt'),
      ground: MinePalette.receiptGround,
      edge: MinePalette.receiptEdge,
      icon: Icons.check_circle_rounded,
      iconColor: MinePalette.accent,
      title: '+${MineFormat.points(points)} BNP claimed',
      body: nextCycleStarted ? 'Next cycle started.' : null,
    );
  }
}

/// `132 BNP expired` with the date, the window and a real Dismiss target.
class MineExpiredNotice extends StatelessWidget {
  const MineExpiredNotice({
    super.key,
    required this.cycle,
    required this.claimWindowHours,
    required this.onDismiss,
  });

  final MiningExpiredCycle cycle;
  final int claimWindowHours;
  final VoidCallback onDismiss;

  /// True while [snapshot]'s forfeit is news: it happened at or after the
  /// current cycle began, or nothing is running. Older forfeits are history.
  static bool isCurrent(MiningSnapshot? snapshot) {
    final cycle = snapshot?.lastExpiredCycle;
    if (cycle == null) return false;
    final sessionStart = snapshot?.session.startsAt;
    if (sessionStart == null) return true;
    final expiredAt = cycle.expiredAt;
    if (expiredAt == null) return false;
    // The backend opens the replacement cycle at the moment of expiry.
    return !expiredAt
        .toUtc()
        .isBefore(sessionStart.toUtc().subtract(const Duration(minutes: 2)));
  }

  /// `Your 14 Sep cycle wasn't claimed within 48 hours.`
  static String sentence(MiningExpiredCycle cycle, int claimWindowHours) {
    final day = cycle.startsAt ?? cycle.endsAt;
    final which = day == null ? 'Your' : 'Your ${MineFormat.dayMonth(day)}';
    final hours = claimWindowHours == 1 ? '1 hour' : '$claimWindowHours hours';
    return "$which cycle wasn't claimed within $hours.";
  }

  @override
  Widget build(BuildContext context) {
    return _NoticeFrame(
      key: const ValueKey('mine-expired-notice'),
      ground: MinePalette.noticeGround,
      edge: MinePalette.noticeEdge,
      icon: Icons.timer_off_outlined,
      iconColor: MinePalette.amber,
      title: '${MineFormat.points(cycle.forfeitedPoints)} BNP expired',
      body: sentence(cycle, claimWindowHours),
      action: Semantics(
        button: true,
        child: InkWell(
          onTap: onDismiss,
          borderRadius: AppRadius.sm,
          // 44 px target around the design's 36 px button.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: mineTileDecoration(
                ground: Colors.transparent,
                edge: MinePalette.noticeButtonEdge,
                radius: AppRadius.sm,
              ),
              child: Text(
                'Dismiss',
                style:
                    AppText.label(MinePalette.body, weight: AppText.semibold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeFrame extends StatelessWidget {
  const _NoticeFrame({
    super.key,
    required this.ground,
    required this.edge,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.action,
  });

  final Color ground;
  final Color edge;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.md,
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: mineTileDecoration(ground: ground, edge: edge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIcon.sm, color: iconColor),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppText.body(
                    MinePalette.strong,
                    weight: AppText.semibold,
                  ),
                ),
              ),
            ],
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              body!,
              style: AppText.label(MinePalette.muted).copyWith(height: 1.6),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpace.sm),
            action!,
          ],
        ],
      ),
    );
  }
}
