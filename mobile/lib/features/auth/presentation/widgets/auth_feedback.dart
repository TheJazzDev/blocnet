import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Turns an auth failure into something a person can read. The store passes
/// some errors through as `error.toString()` (`Exception: ...`,
/// `SocketException ...`, stack-ish noise); those become [fallback].
String authErrorText(String? raw, String fallback) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return fallback;
  final lower = text.toLowerCase();
  const noise = [
    'exception',
    'error:',
    'errno',
    'socket',
    'handshake',
    'instance of',
    'null check',
    'type \'',
  ];
  if (noise.any(lower.contains) || text.length > 160) return fallback;
  return text;
}

/// A floating snackbar in the app's surface colours. [error] adds the red
/// icon; otherwise a green tick.
void showAuthMessage(
  BuildContext context,
  String message, {
  bool error = true,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: AppColors.borderMuted),
        ),
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: AppIcon.sm,
              color: error ? AppColors.error500 : AppColors.successColor,
            ),
            AppSpace.wGapSm,
            Expanded(
              child: Text(
                message,
                style: AppText.label(AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
}

/// A one-line tinted note: an icon and a sentence, left-aligned
/// (reset link sent, new code sent, config missing).
class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    required this.color,
    this.icon = Icons.info_outline_rounded,
  });

  AuthNotice.success({super.key, required this.message})
      : color = AppColors.successColor,
        icon = Icons.check_circle_outline_rounded;

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpace.allMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIcon.sm, color: color),
          AppSpace.wGapSm,
          Expanded(child: Text(message, style: AppText.label(color))),
        ],
      ),
    );
  }
}

/// "Question? Action" on one left-aligned line, the action in the accent.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppText.label(AppColors.textMuted)),
        AuthTextLink(label: action, onTap: onTap),
      ],
    );
  }
}

/// A text link in the accent with a 44px-tall tap target.
class AuthTextLink extends StatelessWidget {
  const AuthTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: AppText.label(
                onTap == null ? AppColors.textFaint : AppColors.primary400,
                weight: AppText.semibold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
