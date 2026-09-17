import 'package:blocnet/widgets/app_toast.dart';
import 'package:flutter/material.dart';

export 'app_toast.dart' show AppToast, AppToastKind;

/// The app's one toast.
///
/// It draws in the root overlay, so it shows above open bottom sheets and
/// dialogs — unlike `ScaffoldMessenger`, whose snack bars sit under them.
/// One toast shows at a time; a new one replaces the last.
///
/// ```dart
/// AppSnackbar.showSuccess(context, 'Saved');
/// AppSnackbar.showInfo(context, 'Report sent',
///     actionLabel: 'My reports', onAction: openReports);
///
/// // Across an async gap, or when the route pops first:
/// final toast = AppSnackbar.of(context);
/// await save();
/// toast.error('Could not save.');
/// ```
class AppSnackbar {
  const AppSnackbar._();

  static const Duration defaultDuration = Duration(seconds: 3);

  /// For money and address messages people may want to read twice.
  static const Duration longDuration = Duration(seconds: 6);

  static OverlayEntry? _active;

  /// The overlay [_active] sits in. When a test (or a hot restart) tears
  /// that overlay down, the entry is simply forgotten.
  static OverlayState? _activeOverlay;

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) =>
      of(context).success(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) =>
      of(context).error(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) =>
      of(context).info(
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  /// Captures the root overlay now, for a toast shown later.
  static AppToaster of(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return AppToaster._(
      Overlay.maybeOf(context, rootOverlay: true),
      (media?.padding.top ?? 0) + kToolbarHeight + 12,
    );
  }

  /// Removes the toast on screen, if any.
  static void dismiss() {
    final entry = _active;
    if (entry != null) _remove(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (!identical(_active, entry)) return;
    final overlay = _activeOverlay;
    _active = null;
    _activeOverlay = null;
    if (overlay == null || !overlay.mounted) return;
    entry.remove();
    entry.dispose();
  }
}

/// A toast target captured by [AppSnackbar.of].
class AppToaster {
  const AppToaster._(this._overlay, this._top);

  final OverlayState? _overlay;
  final double _top;

  void success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppSnackbar.defaultDuration,
  }) =>
      show(AppToastKind.success, message,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  void error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppSnackbar.defaultDuration,
  }) =>
      show(AppToastKind.error, message,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  void info(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppSnackbar.defaultDuration,
  }) =>
      show(AppToastKind.info, message,
          actionLabel: actionLabel, onAction: onAction, duration: duration);

  void show(
    AppToastKind kind,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppSnackbar.defaultDuration,
  }) {
    final overlay = _overlay;
    if (overlay == null || !overlay.mounted) return;
    AppSnackbar.dismiss();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: _top,
        left: 16,
        right: 16,
        child: AppToast(
          message: message,
          kind: kind,
          duration: duration,
          actionLabel: actionLabel,
          onAction: onAction,
          onDismiss: () => AppSnackbar._remove(entry),
        ),
      ),
    );
    AppSnackbar._active = entry;
    AppSnackbar._activeOverlay = overlay;
    overlay.insert(entry);
  }
}
