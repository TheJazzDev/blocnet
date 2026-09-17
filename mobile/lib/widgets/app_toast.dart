import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// What a toast reports. Sets its icon and colour.
enum AppToastKind { success, error, info }

/// The toast card `AppSnackbar` pins under the app bar: elevated ground, a
/// hairline and an icon in the kind's colour, the message, an optional
/// action and a close button.
///
/// The card owns its dismiss timer, so the timer dies with the widget. A
/// test that ends while a toast is up therefore leaves no pending timer, and
/// `pumpAndSettle` never waits on it.
class AppToast extends StatefulWidget {
  const AppToast({
    super.key,
    required this.message,
    required this.kind,
    required this.duration,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppToastKind kind;
  final Duration duration;

  /// Called when the timer runs out, the close button is tapped, or the
  /// action has run.
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  static (Color, IconData) styleOf(AppToastKind kind) => switch (kind) {
        AppToastKind.success => (
            AppColors.successColor,
            Icons.check_circle_rounded,
          ),
        AppToastKind.error => (AppColors.tagWarning, Icons.error_rounded),
        AppToastKind.info => (AppColors.primary500, Icons.info_rounded),
      };

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _runAction() {
    widget.onAction?.call();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = AppToast.styleOf(widget.kind);
    final label = widget.actionLabel;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: AppColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: tone.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.md,
            AppSpace.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIcon.md, color: tone),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  widget.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(AppColors.textPrimary),
                ),
              ),
              if (label != null && widget.onAction != null)
                TextButton(
                  onPressed: _runAction,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 32),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    label,
                    style: AppText.label(
                      AppColors.primary400,
                      weight: AppText.bold,
                    ),
                  ),
                )
              else
                AppSpace.wGapSm,
              Semantics(
                button: true,
                label: 'Dismiss',
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.hair),
                    child: Icon(
                      Icons.close_rounded,
                      size: AppIcon.md,
                      color: AppColors.textMuted,
                    ),
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
