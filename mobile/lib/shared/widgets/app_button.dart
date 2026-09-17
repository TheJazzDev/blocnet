import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_button_tone.dart';
import 'package:flutter/material.dart';

export 'app_button_tone.dart' show AppButtonVariant, AppButtonSize;

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
/// The compact sizes are the visual language's 40px (and 34px) button —
/// filled accent, dark outlined, or outlined in a status colour — used by the
/// Hunter Hub and the moderation space. A busy compact button shows only its
/// spinner, as those screens always did.
///
/// ```dart
/// AppButton(label: 'Start Mining', onPressed: start, fullWidth: true)
/// AppButton(label: 'Cancel', onPressed: pop, variant: AppButtonVariant.ghost)
/// AppButton(label: 'Suspend user', onPressed: suspend, variant: AppButtonVariant.danger)
/// AppButton(label: 'Dismiss', onPressed: dismiss,
///     variant: AppButtonVariant.outline, size: AppButtonSize.compact)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.color,
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

  /// Overrides the tone of a [AppButtonVariant.primary] or
  /// [AppButtonVariant.tinted] button (e.g. the moderation red).
  final Color? color;

  /// Shows a spinner and blocks presses. At regular and small sizes the label
  /// stays, so the button does not change width mid-action.
  final bool isLoading;
  final bool fullWidth;

  bool get _small => size == AppButtonSize.small;
  bool get _compact =>
      size == AppButtonSize.compact || size == AppButtonSize.compactSmall;

  @override
  Widget build(BuildContext context) {
    final tone = AppButtonTone.of(variant, color);
    // A compact button that is busy keeps full strength; it is working, not
    // disabled.
    final dimmed = _compact
        ? onPressed == null && !isLoading
        : onPressed == null || isLoading;
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: !dimmed,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Material(
          color: tone.background,
          borderRadius: _radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: _radius,
            child: Container(
              height: switch (size) {
                AppButtonSize.compact => 40,
                AppButtonSize.compactSmall => 34,
                _ => null,
              },
              alignment: _compact ? Alignment.center : null,
              // 44px tall at regular size: the accessibility minimum for a
              // touch target.
              constraints:
                  _compact ? null : BoxConstraints(minHeight: _small ? 36 : 44),
              padding: EdgeInsets.symmetric(
                horizontal: _compact || _small ? AppSpace.md : AppSpace.lg,
                vertical: _compact ? 0 : (_small ? AppSpace.sm : AppSpace.md),
              ),
              decoration: tone.border == null
                  ? null
                  : BoxDecoration(
                      borderRadius: _radius,
                      border: Border.all(color: tone.border!),
                    ),
              child: _compact && isLoading
                  ? _spinner(tone.foreground, AppIcon.sm)
                  : _content(tone.foreground),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius get _radius => _compact ? AppRadius.md : AppRadius.sm;

  Widget _spinner(Color color, double size) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );

  Widget _content(Color fg) {
    final iconSize = _compact || _small ? AppIcon.sm : AppIcon.md;
    final gap = _compact ? 6.0 : AppSpace.sm;
    final style = _compact
        ? AppText.label(fg, weight: AppText.bold)
        : _small
            ? AppText.label(fg, weight: AppText.semibold)
            : AppText.body(fg, weight: AppText.semibold);
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          _spinner(fg, _small ? AppIcon.xs : AppIcon.sm),
          SizedBox(width: gap),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          SizedBox(width: gap),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
