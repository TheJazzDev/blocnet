import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          _buildHelpSection(
            'Getting Started',
            [
              _buildHelpItem(
                'How to follow projects',
                'Tap the "Follow" button on any project to receive updates.',
              ),
              _buildHelpItem(
                'How to save posts',
                'Tap the bookmark icon on any post to save it for later.',
              ),
              _buildHelpItem(
                'How to manage notifications',
                'Go to Settings > Notifications to customize your preferences.',
              ),
            ],
          ),
          _buildHelpSection(
            'Account',
            [
              _buildHelpItem(
                'How to edit profile',
                'Go to Profile > Edit icon to update your name and bio.',
              ),
              _buildHelpItem(
                'How to sign out',
                'Go to Settings > Account Settings > Sign Out.',
              ),
            ],
          ),
          _buildHelpSection(
            'Contact',
            [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email Support'),
                subtitle: Text(AppConfig.supportEmail),
                onTap: () async {
                  final uri = Uri.parse('mailto:${AppConfig.supportEmail}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.web),
                title: const Text('Website'),
                subtitle: Text(AppConfig.websiteUrl),
                onTap: () async {
                  final uri = Uri.parse(AppConfig.websiteUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        ...items,
        const Divider(),
      ],
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
    );
  }
}
