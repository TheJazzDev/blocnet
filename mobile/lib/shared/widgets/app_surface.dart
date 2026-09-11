import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Which background a surface sits on.
enum AppSurfaceTone {
  /// `bgSurface` — the default card. 116 of the app's hand-rolled cards.
  surface,

  /// `bgElevated` — a surface resting on another surface.
  elevated,

  /// `bgBase` — flush with the page, border only.
  base,
}

/// The card primitive.
///
/// 85 files were building this by hand, and they agreed more than they
/// disagreed: 196 used `color + border + borderRadius`, 99 of the 107 borders
/// were `borderSubtle` at width 1, and the radius was `md` or `lg` in 200 of
/// 319 cases. This is that consensus, with the variations kept as parameters
/// rather than as 85 copies.
///
/// [onTap] is built in on purpose. The app has 147 bare `InkWell` and
/// `GestureDetector` wrappers, most of them making a card tappable, and each
/// one is a chance to forget the ink splash or clip it to the wrong radius.
///
/// ```dart
/// AppSurface(
///   onTap: () => openProject(p),
///   child: Text(p.name, style: AppText.subtitle(AppColors.textPrimary)),
/// )
/// ```
class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    this.tone = AppSurfaceTone.surface,
    this.padding = AppSpace.card,
    this.radius = AppRadius.md,
    this.bordered = true,
    this.borderColor,
    this.borderWidth = 1,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.margin,
    super.key,
  });

  /// A surface with no padding — for content that manages its own insets,
  /// such as a list that needs its rows to reach the edges.
  const AppSurface.flush({
    required this.child,
    this.tone = AppSurfaceTone.surface,
    this.radius = AppRadius.md,
    this.bordered = true,
    this.borderColor,
    this.borderWidth = 1,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.margin,
    super.key,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final AppSurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final bool bordered;

  /// Defaults to `borderSubtle`. Pass a tinted accent to mark a surface as
  /// selected or active, which is what the 8 non-default borders all do.
  final Color? borderColor;
  final double borderWidth;

  /// Takes precedence over [tone]. 44 hand-rolled cards use one.
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  Color get _background => switch (tone) {
        AppSurfaceTone.surface => AppColors.bgSurface,
        AppSurfaceTone.elevated => AppColors.bgElevated,
        AppSurfaceTone.base => AppColors.bgBase,
      };

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? _background : null,
        gradient: gradient,
        borderRadius: radius,
        border: bordered
            ? Border.all(
                color: borderColor ?? AppColors.borderSubtle,
                width: borderWidth,
              )
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return decorated;

    // Material + InkWell rather than GestureDetector so the splash is clipped
    // to the same radius as the border. Getting that pairing wrong is the most
    // common flaw in the hand-rolled versions.
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: decorated,
      ),
    );
  }
}
