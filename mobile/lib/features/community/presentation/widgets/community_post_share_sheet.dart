import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showCommunityPostShareSheet(
  BuildContext context, {
  required String postId,
  required String content,
}) async {
  final trimmedContent = content.trim();
  final deepPath = '/community/$postId';
  final webLink = 'https://blocnet.app/open?path=${Uri.encodeComponent(deepPath)}';
  final deepLink = 'io.blocnet.app://community/$postId';
  final shareText = '$trimmedContent\n$webLink';

  Future<void> copyLink() async {
    await Clipboard.setData(ClipboardData(text: webLink));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    AppSnackbar.showSuccess(context, 'Post link copied');
  }

  Future<void> openExternal(Uri uri, String platformName) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (!launched) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!context.mounted) return;
      AppSnackbar.showError(
        context,
        'Could not open $platformName. Link copied instead.',
      );
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share post',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trimmedContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _ShareOptionTile(
                icon: Icons.copy_all_rounded,
                title: 'Copy link',
                subtitle: webLink,
                onTap: copyLink,
              ),
              _ShareOptionTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Share to WhatsApp',
                subtitle: 'Open WhatsApp with post link',
                onTap: () => openExternal(
                  Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                  ),
                  'WhatsApp',
                ),
              ),
              _ShareOptionTile(
                icon: Icons.send_outlined,
                title: 'Share to Telegram',
                subtitle: 'Open Telegram with post link',
                onTap: () => openExternal(
                  Uri.parse(
                    'https://t.me/share/url?url=${Uri.encodeComponent(webLink)}&text=${Uri.encodeComponent(trimmedContent)}',
                  ),
                  'Telegram',
                ),
              ),
              _ShareOptionTile(
                icon: Icons.link_rounded,
                title: 'Copy deep link',
                subtitle: deepLink,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: deepLink));
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  AppSnackbar.showSuccess(context, 'Deep link copied');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
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
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
      title: Text(
        title,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 13,
          weight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: 11,
          weight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
