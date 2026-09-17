import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_boost.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:flutter/material.dart';

/// `Active means mined in the last 7 days.`, from the config window.
String mineActiveRule(MineBoost boost) {
  final days = (boost.config.activeReferralWindowHours / 24).round();
  return 'Active means mined in the last ${days == 1 ? '1 day' : '$days days'}.';
}

/// Big figure then a caption on one baseline: `+10%  2 active friends · …`.
class MineBoostHeadline extends StatelessWidget {
  const MineBoostHeadline({
    super.key,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String value;
  final String caption;

  /// Defaults to the accent.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: AppText.headline(valueColor ?? MinePalette.accentSoft)
              .merge(AppText.tabular)
              .copyWith(height: 1),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(caption, style: AppText.label(MinePalette.muted)),
        ),
      ],
    );
  }
}

/// One segment per friend the cap allows; filled segments are the boost.
class MineBoostMeter extends StatelessWidget {
  const MineBoostMeter({super.key, required this.boost});

  final MineBoost boost;

  @override
  Widget build(BuildContext context) {
    final filled = boost.filledSegments;
    return Semantics(
      label: '${boost.percent} of ${boost.maxPercent}',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.md),
        child: Row(
          children: [
            for (var i = 0; i < boost.segments; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.hair),
              Expanded(
                child: Container(
                  key: ValueKey('mine-meter-${i < filled ? 'on' : 'off'}'),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < filled ? MinePalette.accent : MinePalette.raised,
                    borderRadius: AppRadius.full,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muted rule line under the meter.
class MineRuleText extends StatelessWidget {
  const MineRuleText(this.text, {super.key, this.lead});

  final String text;

  /// Optional bold lead, e.g. `+5%`.
  final String? lead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Text.rich(
        TextSpan(
          children: [
            if (lead != null)
              TextSpan(
                text: lead,
                style: TextStyle(
                  color: MinePalette.text,
                  fontWeight: AppText.bold,
                ),
              ),
            TextSpan(text: text),
          ],
        ),
        style: AppText.label(MinePalette.muted),
      ),
    );
  }
}

/// `Have a friend's code?` with its deadline, only while binding is open.
class MineFriendCodeRow extends StatelessWidget {
  const MineFriendCodeRow({
    super.key,
    required this.until,
    required this.now,
    required this.onTap,
  });

  final DateTime? until;
  final DateTime now;
  final VoidCallback onTap;

  static String deadlineLabel(DateTime? until, DateTime now) {
    if (until == null) return 'Today only';
    if (MineFormat.dayGap(until, now) <= 0) return 'Today only';
    return 'Until ${MineFormat.relativeDay(until, now)} at '
        '${MineFormat.clock(until)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('mine-friend-code'),
          onTap: onTap,
          borderRadius: AppRadius.md,
          child: Ink(
            padding: AppSpace.row,
            decoration: mineTileDecoration(
              ground: MinePalette.raised.withValues(alpha: 0.5),
              radius: AppRadius.md,
            ),
            child: Row(
              children: [
                Icon(Icons.how_to_reg_outlined,
                    size: AppIcon.md, color: MinePalette.accentSoft),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    "Have a friend's code?",
                    style:
                        AppText.label(MinePalette.text, weight: AppText.bold),
                  ),
                ),
                Text(
                  deadlineLabel(until, now),
                  style:
                      AppText.caption(MinePalette.amber, weight: AppText.bold),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppIcon.md,
                  color: MinePalette.faint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
