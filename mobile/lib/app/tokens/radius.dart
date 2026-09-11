import 'package:flutter/widgets.dart';

/// The Blocnet corner scale.
///
/// Replaces 10 ad-hoc radii across ~480 call sites. The spread was the single
/// clearest signal that corners were decided per screen: 12 (152), 14 (79),
/// 10 (57), 999 (52), 8 (45), 16 (31), 20 (19), 6 (15), 4 (7), 18 (5).
///
/// Five steps, each with a job. If a new surface does not obviously belong to
/// one of them, it probably belongs to an existing surface.
///
/// ```dart
/// Container(decoration: BoxDecoration(borderRadius: AppRadius.md))
/// ClipRRect(borderRadius: AppRadius.lg, child: ...)
/// ```
class AppRadius {
  const AppRadius._();

  /// 8 — inputs, chips, small buttons. Absorbs 4, 6.
  static const double smValue = 8;

  /// 12 — cards, tiles, list rows. The workhorse. Absorbs 10.
  static const double mdValue = 12;

  /// 16 — panels, bottom sheets, large cards. Absorbs 14, 18.
  static const double lgValue = 16;

  /// 20 — full-screen sheets and modals.
  static const double xlValue = 20;

  /// Pills: badges, avatars, filter chips.
  static const double fullValue = 999;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullValue));

  /// Bottom sheets: rounded top, square bottom.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xlValue),
  );
}
