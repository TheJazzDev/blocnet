import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailDigest = true;
  bool _highUrgencyOnly = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StyledLabelLarge('Settings'),
          const SizedBox(height: 8),
          const StyledBodyText500('Control how you receive Blocnet updates.'),
          const SizedBox(height: 18),
          _SettingSwitchTile(
            title: 'Push notifications',
            subtitle: 'Get in-app and device alerts',
            value: _pushNotifications,
            onChanged: (value) => setState(() => _pushNotifications = value),
          ),
          _SettingSwitchTile(
            title: 'Email digest',
            subtitle: 'Receive daily summary email',
            value: _emailDigest,
            onChanged: (value) => setState(() => _emailDigest = value),
          ),
          _SettingSwitchTile(
            title: 'High urgency only',
            subtitle: 'Mute low and mid urgency alerts',
            value: _highUrgencyOnly,
            onChanged: (value) => setState(() => _highUrgencyOnly = value),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                await context.read<AuthStore>().signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.signIn,
                  (Route<dynamic> route) => false,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.darkGrey100,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.darkGrey300),
                ),
              ),
              child: Text(
                'Sign out',
                style: TextStyle(
                  color: AppColors.error500,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkGrey200),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        activeColor: AppColors.primary500,
        title: StyledBodyText700(title, size: 14),
        subtitle: StyledBodyText500(subtitle, size: 12),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
