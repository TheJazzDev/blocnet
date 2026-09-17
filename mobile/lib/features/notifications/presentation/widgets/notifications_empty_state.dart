import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/presentation/widgets/parts/notif_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Left-aligned empty card. [categoryLabel] names the filter when one is on.
class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key, this.categoryLabel});

  final String? categoryLabel;

  @override
  Widget build(BuildContext context) {
    final label = categoryLabel;
    final title = label == null
        ? 'No notifications yet'
        : 'No ${label.toLowerCase()} notifications';
    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: notifCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotifIconSquare(
            icon: Symbols.notifications_off,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  'Follow gems to get their updates here.',
                  style: AppText.label(AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
