import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_feedback.dart';
import 'package:blocnet/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when the closed-alpha check turns an email away. Says what happened
/// and what to do next, instead of a one-line snackbar.
///
/// Reads the rejected email from the route arguments (`{'email': ...}`).
class ClosedAlphaScreen extends StatelessWidget {
  const ClosedAlphaScreen({super.key, this.email});

  static const String routeName = '/closed-alpha';
  static const String supportEmail = 'support@blocnet.app';

  /// Overrides the route argument (used by tests and direct pushes).
  final String? email;

  String _email(BuildContext context) {
    if (email != null) return email!.trim();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) return (args['email'] as String?)?.trim() ?? '';
    return '';
  }

  Future<void> _askForInvite(BuildContext context, String address) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeQuery({
        'subject': 'Blocnet invite request',
        'body': address.isEmpty
            ? 'Please add my email to the Blocnet test.'
            : 'Please add $address to the Blocnet test.',
      }),
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!context.mounted) return;
    showAuthMessage(
      context,
      'No mail app found. $supportEmail copied.',
      error: false,
    );
  }

  static String _encodeQuery(Map<String, String> params) => params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');

  void _useDifferentEmail(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.signIn, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final address = _email(context);
    return AuthScreenShell(
      heading: 'Not on the list yet',
      subtitle: 'Blocnet is in a closed test. Only invited emails can '
          'sign in for now.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Email',
            icon: Icons.alternate_email_rounded,
            padding: EdgeInsets.zero,
          ),
          AppSpace.gapSm,
          Row(
            children: [
              Expanded(
                child: Text(
                  address.isEmpty ? 'This email' : address,
                  key: const Key('closed-alpha-email'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.semibold,
                  ),
                ),
              ),
              AppSpace.wGapSm,
              AppPill(
                label: 'Not invited',
                color: AppColors.warning500,
                dense: true,
                uppercase: true,
              ),
            ],
          ),
          AppSpace.gapXl,
          const AppSectionHeader(
            title: 'What to do next',
            icon: Icons.flag_outlined,
            padding: EdgeInsets.zero,
          ),
          AppSpace.gapXs,
          _NextStepRow(
            icon: Icons.mail_outline_rounded,
            title: 'Ask for an invite',
            subtitle: 'Email $supportEmail',
            onTap: () => _askForInvite(context, address),
          ),
          Divider(height: 1, color: AppColors.borderSubtle),
          _NextStepRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Use a different email',
            subtitle: 'Back to sign in',
            onTap: () => _useDifferentEmail(context),
          ),
          AppSpace.gapMd,
          Text(
            'Once you are added, sign in with the same email.',
            style: AppText.label(AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
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
    return AppListRow(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.12),
          borderRadius: AppRadius.sm,
        ),
        child: Icon(icon, size: AppIcon.md, color: AppColors.primary400),
      ),
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: AppIcon.md,
        color: AppColors.textFaint,
      ),
      onTap: onTap,
    );
  }
}
