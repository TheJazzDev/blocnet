import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/settings/presentation/widgets/settings_account_sections.dart';
import 'package:blocnet/features/settings/presentation/widgets/settings_notification_sections.dart';
import 'package:blocnet/features/settings/presentation/widgets/settings_retry_card.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      context
          .read<NotificationSettingsStore>()
          .fetchInitialOnce(userId: auth.userId);
    });
  }

  /// A failed save shows once as a toast. A failed load has its own card,
  /// so it is not repeated here.
  void _reportSaveError(NotificationSettingsStore store) {
    final error = store.lastError;
    if (error == null || error.isEmpty || !store.hasLoaded) return;
    if (error == _lastShownError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastShownError == error) return;
      _lastShownError = error;
      AppSnackbar.showError(context, 'Could not save that setting');
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationSettingsStore>();
    final prefs = store.preferences;
    final catalog = store.catalog;
    _reportSaveError(store);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Settings',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xxxl),
        children: [
          if (store.isLoading && !store.hasLoaded)
            const SkeletonList(items: 4, itemHeight: 56)
          else if (prefs == null || catalog == null)
            SettingsRetryCard(onRetry: store.refresh)
          else ...[
            SettingsNotificationsSection(store: store, prefs: prefs),
            AppSpace.gapXl,
            SettingsCategoriesSection(
              store: store,
              prefs: prefs,
              catalog: catalog,
            ),
          ],
          AppSpace.gapXl,
          const SettingsDisplaySection(),
          AppSpace.gapXl,
          const SettingsPrivacySection(),
        ],
      ),
    );
  }
}
