import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_icon_square.dart';
import 'package:flutter/material.dart';

/// The list row of the visual language: a leading icon (in a tinted square,
/// or bare in the accent), a bold title, a muted subtitle, an optional
/// trailing widget and a chevron when the row opens something.
///
/// Flutter's own `ListTile` is deliberately not used: it enforces Material
/// metrics and its own text theme, which fight the token scale.
///
/// ```dart
/// AppListRow(
///   icon: Icons.shield_outlined,
///   title: 'Privacy',
///   subtitle: 'Who can see your activity',
///   onTap: openPrivacy,
/// )
/// AppListRow(leading: AppAvatar(user: u), title: u.displayName)
/// ```
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.icon,
    this.iconColor,
    this.plainIcon = false,
    this.leading,
    this.trailing,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.showChevron,
    this.onTap,
    this.dense = false,
    this.padding,
    this.titleColor,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Replaces [subtitle] when the second line needs more than text.
  final Widget? subtitleWidget;

  /// Drawn in an [AppIconSquare] (or bare, when [plainIcon]). Ignored when
  /// [leading] is given.
  final IconData? icon;

  /// Defaults to the live space accent.
  final Color? iconColor;

  /// The bare accent icon of the Mine rows, instead of the square.
  final bool plainIcon;
  final Widget? leading;

  /// A value, a pill, a switch — anything before the chevron.
  final Widget? trailing;
  final IconData trailingIcon;

  /// Defaults to showing the chevron whenever the row is tappable.
  final bool? showChevron;
  final VoidCallback? onTap;

  /// Label-sized title. For rows inside a dense card.
  final bool dense;
  final EdgeInsetsGeometry? padding;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final lead = leading ?? _iconLead();
    final chevron = showChevron ?? onTap != null;
    final titleStyle = (dense ? AppText.label : AppText.body)(
      titleColor ?? AppColors.textPrimary,
      weight: AppText.bold,
    );

    final row = Padding(
      padding: padding ?? AppSpace.row,
      child: Row(
        children: [
          if (lead != null) ...[lead, AppSpace.wGapMd],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleWidget != null) ...[
                  AppSpace.gapHair,
                  subtitleWidget!,
                ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                  AppSpace.gapHair,
                  Text(
                    subtitle!,
                    style: AppText.label(AppColors.textMuted,
                        weight: AppText.regular),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpace.wGapSm, trailing!],
          if (chevron) ...[
            AppSpace.wGapXs,
            Icon(trailingIcon, size: AppIcon.md, color: AppColors.textFaint),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: row),
    );
  }

  Widget? _iconLead() {
    if (icon == null) return null;
    if (plainIcon) {
      return Icon(
        icon,
        size: AppIcon.md,
        color: iconColor ?? AppColors.primary400,
      );
    }
    return AppIconSquare(icon: icon, color: iconColor);
  }
}
