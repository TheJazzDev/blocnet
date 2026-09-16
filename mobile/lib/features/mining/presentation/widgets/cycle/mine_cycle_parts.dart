import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:flutter/material.dart';

/// Pill colours and icon per phase.
class MinePhaseStyle {
  const MinePhaseStyle({
    required this.icon,
    required this.pillText,
    required this.pillGround,
    required this.ringColor,
  });

  final IconData icon;
  final Color pillText;
  final Color pillGround;
  final Color ringColor;

  static MinePhaseStyle of(MineCyclePhase phase) {
    switch (phase) {
      case MineCyclePhase.running:
        return const MinePhaseStyle(
          icon: Icons.bolt_rounded,
          pillText: MinePalette.accentSoft,
          pillGround: MinePalette.accentChip,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.ready:
        return const MinePhaseStyle(
          icon: Icons.check_circle_rounded,
          pillText: MinePalette.readyText,
          pillGround: MinePalette.readyChip,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.closingSoon:
        return const MinePhaseStyle(
          icon: Icons.timer_rounded,
          pillText: MinePalette.amberText,
          pillGround: MinePalette.amberChip,
          ringColor: MinePalette.amber,
        );
      case MineCyclePhase.paused:
        return const MinePhaseStyle(
          icon: Icons.pause_circle_outline_rounded,
          pillText: MinePalette.faint,
          pillGround: MinePalette.chip,
          ringColor: MinePalette.accent,
        );
      case MineCyclePhase.idle:
      case MineCyclePhase.loading:
      case MineCyclePhase.loadError:
        return const MinePhaseStyle(
          icon: Icons.pause_circle_outline_rounded,
          pillText: MinePalette.faint,
          pillGround: MinePalette.chip,
          ringColor: MinePalette.accent,
        );
    }
  }
}

/// `MINING` pill on the left, `Hour 9 of 24` on the right.
class MineStatusRow extends StatelessWidget {
  const MineStatusRow({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    final style = MinePhaseStyle.of(view.phase);
    final caps = AppText.caption(MinePalette.caption, weight: AppText.bold);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: style.pillGround,
            borderRadius: AppRadius.full,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: AppIcon.xs, color: style.pillText),
              const SizedBox(width: AppSpace.xs),
              Text(
                view.pill,
                style: AppText.caption(style.pillText, weight: AppText.bold)
                    .copyWith(letterSpacing: 1.3, height: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            view.rightLabel.toUpperCase(),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: caps.copyWith(letterSpacing: 0.7),
          ),
        ),
      ],
    );
  }
}

/// `Ready tomorrow at 09:20` in white, ` · 15h left` muted.
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
            style: const TextStyle(
              color: MinePalette.muted,
              fontWeight: AppText.medium,
            ),
          ),
        ],
      ),
      style: AppText.title(MinePalette.white)
          .copyWith(height: 1.25, letterSpacing: -0.4),
    );
  }
}

/// Icon, number and unit inside the ring.
class MineRingCenter extends StatelessWidget {
  const MineRingCenter({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    final style = MinePhaseStyle.of(view.phase);
    final quiet = view.phase == MineCyclePhase.idle ||
        view.phase == MineCyclePhase.paused;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          style.icon,
          size: AppIcon.sm,
          color: quiet
              ? MinePalette.caption
              : (view.isAmber ? MinePalette.amberText : MinePalette.accent),
        ),
        const SizedBox(height: AppSpace.hair),
        if (view.centerNumber != null)
          Text(
            view.centerNumber!,
            style: AppText.headline(MinePalette.white)
                .merge(AppText.tabular)
                .copyWith(height: 1),
          ),
        Text(
          view.centerUnit,
          style: AppText.caption(MinePalette.muted, weight: AppText.semibold),
        ),
      ],
    );
  }
}

/// `5 BNP/hr` over the boost line (or the closing-soon warning).
class MineSideColumn extends StatelessWidget {
  const MineSideColumn({super.key, required this.view});

  final MineCycleView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.sideTop != null)
          Text(
            view.sideTop!,
            style: AppText.label(MinePalette.body, weight: AppText.semibold),
          ),
        if (view.sideBottom != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(view.sideBottom!, style: AppText.label(MinePalette.faint)),
        ],
      ],
    );
  }
}

/// The card's one primary action, 52 tall.
class MinePrimaryButton extends StatelessWidget {
  const MinePrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.amber = false,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool amber;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = amber ? MinePalette.onAmber : MinePalette.white;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: amber ? MinePalette.amber : MinePalette.fill,
        borderRadius: AppRadius.md,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: busy ? null : onPressed,
          child: SizedBox(
            height: 52,
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
                  style: AppText.subtitle(fg, weight: AppText.bold)
                      .copyWith(letterSpacing: -0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
