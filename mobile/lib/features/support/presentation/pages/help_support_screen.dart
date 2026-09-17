import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_list_row.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/support/data/getting_started_content.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SupportLinkLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key, this.launcher = _launchExternally});

  static const String supportEmail = 'support@blocnet.app';

  /// Opens mail and web links; tests replace it.
  final SupportLinkLauncher launcher;

  Future<void> _open(BuildContext context, Uri uri, String what) async {
    final opened = await launcher(uri);
    if (!opened && context.mounted) {
      AppSnackbar.showError(context, 'Could not open $what');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    ProfileListRow link(IconData icon, String title, String url) {
      return ProfileListRow(
        icon: icon,
        iconColor: AppColors.textMuted,
        title: title,
        trailingIcon: Icons.open_in_new_rounded,
        onTap: () => _open(context, Uri.parse(url), title),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Help & Support',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xxxl),
        children: [
          const SectionLabel('Quick help', icon: Icons.help_outline_rounded),
          AppSpace.gapSm,
          ProfileRowGroup(
            children: [
              ProfileListRow(
                icon: Icons.question_answer_outlined,
                title: 'FAQs',
                subtitle: 'Gems, Hunters, mining, BNP and BNT',
                onTap: () => navigator.pushNamed(AppRoutes.faq),
              ),
              ProfileListRow(
                icon: Icons.lightbulb_outline,
                title: 'Getting Started Guide',
                subtitle: '${gettingStartedSteps.length} steps',
                onTap: () => navigator.pushNamed(AppRoutes.gettingStarted),
              ),
              ProfileListRow(
                icon: Icons.menu_book_outlined,
                title: 'Glossary',
                subtitle: 'Gem, Hunter, Update, BNP, BNT',
                onTap: () => navigator.pushNamed(AppRoutes.glossary),
              ),
            ],
          ),
          AppSpace.gapXl,
          const SectionLabel('Contact', icon: Icons.mail_outline_rounded),
          AppSpace.gapSm,
          ProfileRowGroup(
            children: [
              ProfileListRow(
                icon: Icons.email_outlined,
                iconColor: AppColors.successColor,
                title: 'Email Support',
                subtitle: supportEmail,
                trailingIcon: Icons.open_in_new_rounded,
                onTap: () => _open(
                  context,
                  Uri.parse('mailto:$supportEmail'),
                  'your mail app',
                ),
              ),
            ],
          ),
          AppSpace.gapXl,
          const SectionLabel('Resources', icon: Icons.article_outlined),
          AppSpace.gapSm,
          ProfileRowGroup(
            children: [
              link(Icons.article_outlined, 'Documentation',
                  'https://docs.blocnet.app'),
              link(Icons.policy_outlined, 'Terms of Service',
                  'https://blocnet.app/terms'),
              link(Icons.privacy_tip_outlined, 'Privacy Policy',
                  'https://blocnet.app/privacy'),
            ],
          ),
        ],
      ),
    );
  }
}
