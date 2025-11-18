import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../../data/models/settings_model.dart';
import '../../../../core/utils/helpers.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive all notifications'),
            value: settingsProvider.settings.notificationsEnabled,
            onChanged: (value) async {
              if (authProvider.currentUser == null) return;

              try {
                await settingsProvider.updateSettings(
                  authProvider.currentUser!.id,
                  settingsProvider.settings.copyWith(
                    notificationsEnabled: value,
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  Helpers.showError(context, 'Failed to update settings');
                }
              }
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: settingsProvider.settings.pushNotifications,
            onChanged: settingsProvider.settings.notificationsEnabled
                ? (value) async {
                    if (authProvider.currentUser == null) return;

                    try {
                      await settingsProvider.updateSettings(
                        authProvider.currentUser!.id,
                        settingsProvider.settings.copyWith(
                          pushNotifications: value,
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        Helpers.showError(context, 'Failed to update settings');
                      }
                    }
                  }
                : null,
            secondary: const Icon(Icons.mobile_friendly),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive email notifications'),
            value: settingsProvider.settings.emailNotifications,
            onChanged: settingsProvider.settings.notificationsEnabled
                ? (value) async {
                    if (authProvider.currentUser == null) return;

                    try {
                      await settingsProvider.updateSettings(
                        authProvider.currentUser!.id,
                        settingsProvider.settings.copyWith(
                          emailNotifications: value,
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        Helpers.showError(context, 'Failed to update settings');
                      }
                    }
                  }
                : null,
            secondary: const Icon(Icons.email),
          ),
        ],
      ),
    );
  }
}
