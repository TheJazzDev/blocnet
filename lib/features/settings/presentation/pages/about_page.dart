import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Image.asset(
              'assets/img/logo.png',
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppConfig.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version ${AppConfig.appVersion}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            AppConfig.appDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'BlocNet helps you stay updated with the latest developments in your favorite blockchain projects. Never miss important announcements, updates, or action items.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            '© 2025 BlocNet. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
