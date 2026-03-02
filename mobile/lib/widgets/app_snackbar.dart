import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(
      context,
      _build(
        context: context,
        message: message,
        icon: Icons.error_outline_rounded,
        background: AppColors.error900,
        border: AppColors.error500,
        iconColor: AppColors.error500,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      _build(
        context: context,
        message: message,
        icon: Icons.check_circle_outline_rounded,
        background: AppColors.bgSurface,
        border: AppColors.successColor,
        iconColor: AppColors.successColor,
      ),
    );
  }

  static void _show(BuildContext context, SnackBar snackBar) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }

  static SnackBar _build({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color background,
    required Color border,
    required Color iconColor,
  }) {
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
    final bottomInset = MediaQuery.sizeOf(context).height - topInset - 72;
    return SnackBar(
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      closeIconColor: AppColors.textMuted,
      backgroundColor: background,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset.clamp(16, 1200).toDouble(),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 12,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
