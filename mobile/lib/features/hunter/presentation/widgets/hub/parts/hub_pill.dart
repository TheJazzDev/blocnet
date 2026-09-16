import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A filled pill carrying an upper-case word: `HUNTER`, `RELIABLE`,
/// `INVITE`, `IN REVIEW`, a gem's state.
class HubPill extends StatelessWidget {
  const HubPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.tracking = 1.1,
  });

  final String label;
  final Color color;
  final Color background;
  final EdgeInsets padding;
  final double tracking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        style: HubType.caps(color, weight: FontWeight.w800, tracking: tracking),
      ),
    );
  }
}
