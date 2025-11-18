import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Information We Collect',
            'We collect information that you provide directly to us, including your email address, display name, and profile information.',
          ),
          _buildSection(
            'How We Use Your Information',
            'We use the information we collect to provide, maintain, and improve our services, send you notifications about projects you follow, and communicate with you.',
          ),
          _buildSection(
            'Data Security',
            'We use industry-standard security measures to protect your personal information from unauthorized access, disclosure, alteration, and destruction.',
          ),
          _buildSection(
            'Your Rights',
            'You have the right to access, update, or delete your personal information at any time through your account settings.',
          ),
          _buildSection(
            'Contact Us',
            'If you have any questions about this Privacy Policy, please contact us at support@blocnet.com.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
