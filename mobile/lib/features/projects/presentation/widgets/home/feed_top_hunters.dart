import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// One hunter in the day-one rail. [admin] is what the profile sheet opens.
typedef FeedHunter = ({String handle, String name, Admin admin});

/// The hunters worth following right now, shown on the day-one screen only.
///
/// It appears **only at zero follows**, because once a member has a board the
/// people they follow are the feed and a row of strangers above it is noise.
/// Drawn like the old Top Hunters rail: a small uppercase label, then ringed
/// avatars with the handle beneath.
class FeedTopHunters extends StatelessWidget {
  const FeedTopHunters({
    super.key,
    required this.hunters,
    required this.onOpen,
  });

  /// Handle and display name per hunter, already ranked and capped by the
  /// caller.
  final List<FeedHunter> hunters;
  final void Function(Admin admin) onOpen;

  @override
  Widget build(BuildContext context) {
    if (hunters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP HUNTERS THIS WEEK',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hunters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.lg),
              itemBuilder: (context, i) {
                final hunter = hunters[i];
                return _Hunter(
                  hunter: hunter,
                  onTap: () => onOpen(hunter.admin),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Hunter extends StatelessWidget {
  const _Hunter({required this.hunter, required this.onTap});

  final FeedHunter hunter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A solid accent ring around the photo, as the old rail had.
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(AppSpace.hair),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary400, width: 2),
              ),
              child: AppAvatar(
                radius: 20,
                imageUrl: hunter.admin.imageUrl,
                fallback: Text(
                  _initials(hunter.name, hunter.handle),
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs + 2),
            Text(
              hunter.handle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String handle) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    final source = words.isNotEmpty ? words.first : handle.replaceAll('@', '');
    if (source.isEmpty) return '?';
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }
}
