import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_caps_pill.dart';
import 'package:flutter/material.dart';

/// How a pill carries its colour.
enum AppPillStyle {
  /// Tinted fill at 12% with a 35% border. The app's dominant pill.
  tinted,

  /// Solid fill, dark text. For the one pill on screen that must win.
  filled,

  /// Border and text only, no fill. For quiet metadata.
  outlined,
}

/// A status pill: level chips, priority flags, role tags, tier markers.
///
/// The app has ~50 of these and they were all slightly different, because the
/// colour changes per use (tier colour, priority colour, tag colour) and each
/// site reinvented the surrounding geometry to suit. [color] stays open for
/// that reason; everything else is fixed so they finally line up.
///
/// ```dart
/// AppPill(label: 'CURRENT', color: tierColor)
/// AppPill(label: 'HIGH', color: AppColors.tagWarning, style: AppPillStyle.outlined)
/// AppPill(label: 'Featured', icon: Icons.star_rounded, style: AppPillStyle.filled)
/// ```
class AppPill extends StatelessWidget {
  const AppPill({
    required this.label,
    this.color,
    this.style = AppPillStyle.tinted,
    this.icon,
    this.dense = false,
    this.uppercase = false,
    super.key,
  }) : caps = false;

  /// The caps status pill of the visual language (`HUNTER`, `HIGH`,
  /// `IN REVIEW`): 12% tint, 35% hairline, 10px bold caps.
  ///
  /// With no [color] it is the neutral grey pill for states that ask nothing
  /// (`CURRENT`, `NEW`). [uppercase] false keeps a phrase as written
  /// (`Quiet · 25% current`). [dense] is the tighter pill for inline rows.
  const AppPill.caps({
    required this.label,
    this.color,
    this.icon,
    this.dense = false,
    this.uppercase = true,
    super.key,
  })  : caps = true,
        style = AppPillStyle.tinted;

  final String label;

  /// Defaults to the live space accent, so a pill with no explicit colour
  /// re-skins with the rest of the app when the user switches space.
  final Color? color;
  final AppPillStyle style;
  final IconData? icon;

  /// Tighter padding and caption text. For pills inside grid tiles and rows,
  /// where the full size overflows.
  final bool dense;
  final bool uppercase;

  /// Built by [AppPill.caps]; drawn by [AppCapsPill].
  final bool caps;

  @override
  Widget build(BuildContext context) {
    if (caps) {
      return AppCapsPill(
        label: label,
        color: color,
        icon: icon,
        dense: dense,
        uppercase: uppercase,
      );
    }
    final tone = color ?? AppColors.primary500;
    final filled = style == AppPillStyle.filled;

    final background = switch (style) {
      AppPillStyle.tinted => tone.withValues(alpha: 0.12),
      AppPillStyle.filled => tone,
      AppPillStyle.outlined => Colors.transparent,
    };
    // A filled pill takes any colour the caller has — a tier colour, a
    // priority colour, a tag colour — so the label has to be chosen against
    // it rather than assumed dark. Gold needs black, violet needs white.
    final foreground = filled
        ? (tone.computeLuminance() > 0.4 ? AppColors.bgBase : Colors.white)
        : tone;
    final borderColor = filled ? tone : tone.withValues(alpha: 0.35);

    final text = uppercase ? label.toUpperCase() : label;
    final textStyle = dense
        ? AppText.caption(foreground, weight: AppText.semibold)
        : AppText.label(foreground, weight: AppText.semibold);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpace.xs : AppSpace.sm,
        vertical: dense ? AppSpace.hair : AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.full,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? AppIcon.xs : AppIcon.sm, color: foreground),
            SizedBox(width: dense ? AppSpace.hair : AppSpace.xs),
          ],
          Text(
            text,
            style: uppercase
                ? textStyle.copyWith(letterSpacing: 0.4)
                : textStyle,
          ),
        ],
      ),
    );
  }
}
