import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Follow / Following toggle on a public profile.
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
    final foreground = isFollowing ? AppColors.textPrimary : Colors.black;
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? AppColors.bgElevated : AppColors.primary500,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
          ),
        ),
        child: isSubmitting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: foreground,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: AppTypography.custom(
                  color: foreground,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
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
      height: 42,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500.withValues(alpha: 0.14),
          foregroundColor: AppColors.primary400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
            side: BorderSide(
              color: AppColors.primary500.withValues(alpha: 0.45),
            ),
          ),
        ),
        icon: Icon(
          Icons.volunteer_activism_rounded,
          color: AppColors.primary400,
          size: AppIcon.sm,
        ),
        label: Text(
          'Tip Hunter',
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: AppText.labelSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Block / unblock toggle on someone else's public profile.
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
    final color = isBlocked ? AppColors.primary400 : AppColors.error500;
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isBlocked
                ? AppColors.primary400.withValues(alpha: 0.5)
                : AppColors.error500.withValues(alpha: 0.45),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
          ),
          backgroundColor: isBlocked
              ? AppColors.primary500.withValues(alpha: 0.08)
              : AppColors.error500.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: isSubmitting
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                isBlocked ? Icons.check_circle_outline : Icons.block_outlined,
                size: AppIcon.sm,
                color: color,
              ),
        label: Text(
          isBlocked ? 'User blocked' : 'Block user',
          style: AppTypography.custom(
            color: color,
            size: AppText.labelSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Asks before blocking or unblocking. Resolves true only on confirm.
Future<bool> confirmPublicProfileBlock(
  BuildContext context, {
  required bool isBlocked,
}) async {
  final actionLabel = isBlocked ? 'Unblock' : 'Block';
  final description = isBlocked
      ? 'You will start seeing this user in your feeds again.'
      : 'You will stop seeing this user in your feeds and comments.';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      title: Text(
        '$actionLabel user?',
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.subtitleSize,
          weight: FontWeight.w700,
        ),
      ),
      content: Text(
        description,
        style: AppTypography.custom(
          color: AppColors.textSecondary,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            actionLabel,
            style: AppTypography.custom(
              color: isBlocked ? AppColors.primary400 : AppColors.error500,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
