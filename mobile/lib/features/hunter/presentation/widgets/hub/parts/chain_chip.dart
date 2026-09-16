import 'package:blocnet/features/hunter/domain/chain_style.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The gem's chain as a small tinted chip (`CORE`, `SOLANA`, ...).
class ChainChip extends StatelessWidget {
  const ChainChip({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final style = ChainStyle.forTag(tag);
    if (style.label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: style.chipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(style.label, maxLines: 1, style: HubType.caps(style.color)),
    );
  }
}
