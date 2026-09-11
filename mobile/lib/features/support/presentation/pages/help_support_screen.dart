import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(),
            const SizedBox(height: AppSpace.xl),
            _QuickHelpSection(),
            const SizedBox(height: AppSpace.xl),
            _ContactSection(),
            const SizedBox(height: AppSpace.xl),
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
            size: AppText.headlineSize,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Get assistance with your account, explore FAQs, or reach out to our support team.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
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
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        _HelpTile(
          icon: Icons.question_answer_outlined,
          title: 'FAQs',
          subtitle: 'Gems, Hunters, Updates, mining, BNP and BNT explained',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.faq),
        ),
        _HelpTile(
          icon: Icons.lightbulb_outline,
          title: 'Getting Started Guide',
          subtitle: 'Your first week on Blocnet, step by step',
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.gettingStarted),
        ),
        _HelpTile(
          icon: Icons.menu_book_outlined,
          title: 'Glossary',
          subtitle: 'Gem, Hunter, Update, Space, BNP, BNT and more',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.glossary),
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
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.md),
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
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.md),
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
      child: AppSurface(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
              ),
              child: Icon(
                icon,
                color: AppColors.primary400,
                size: AppIcon.lg,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.bodySize,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.bodySize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textFaint,
              size: AppIcon.md,
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
      child: AppSurface(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal500.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
              ),
              child: Icon(
                icon,
                color: AppColors.teal400,
                size: AppIcon.lg,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.bodySize,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpace.hair),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.bodySize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textFaint,
              size: AppIcon.md,
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
      child: AppSurface(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textMuted,
              size: AppIcon.md,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.bodySize,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textFaint,
              size: AppIcon.md,
            ),
          ],
        ),
      ),
    );
  }
}
