import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

export 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_block_dialog.dart';

const double _buttonHeight = 40;

/// Follow / Following toggle on a public profile: filled accent to follow,
/// dark outlined once following.
class PublicProfileFollowButton extends StatelessWidget {
  const PublicProfileFollowButton({
    super.key,
    required this.isFollowing,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isFollowing;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final inHunterSpace = context.select<AuthStore?, bool>(
      (auth) => auth?.isInHunterSpace ?? false,
    );
    final foreground = isFollowing
        ? AppColors.textPrimary
        : AppColors.onAccentForSpace(inHunterSpace);
    final label = isSubmitting
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(color: foreground, strokeWidth: 2),
          )
        : Text(
            isFollowing ? 'Following' : 'Follow',
            style: AppText.label(foreground, weight: AppText.bold),
          );
    final shape = const RoundedRectangleBorder(borderRadius: AppRadius.md);

    return SizedBox(
      height: _buttonHeight,
      child: isFollowing
          ? OutlinedButton(
              onPressed: isSubmitting ? null : onPressed,
              style: OutlinedButton.styleFrom(
                shape: shape,
                side: const BorderSide(color: AppColors.borderMuted),
                backgroundColor: AppColors.bgSurface,
              ),
              child: label,
            )
          : FilledButton(
              onPressed: isSubmitting ? null : onPressed,
              style: FilledButton.styleFrom(
                shape: shape,
                backgroundColor: AppColors.primary500,
                foregroundColor: foreground,
              ),
              child: label,
            ),
    );
  }
}

/// Opens the tip sheet for a hunter's public profile.
class PublicProfileTipButton extends StatelessWidget {
  const PublicProfileTipButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
          side: const BorderSide(color: AppColors.borderMuted),
          backgroundColor: AppColors.bgSurface,
        ),
        icon: Icon(
          Icons.volunteer_activism_outlined,
          color: AppColors.primary400,
          size: AppIcon.sm,
        ),
        label: Text(
          'Tip',
          style: AppText.label(AppColors.textPrimary, weight: AppText.bold),
        ),
      ),
    );
  }
}

/// Block / unblock on someone else's public profile. A quiet text row, not
/// a second primary button.
class PublicProfileBlockButton extends StatelessWidget {
  const PublicProfileBlockButton({
    super.key,
    required this.isBlocked,
    required this.isSubmitting,
    required this.onPressed,
  });

  final bool isBlocked;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isBlocked ? AppColors.textMuted : AppColors.error500;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          foregroundColor: color,
        ),
        icon: isSubmitting
            ? SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                isBlocked ? Icons.lock_open_rounded : Icons.block_outlined,
                size: AppIcon.sm,
                color: color,
              ),
        label: Text(
          isBlocked ? 'Blocked · Unblock' : 'Block user',
          style: AppText.label(color, weight: AppText.semibold),
        ),
      ),
    );
  }
}
