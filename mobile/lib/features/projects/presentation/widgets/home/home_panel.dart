import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// The flat panel Home draws its non-post blocks on: surface colour, a 1px
/// subtle border, left-aligned content. This is the app's original card.
class HomePanel extends StatelessWidget {
  const HomePanel({
    super.key,
    required this.child,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

/// A panel's header: a small icon and a small uppercase, tracked label, with
/// an optional trailing widget pushed to the right.
class HomePanelHeader extends StatelessWidget {
  const HomePanelHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIcon.sm, color: iconColor),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.sm),
          trailing!,
        ],
      ],
    );
  }
}
