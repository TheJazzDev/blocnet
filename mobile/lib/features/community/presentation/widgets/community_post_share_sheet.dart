import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/widgets/app_sheet.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Share a community post: copy its link, send it to WhatsApp or Telegram, or
/// hand it to the system share sheet.
Future<void> showCommunityPostShareSheet(
  BuildContext context, {
  required String postId,
  required String content,
}) async {
  final text = content.trim();
  final link =
      'https://blocnet.app/open?path=${Uri.encodeComponent('/community/$postId')}';
  final shareText = text.isEmpty ? link : '$text\n$link';

  final choice = await AppSheet.show<_ShareChoice>(
    context: context,
    title: 'Share post',
    icon: Icons.share_outlined,
    builder: (sheetContext) {
      void pick(_ShareChoice choice) => Navigator.of(sheetContext).pop(choice);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShareRow(
            icon: Icons.link_rounded,
            label: 'Copy link',
            onTap: () => pick(_ShareChoice.copy),
          ),
          _ShareRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp',
            onTap: () => pick(_ShareChoice.whatsApp),
          ),
          _ShareRow(
            icon: Icons.send_outlined,
            label: 'Telegram',
            onTap: () => pick(_ShareChoice.telegram),
          ),
          _ShareRow(
            icon: Icons.ios_share_rounded,
            label: 'More',
            onTap: () => pick(_ShareChoice.system),
          ),
        ],
      );
    },
  );
  if (choice == null || !context.mounted) return;

  Future<void> copy(String message) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) AppSnackbar.showSuccess(context, message);
  }

  Future<void> open(Uri uri, String app) async {
    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) await copy('$app isn’t available. Link copied.');
  }

  switch (choice) {
    case _ShareChoice.copy:
      await copy('Link copied');
    case _ShareChoice.whatsApp:
      await open(
        Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}'),
        'WhatsApp',
      );
    case _ShareChoice.telegram:
      await open(
        Uri.parse(
          'https://t.me/share/url?url=${Uri.encodeComponent(link)}'
          '&text=${Uri.encodeComponent(text)}',
        ),
        'Telegram',
      );
    case _ShareChoice.system:
      try {
        await SharePlus.instance.share(ShareParams(text: shareText));
      } catch (_) {
        await copy('Sharing isn’t available. Link copied.');
      }
  }
}

enum _ShareChoice { copy, whatsApp, telegram, system }

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(icon, size: AppIcon.md, color: AppColors.primary400),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
