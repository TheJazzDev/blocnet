import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:flutter/material.dart';

/// Scrim below the app bar plus the popover card under the `?` icon.
///
/// Lives in an [OverlayEntry], so opening it never changes the page layout.
class MineHelpOverlay extends StatelessWidget {
  const MineHelpOverlay({
    super.key,
    required this.anchor,
    required this.scrimTop,
    required this.onClose,
    this.cycleHours = 24,
    this.claimWindowHours = 48,
  });

  /// From the mining config; the design's 24 and 48 are defaults only.
  final int cycleHours;
  final int claimWindowHours;

  /// The `?` icon's rectangle in global coordinates.
  final Rect anchor;

  /// Where the scrim starts: the bottom of the app bar.
  final double scrimTop;
  final VoidCallback onClose;

  static const double width = 272;
  static const double _arrow = 12;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    const right = 10.0;
    final top = anchor.bottom + _arrow / 2 + AppSpace.xs;
    final left = (screen.width - right - width).clamp(0.0, screen.width);
    final arrowLeft = (anchor.center.dx - left - _arrow / 2)
        .clamp(AppSpace.md, width - AppSpace.md - _arrow);

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: scrimTop,
          bottom: 0,
          child: GestureDetector(
            key: const ValueKey('mine-help-scrim'),
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const ColoredBox(color: MinePalette.scrim),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -_arrow / 2,
                left: arrowLeft,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: _arrow,
                    height: _arrow,
                    decoration: BoxDecoration(
                      color: MinePalette.popover,
                      border: Border.all(color: MinePalette.popoverEdge),
                    ),
                  ),
                ),
              ),
              _PopoverCard(
                onClose: onClose,
                lines: [
                  (Icons.bolt_rounded, 'Mine BNP in $cycleHours-hour cycles.'),
                  (
                    Icons.check_circle_outline_rounded,
                    'Claim within $claimWindowHours hours, or the cycle '
                        'expires.',
                  ),
                  (Icons.swap_horiz_rounded, 'BNP converts to BNT at launch.'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PopoverCard extends StatelessWidget {
  const _PopoverCard({required this.onClose, required this.lines});

  final VoidCallback onClose;
  final List<(IconData, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('mine-help-popover'),
      color: MinePalette.popover,
      elevation: 12,
      shadowColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: MinePalette.popoverEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'How mining works',
                style: AppText.body(MinePalette.white, weight: AppText.bold),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.hair),
                    child: Icon(lines[i].$1,
                        size: AppIcon.sm, color: MinePalette.accent),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      lines[i].$2,
                      style:
                          AppText.label(MinePalette.soft).copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.sm),
            Semantics(
              button: true,
              child: InkWell(
                key: const ValueKey('mine-help-got-it'),
                onTap: onClose,
                borderRadius: AppRadius.sm,
                child: Padding(
                  // 44 px target around the design's 36 px button.
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: MinePalette.chip,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Text(
                      'Got it',
                      style: AppText.label(
                        MinePalette.white,
                        weight: AppText.semibold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
