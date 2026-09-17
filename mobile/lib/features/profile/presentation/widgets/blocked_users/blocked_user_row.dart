import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/widgets/profile_avatar.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:flutter/material.dart';

/// One blocked account: avatar, name, handle and an Unblock button.
class BlockedUserRow extends StatelessWidget {
  const BlockedUserRow({
    super.key,
    required this.user,
    required this.isPending,
    required this.onUnblock,
  });

  final BlockedUser user;
  final bool isPending;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final displayName = user.blocked.displayName?.trim() ?? '';
    final username = user.blocked.username?.trim() ?? '';
    final name = displayName.isNotEmpty
        ? displayName
        : (username.isNotEmpty ? username : 'Member');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.md, AppSpace.md),
      child: Row(
        children: [
          ProfileAvatar(
            name: name,
            imageUrl: user.blocked.avatarUrl,
            size: 40,
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(AppColors.textPrimary,
                      weight: AppText.semibold),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textMuted,
                        weight: AppText.regular),
                  ),
              ],
            ),
          ),
          AppSpace.wGapSm,
          OutlinedButton(
            onPressed: isPending ? null : onUnblock,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              side: const BorderSide(color: AppColors.borderMuted),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
            ),
            child: isPending
                ? SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textMuted,
                    ),
                  )
                : Text(
                    'Unblock',
                    style: AppText.label(AppColors.textPrimary,
                        weight: AppText.semibold),
                  ),
          ),
        ],
      ),
    );
  }
}
