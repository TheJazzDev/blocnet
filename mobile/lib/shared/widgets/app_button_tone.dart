import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Filled with the live space accent (or [AppButton.color]). One per
  /// screen.
  primary,

  /// Tinted accent on a bordered surface. The common secondary action.
  secondary,

  /// Text only. For tertiary actions and anything inside a dense row.
  ghost,

  /// Filled destructive. Reserve for actions that lose data or access.
  danger,

  /// Dark outlined: elevated ground, muted hairline, primary text.
  outline,

  /// Outlined in [AppButton.color]: a faint tint and a coloured hairline
  /// (Resolve, Uphold, Hand over).
  tinted,
}

enum AppButtonSize {
  /// 44px minimum.
  regular,

  /// 36px minimum.
  small,

  /// 40px, [AppRadius.md] corners, 12px bold label.
  compact,

  /// 34px version of [compact].
  compactSmall,
}

/// The colours one [AppButtonVariant] draws with.
class AppButtonTone {
  const AppButtonTone(this.background, this.foreground, [this.border]);

  final Color background;
  final Color foreground;
  final Color? border;

  static AppButtonTone of(AppButtonVariant variant, Color? color) {
    final accent = color ?? AppColors.primary500;
    return switch (variant) {
      AppButtonVariant.primary => AppButtonTone(accent, _on(accent)),
      AppButtonVariant.danger =>
        AppButtonTone(AppColors.error500, _on(AppColors.error500)),
      AppButtonVariant.secondary => AppButtonTone(
          accent.withValues(alpha: 0.12),
          accent,
          accent.withValues(alpha: 0.35),
        ),
      AppButtonVariant.ghost => AppButtonTone(Colors.transparent, accent),
      AppButtonVariant.outline => AppButtonTone(
          AppColors.bgElevated,
          AppColors.textPrimary,
          AppColors.borderMuted,
        ),
      AppButtonVariant.tinted => AppButtonTone(
          accent.withValues(alpha: 0.1),
          accent,
          accent.withValues(alpha: 0.45),
        ),
    };
  }

  /// Dark text on a light fill (the cyan accent), white on a dark one.
  static Color _on(Color fill) =>
      fill.computeLuminance() > 0.4 ? AppColors.bgBase : Colors.white;
}
