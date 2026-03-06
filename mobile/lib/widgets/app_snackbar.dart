import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AppSnackbar {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showError(BuildContext context, String message) {
    _show(
      context,
      _ToastSpec(
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
      _ToastSpec(
        message: message,
        icon: Icons.check_circle_outline_rounded,
        background: AppColors.bgSurface,
        border: AppColors.successColor,
        iconColor: AppColors.successColor,
      ),
    );
  }

  static void _show(BuildContext context, _ToastSpec spec) {
    _dismissActive();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    final media = MediaQuery.maybeOf(context);
    final topInset = (media?.padding.top ?? 0) + kToolbarHeight + 12;

    final entry = OverlayEntry(
      builder: (_) => _OverlayToast(
        topInset: topInset,
        spec: spec,
        onClose: _dismissActive,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(const Duration(seconds: 3), _dismissActive);
  }

  static void _dismissActive() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _activeEntry?.remove();
    _activeEntry = null;
  }
}

class _ToastSpec {
  const _ToastSpec({
    required this.message,
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
}

class _OverlayToast extends StatelessWidget {
  const _OverlayToast({
    required this.topInset,
    required this.spec,
    required this.onClose,
  });

  final double topInset;
  final _ToastSpec spec;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topInset,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: spec.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: spec.border),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(spec.icon, size: 18, color: spec.iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  spec.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
