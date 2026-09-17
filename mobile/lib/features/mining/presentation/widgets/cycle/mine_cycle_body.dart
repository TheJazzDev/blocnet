import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_parts.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_semantics.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_notify_row.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_progress_ring.dart';
import 'package:flutter/material.dart';

/// The card's contents, top to bottom: status row, when line, ring and side
/// column, primary button, note, notify row.
class MineCycleBody extends StatelessWidget {
  const MineCycleBody({
    super.key,
    required this.view,
    required this.glow,
    required this.isBusy,
    required this.onStart,
    required this.onClaim,
  });

  final MineCycleView view;

  /// 0→1→0 breathing value for the running ring's halo.
  final Animation<double> glow;
  final bool isBusy;
  final VoidCallback onStart;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final button = view.buttonLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Read as one summary; the pieces would otherwise be spoken as
        // "MINING", "HOUR 9 OF 24", "49" ... (F-62).
        Semantics(
          container: true,
          label: mineCycleSemanticsLabel(view),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MineStatusRow(view: view),
                const SizedBox(height: AppSpace.lg),
                MineWhenLine(view: view),
                const SizedBox(height: AppSpace.sm),
                Center(child: _Ring(view: view, glow: glow)),
                const SizedBox(height: AppSpace.sm),
                MineSideColumn(view: view),
              ],
            ),
          ),
        ),
        if (button != null) ...[
          const SizedBox(height: AppSpace.lg),
          MinePrimaryButton(
            key: const ValueKey('mine-primary'),
            label: button,
            icon: view.canClaim ? Icons.savings_outlined : Icons.bolt_rounded,
            busy: isBusy,
            onPressed: view.canClaim ? onClaim : onStart,
          ),
        ],
        if (view.note != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            view.note!,
            textAlign: TextAlign.center,
            style: AppText.label(MinePalette.faint),
          ),
        ],
        if (view.showNotify) const MineNotifyRow(),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.view, required this.glow});

  final MineCycleView view;
  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    final style = MinePhaseStyle.of(view.phase);
    final running = view.phase == MineCyclePhase.running;
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        // Running breathes the head dot's halo and the core glow, as the
        // old hero's pulse did; the other states hold still.
        final t = running ? glow.value : 0.5;
        final lit = view.ringFraction > 0;
        return MineProgressRing(
          fraction: view.ringFraction,
          color: style.ringColor,
          glowColor: style.ringColor
              .withValues(alpha: running ? 0.35 + 0.35 * t : 0.5),
          glow: lit ? (running ? 3 + 5 * t : 5) : 0,
          halo: style.quiet ? 0.08 : (running ? 0.16 + 0.16 * t : 0.22),
          center: MineRingCenter(view: view),
        );
      },
    );
  }
}
