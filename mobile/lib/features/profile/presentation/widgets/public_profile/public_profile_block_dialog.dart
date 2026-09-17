import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Asks before blocking or unblocking. Resolves true only on confirm.
Future<bool> confirmPublicProfileBlock(
  BuildContext context, {
  required bool isBlocked,
}) async {
  final actionLabel = isBlocked ? 'Unblock' : 'Block';
  final description = isBlocked
      ? 'Their posts and comments show again.'
      : 'Their posts and comments are hidden from you.';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      title: Text(
        '$actionLabel user?',
        style: AppText.subtitle(AppColors.textPrimary, weight: AppText.bold),
      ),
      content: Text(
        description,
        style: AppText.body(AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppText.label(AppColors.textMuted, weight: AppText.semibold),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            actionLabel,
            style: AppText.label(
              isBlocked ? AppColors.primary400 : AppColors.error500,
              weight: AppText.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
