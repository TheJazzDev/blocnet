import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/settings/presentation/utils/humanize_notification_type.dart';
import 'package:blocnet/features/settings/presentation/widgets/setting_switch_tile.dart';
import 'package:flutter/material.dart';

/// Notification category row. The subtitle shows the first linked event and
/// a tappable "+ N more" that expands to list every event type in the
/// category (from the preferences catalog).
class CategorySwitchTile extends StatefulWidget {
  const CategorySwitchTile({
    super.key,
    required this.icon,
    required this.category,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final IconData icon;
  final NotificationPreferenceCategoryCatalog category;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  State<CategorySwitchTile> createState() => _CategorySwitchTileState();
}

class _CategorySwitchTileState extends State<CategorySwitchTile> {
  bool _expanded = false;

  List<String> get _types => widget.category.types;

  String get _collapsedSubtitle {
    if (_types.isEmpty) return 'No linked events';
    return humanizeNotificationType(_types.first);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onChanged != null;
    final mutedColor = isEnabled
        ? AppColors.textMuted
        : AppColors.textMuted.withValues(alpha: 0.7);
    final extra = _types.length - 1;
    final canExpand = extra > 0;

    return SettingSwitchTile(
      icon: widget.icon,
      title: widget.category.label,
      subtitle: _collapsedSubtitle,
      value: widget.value,
      onChanged: widget.onChanged,
      showDivider: widget.showDivider,
      subtitleWidget: canExpand
          ? GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Text.rich(
                TextSpan(
                  text: '$_collapsedSubtitle ',
                  style: AppTypography.custom(
                    color: mutedColor,
                    size: AppText.labelSize,
                    weight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: _expanded ? 'show less' : '+ $extra more',
                      style: AppTypography.custom(
                        color: AppColors.teal400,
                        size: AppText.labelSize,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      footer: canExpand && _expanded
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpace.xxl, bottom: AppSpace.md),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _types
                    .map(
                      (type) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(AppRadius.smValue),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          humanizeNotificationType(type),
                          style: AppTypography.custom(
                            color: mutedColor,
                            size: AppText.captionSize,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            )
          : null,
    );
  }
}
