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

  /// 20 — the default. Buttons, list rows, tab bars. Absorbs 18, 19, 21, 22.
  static const double md = 20;

  /// 24 — app bar, prominent actions. Absorbs 28.
  static const double lg = 24;

  /// 32 — feature tiles, section markers. Absorbs 36, 38, 40.
  static const double xl = 32;

  /// 48 — empty states and illustrations. Absorbs 64.
  static const double xxl = 48;
}
