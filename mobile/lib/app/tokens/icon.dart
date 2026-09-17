/// The Blocnet icon scale.
///
/// Replaces 21 ad-hoc icon sizes (10px–64px, 285 call sites). The app's own
/// centre of gravity was 18 (65), 16 (56) and 20 (39), so the scale is built
/// around 16/20 rather than Material's 24 default.
///
/// Icon size is not type size. They were both being written as `size:` and
/// that is exactly why the two drifted apart.
///
/// ```dart
/// Icon(Icons.bolt_rounded, size: AppIcon.sm, color: AppColors.tagInfo)
/// ```
class AppIcon {
  const AppIcon._();

  /// 12 — inline with caption text. Absorbs 10, 11, 13.
  static const double xs = 12;

  /// 16 — inline with body and label text, dense rows. Absorbs 14, 15, 17.
  static const double sm = 16;

  /// 18 — the default. Buttons, list rows, tab bars.
  static const double md = 18;

  /// 24 — app bar, prominent actions. Absorbs 28.
  static const double lg = 24;

  /// 28 — feature tiles, section markers.
  static const double xl = 28;

  /// 40 — empty states and illustrations.
  static const double xxl = 40;
}
