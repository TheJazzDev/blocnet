import 'package:flutter/material.dart';
import '../../../../core/routes/route_names.dart';

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Preferences'),
          _buildSettingsTile(
            context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Change app theme',
            onTap: () => Navigator.pushNamed(context, RouteNames.themeSettings),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () =>
                Navigator.pushNamed(context, RouteNames.notificationSettings),
          ),
          const Divider(),
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.account_circle,
            title: 'Account Settings',
            subtitle: 'Manage your account',
            onTap: () =>
                Navigator.pushNamed(context, RouteNames.accountSettings),
          ),
          const Divider(),
          _buildSectionHeader('Information'),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'About',
            subtitle: 'About BlocNet',
            onTap: () => Navigator.pushNamed(context, RouteNames.about),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and support',
            onTap: () => Navigator.pushNamed(context, RouteNames.help),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'View privacy policy',
            onTap: () => Navigator.pushNamed(context, RouteNames.privacy),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
