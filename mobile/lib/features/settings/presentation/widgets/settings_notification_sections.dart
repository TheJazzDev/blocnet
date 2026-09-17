import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/settings/presentation/widgets/category_switch_tile.dart';
import 'package:blocnet/features/settings/presentation/widgets/setting_switch_tile.dart';
import 'package:blocnet/features/settings/presentation/widgets/settings_choice_row.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Push, email digest and digest cadence.
class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.store,
    required this.prefs,
  });

  final NotificationSettingsStore store;
  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final saving = store.isSaving;
    final digestTime = TimeOfDay(
      hour: prefs.digestHourLocal,
      minute: prefs.digestMinuteLocal,
    ).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Notifications',
            icon: Icons.notifications_none_rounded),
        AppSpace.gapSm,
        AppRowGroup(
          children: [
            SettingSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              subtitle: prefs.masterEnabled ? 'On' : 'Off',
              value: prefs.masterEnabled,
              onChanged: saving ? null : store.setMasterEnabled,
            ),
            SettingSwitchTile(
              icon: Icons.mail_outline,
              title: 'Email digest',
              subtitle: prefs.digestCadence == 'weekly'
                  ? 'Weekly at $digestTime'
                  : 'Daily at $digestTime',
              value: prefs.digestEmailEnabled,
              onChanged: saving ? null : store.setDigestEmailEnabled,
            ),
            SettingsChoiceRow<String>(
              icon: Icons.schedule_outlined,
              title: 'Digest',
              options: const {'daily': 'Daily', 'weekly': 'Weekly'},
              selected: prefs.digestCadence == 'weekly' ? 'weekly' : 'daily',
              onChanged: saving || !prefs.digestEmailEnabled
                  ? null
                  : store.setDigestCadence,
            ),
          ],
        ),
      ],
    );
  }
}

/// One switch per notification category from the catalog.
class SettingsCategoriesSection extends StatelessWidget {
  const SettingsCategoriesSection({
    super.key,
    required this.store,
    required this.prefs,
    required this.catalog,
  });

  final NotificationSettingsStore store;
  final NotificationPreferences prefs;
  final NotificationPreferencesCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final categories = catalog.categories;
    if (categories.isEmpty) return const SizedBox.shrink();
    final locked = store.isSaving || !prefs.masterEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          'Categories',
          icon: Icons.tune_rounded,
          trailing: prefs.masterEnabled
              ? null
              : Text(
                  'PUSH OFF',
                  style:
                      AppText.caption(AppColors.textFaint, weight: AppText.bold)
                          .copyWith(letterSpacing: 1.0),
                ),
        ),
        AppSpace.gapSm,
        AppRowGroup(
          children: [
            for (final category in categories)
              CategorySwitchTile(
                key: ValueKey('category-${category.key}'),
                category: category,
                value: prefs.isCategoryEnabled(category.key),
                onChanged: locked
                    ? null
                    : (value) => store.setCategoryEnabled(category.key, value),
              ),
          ],
        ),
      ],
    );
  }
}
