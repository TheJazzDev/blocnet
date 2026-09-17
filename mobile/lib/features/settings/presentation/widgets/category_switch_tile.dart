import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_pill.dart';
import 'package:blocnet/features/settings/presentation/utils/humanize_notification_type.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_style.dart';
import 'package:blocnet/features/settings/presentation/widgets/setting_switch_tile.dart';
import 'package:flutter/material.dart';

/// Notification category row. The subtitle shows the first linked event and
/// a tappable "+ N more" that expands to list every event type in the
/// category (from the preferences catalog).
class CategorySwitchTile extends StatefulWidget {
  const CategorySwitchTile({
    super.key,
    required this.category,
    required this.value,
    required this.onChanged,
  });

  final NotificationPreferenceCategoryCatalog category;
  final bool value;
  final ValueChanged<bool>? onChanged;

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
    final style = styleForNotificationCategory(widget.category.key);
    final extra = _types.length - 1;
    final canExpand = extra > 0;

    return SettingSwitchTile(
      icon: style.icon,
      iconColor: style.color,
      title: widget.category.label,
      subtitle: _collapsedSubtitle,
      value: widget.value,
      onChanged: widget.onChanged,
      subtitleWidget: canExpand
          ? GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Text.rich(
                TextSpan(
                  text: '$_collapsedSubtitle ',
                  style: AppText.label(AppColors.textMuted,
                      weight: AppText.regular),
                  children: [
                    TextSpan(
                      text: _expanded ? 'Show less' : '+ $extra more',
                      style: AppText.label(AppColors.primary400,
                          weight: AppText.bold),
                    ),
                  ],
                ),
              ),
            )
          : null,
      footer: canExpand && _expanded
          ? Padding(
              padding: const EdgeInsets.only(
                  left: 42, top: AppSpace.sm, right: AppSpace.sm),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final type in _types)
                    ProfilePill(
                      label: humanizeNotificationType(type),
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
