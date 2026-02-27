import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Help & Support',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(),
            const SizedBox(height: 24),
            _QuickHelpSection(),
            const SizedBox(height: 24),
            _ContactSection(),
            const SizedBox(height: 24),
            _ResourcesSection(),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How can we help?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 22,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get assistance with your account, explore FAQs, or reach out to our support team.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _QuickHelpSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Help',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _HelpTile(
          icon: Icons.question_answer_outlined,
          title: 'FAQs',
          subtitle: 'Find answers to common questions',
          onTap: () {
            // TODO: Navigate to FAQ page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('FAQ page coming soon')),
            );
          },
        ),
        _HelpTile(
          icon: Icons.lightbulb_outline,
          title: 'Getting Started Guide',
          subtitle: 'Learn how to use Blocnet',
          onTap: () {
            // TODO: Navigate to guide
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Guide coming soon')),
            );
          },
        ),
        _HelpTile(
          icon: Icons.security_outlined,
          title: 'Account & Privacy',
          subtitle: 'Manage your security and data',
          onTap: () {
            // TODO: Navigate to privacy settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Us',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _ContactTile(
          icon: Icons.email_outlined,
          title: 'Email Support',
          subtitle: 'support@blocnet.app',
          onTap: () async {
            final uri = Uri.parse('mailto:support@blocnet.app');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
        _ContactTile(
          icon: Icons.chat_bubble_outline,
          title: 'Live Chat',
          subtitle: 'Chat with our support team',
          onTap: () {
            // TODO: Open live chat
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live chat coming soon')),
            );
          },
        ),
        _ContactTile(
          icon: Icons.bug_report_outlined,
          title: 'Report a Bug',
          subtitle: 'Help us improve Blocnet',
          onTap: () {
            // TODO: Open bug report form
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bug report form coming soon')),
            );
          },
        ),
      ],
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _ResourceTile(
          icon: Icons.article_outlined,
          title: 'Documentation',
          onTap: () async {
            final uri = Uri.parse('https://docs.blocnet.app');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _ResourceTile(
          icon: Icons.policy_outlined,
          title: 'Terms of Service',
          onTap: () async {
            final uri = Uri.parse('https://blocnet.app/terms');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        _ResourceTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () async {
            final uri = Uri.parse('https://blocnet.app/privacy');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary400,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 12,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.teal400,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 12,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textFaint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 14,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textFaint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
