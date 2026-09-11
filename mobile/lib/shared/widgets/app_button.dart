import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Filled with the live space accent. One per screen.
  primary,

  /// Tinted accent on a bordered surface. The common secondary action.
  secondary,

  /// Text only. For tertiary actions and anything inside a dense row.
  ghost,

  /// Filled destructive. Reserve for actions that lose data or access.
  danger,
}

enum AppButtonSize { regular, small }

/// The button.
///
/// Supersedes `PrimaryButton` and `SecondaryButton`, which between them are
/// used 9 times and have two problems: `PrimaryButton` returns an [Expanded],
/// so it can only ever live inside a [Flex] and silently breaks anywhere else,
/// and both reach into `AuthStore` through a [Provider] purely to pick the
/// space accent. They do not need to: `applySpaceAccent` already rewrites
/// `AppColors.primary500` when the space changes, so reading the token is
/// enough and the widget stays independent of app state.
///
/// ```dart
/// AppButton(label: 'Start Mining', onPressed: start, fullWidth: true)
/// AppButton(label: 'Cancel', onPressed: pop, variant: AppButtonVariant.ghost)
/// AppButton(label: 'Suspend user', onPressed: suspend, variant: AppButtonVariant.danger)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    super.key,
  });

  final String label;

  /// Null disables the button. There is no separate `isEnabled`, because two
  /// sources of truth for one state is how buttons end up enabled-looking and
  /// unresponsive.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// Shows a spinner and blocks presses. The label stays, so the button does
  /// not change width mid-action.
  final bool isLoading;
  final bool fullWidth;

  bool get _enabled => onPressed != null && !isLoading;
  bool get _small => size == AppButtonSize.small;

  Color get _tone => switch (variant) {
        AppButtonVariant.danger => AppColors.error500,
        _ => AppColors.primary500,
      };

  Color get _background => switch (variant) {
        AppButtonVariant.primary => _tone,
        AppButtonVariant.danger => _tone,
        AppButtonVariant.secondary => _tone.withValues(alpha: 0.12),
        AppButtonVariant.ghost => Colors.transparent,
      };

  Color get _foreground => switch (variant) {
        AppButtonVariant.primary ||
        AppButtonVariant.danger =>
          _tone.computeLuminance() > 0.4 ? AppColors.bgBase : Colors.white,
        _ => _tone,
      };

  @override
  Widget build(BuildContext context) {
    final fg = _foreground;

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _small ? AppIcon.xs : AppIcon.sm,
            height: _small ? AppIcon.xs : AppIcon.sm,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: AppSpace.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: _small ? AppIcon.sm : AppIcon.md, color: fg),
          const SizedBox(width: AppSpace.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _small
                ? AppText.label(fg, weight: AppText.semibold)
                : AppText.body(fg, weight: AppText.semibold),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: Material(
        color: _background,
        borderRadius: AppRadius.sm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: AppRadius.sm,
          child: Container(
            // 44px tall at regular size: the accessibility minimum for a
            // touch target, which the hand-rolled buttons vary either side of.
            constraints: BoxConstraints(minHeight: _small ? 36 : 44),
            padding: EdgeInsets.symmetric(
              horizontal: _small ? AppSpace.md : AppSpace.lg,
              vertical: _small ? AppSpace.sm : AppSpace.md,
            ),
            decoration: variant == AppButtonVariant.secondary
                ? BoxDecoration(
                    borderRadius: AppRadius.sm,
                    border: Border.all(color: _tone.withValues(alpha: 0.35)),
                  )
                : null,
            child: content,
          ),
        ),
      ),
    );
  }
}
