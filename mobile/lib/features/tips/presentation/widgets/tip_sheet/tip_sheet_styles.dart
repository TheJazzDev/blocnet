import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Text colour on the space accent: black on cyan, white on blue.
Color tipOnAccent() =>
    AppColors.primary500.computeLuminance() > 0.4 ? Colors.black : Colors.white;

/// 10px bold caps with 1.0 tracking, the app's card and section label.
TextStyle tipCaps(Color color) =>
    AppText.caption(color, weight: AppText.bold).copyWith(letterSpacing: 1.0);

/// Small section label above a card: `RECENT TIPS`.
class TipSectionLabel extends StatelessWidget {
  const TipSectionLabel(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIcon.xs, color: AppColors.textFaint),
            const SizedBox(width: AppSpace.xs),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tipCaps(AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined pill: faint tint, coloured hairline, coloured caps.
class TipPill extends StatelessWidget {
  const TipPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.hair,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label.toUpperCase(), maxLines: 1, style: tipCaps(color)),
    );
  }
}

/// Input style for the tip form: elevated ground, subtle edge, accent focus.
InputDecoration tipFieldDecoration(String hint) {
  OutlineInputBorder edge(Color color) => OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: color),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(AppColors.textFaint),
    filled: true,
    fillColor: AppColors.bgSurface,
    isDense: true,
    border: edge(AppColors.borderSubtle),
    enabledBorder: edge(AppColors.borderSubtle),
    focusedBorder: edge(AppColors.primary500),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpace.md,
      vertical: AppSpace.md,
    ),
  );
}
