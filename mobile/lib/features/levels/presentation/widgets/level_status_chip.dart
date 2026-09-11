import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Small uppercase pill (`CURRENT`, `LOCKED`, `DONE`) tinted with a tier
/// colour. [filled] paints a solid background; otherwise a soft tint.
///
/// A thin wrapper over [AppPill] now. It stays because the levels screens read
/// better naming a level's status than describing a pill, and because it pins
/// the dense/uppercase choices that the level grid needs.
class LevelStatusChip extends StatelessWidget {
  const LevelStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.filled = true,
    this.icon,
  });

  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppPill(
      label: label,
      color: color,
      icon: icon,
      style: filled ? AppPillStyle.filled : AppPillStyle.tinted,
      dense: true,
      uppercase: true,
    );
  }
}
