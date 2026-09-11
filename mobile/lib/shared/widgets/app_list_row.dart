import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A leading / title+subtitle / trailing row.
///
/// This is the shape behind most of the app's lists: settings entries,
/// leaderboard rows, wallet assets, project rows, notification items. Each one
/// had its own copy, which is why the gap between the avatar and the title, and
/// the alignment of the trailing value, differ from screen to screen.
///
/// Flutter's own `ListTile` is deliberately not used: it enforces Material
/// metrics and its own text theme, which fight the token scale.
///
/// ```dart
/// AppListRow(
///   leading: AppAvatar(user: u),
///   title: u.displayName,
///   subtitle: '@${u.username}',
///   trailing: Text('4,210', style: AppText.label(AppColors.textPrimary)),
///   onTap: () => openProfile(u),
/// )
/// ```
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.padding,
    this.titleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// A value, a chip, or a chevron. Kept as a widget because the app's rows
  /// end in all three.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tighter vertical padding, label-sized title. For rows inside a card.
  final bool dense;
  final EdgeInsetsGeometry? padding;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: dense ? AppSpace.sm : AppSpace.md,
          ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: dense
                      ? AppText.label(
                          titleColor ?? AppColors.textPrimary,
                          weight: AppText.medium,
                        )
                      : AppText.body(
                          titleColor ?? AppColors.textPrimary,
                          weight: AppText.medium,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle!,
                    style: AppText.caption(AppColors.textFaint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
