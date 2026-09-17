import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Icon, tone (tag, icons) and ring colour per phase, as the old hero's
/// status tag: grey idle, accent live, green ready, amber paused / closing.
/// The ring stays in the space accent in every phase.
class MinePhaseStyle {
  const MinePhaseStyle({
    required this.icon,
    required this.tone,
    required this.ringColor,
    this.quiet = false,
  });

  final IconData icon;
  final Color tone;
  final Color ringColor;

  /// Idle and paused: nothing is being earned, so the core stays dim.
  final bool quiet;

  static MinePhaseStyle of(MineCyclePhase phase) {
    switch (phase) {
      case MineCyclePhase.running:
        return MinePhaseStyle(
          icon: Icons.bolt_rounded,
          tone: MinePalette.accent,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.ready:
        return MinePhaseStyle(
          icon: Icons.check_circle_rounded,
          tone: MinePalette.success,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.closingSoon:
        return MinePhaseStyle(
          icon: Icons.timer_rounded,
          tone: MinePalette.amber,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.paused:
        return MinePhaseStyle(
          icon: Icons.pause_circle_outline_rounded,
          tone: MinePalette.amber,
          ringColor: MinePalette.accent,
          quiet: true,
        );
      case MineCyclePhase.idle:
      case MineCyclePhase.loading:
      case MineCyclePhase.loadError:
        return MinePhaseStyle(
          icon: Icons.pause_circle_outline_rounded,
          tone: MinePalette.faint,
          ringColor: MinePalette.accent,
          quiet: true,
        );
    }
  }
}

/// Old hero header: icon and `Hour 9 of 24` on the left, `MINING` tag right.
class MineStatusRow extends StatelessWidget {
  const MineStatusRow({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    final style = MinePhaseStyle.of(view.phase);
    return Row(
      children: [
        Icon(
          style.icon,
          size: AppIcon.md,
          color: style.quiet ? MinePalette.faint : style.tone,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            view.rightLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(MinePalette.muted),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        AppPill.caps(label: view.pill, color: style.tone),
      ],
    );
  }
}

/// `Ready tomorrow at 09:20` bold, ` · 15h left` muted, centred.
class MineWhenLine extends StatelessWidget {
  const MineWhenLine({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: view.whenBold,
        children: [
          TextSpan(
            text: view.whenMuted,
            style: TextStyle(
              color: MinePalette.muted,
              fontWeight: AppText.medium,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: AppText.subtitle(MinePalette.text, weight: AppText.bold),
    );
  }
}

/// Icon, number and unit inside the core.
class MineRingCenter extends StatelessWidget {
  const MineRingCenter({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    final style = MinePhaseStyle.of(view.phase);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          style.icon,
          size: view.centerNumber == null ? AppIcon.lg : AppIcon.sm,
          color: style.quiet ? MinePalette.faint : style.tone,
        ),
        const SizedBox(height: AppSpace.hair),
        if (view.centerNumber != null)
          Text(
            view.centerNumber!,
            style: AppText.headline(MinePalette.text)
                .merge(AppText.tabular)
                .copyWith(height: 1.1),
          ),
        Text(
          view.centerUnit,
          style: AppText.caption(MinePalette.muted, weight: AppText.semibold),
        ),
      ],
    );
  }
}

/// The rate (or the closing-soon warning) as an old stat tile: icon in a
/// tinted square, the value, and the boost line under it.
class MineSideColumn extends StatelessWidget {
  const MineSideColumn({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    final top = view.sideTop;
    final bottom = view.sideBottom;
    if (top == null && bottom == null) return const SizedBox.shrink();
    final tone = view.isAmber ? MinePalette.amber : MinePalette.accent;
    return Container(
      padding: AppSpace.allMd,
      decoration: BoxDecoration(
        color: MinePalette.raised.withValues(alpha: 0.5),
        borderRadius: AppRadius.lg,
        border: Border.all(color: MinePalette.edge.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          AppIconSquare(
            icon: view.isAmber ? Icons.timer_outlined : Icons.speed_rounded,
            color: tone,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (top != null)
                  Text(
                    top,
                    style:
                        AppText.label(MinePalette.text, weight: AppText.bold),
                  ),
                if (bottom != null) ...[
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    bottom,
                    style: AppText.caption(
                      MinePalette.faint,
                      weight: AppText.semibold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The card's one primary action, in the old Mine button's shape.
class MinePrimaryButton extends StatelessWidget {
  const MinePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  /// Defaults to the accent.
  final Color? color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ground = color ?? MinePalette.accent;
    final fg = ThemeData.estimateBrightnessForColor(ground) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: ground,
        borderRadius: AppRadius.lg,
        child: InkWell(
          borderRadius: AppRadius.lg,
          onTap: busy ? null : onPressed,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox.square(
                    dimension: AppIcon.sm,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  Icon(icon, size: AppIcon.sm, color: fg),
                const SizedBox(width: AppSpace.sm),
                Text(
                  label,
                  style: AppText.body(fg, weight: AppText.bold)
                      .copyWith(letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
