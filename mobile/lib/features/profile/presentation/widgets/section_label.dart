import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The old app's small section header: an optional faint icon and a 10px
/// bold, letter-spaced upper-case label, with an optional trailing widget.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.icon, this.trailing});

  final String label;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIcon.sm, color: AppColors.textFaint),
          AppSpace.wGapSm,
        ],
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption(AppColors.textFaint, weight: AppText.bold)
                .copyWith(letterSpacing: 1.0),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
