import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The gem's chain as a small outlined tag (`CORE`, `SOLANA`, ...), like
/// the old feed's category pills.
class ChainChip extends StatelessWidget {
  const ChainChip({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final style = ChainStyle.forTag(tag);
    if (style.label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: style.chipBackground,
        borderRadius: AppRadius.full,
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Text(
        style.label,
        maxLines: 1,
        style: HubType.caps(style.color, weight: AppText.semibold, tracking: 0.5),
      ),
    );
  }
}
