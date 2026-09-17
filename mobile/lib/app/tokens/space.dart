import 'package:flutter/widgets.dart';

/// The Blocnet spacing scale — a 4pt grid with one 2pt hairline step.
///
/// Replaces 16 ad-hoc gap values across ~1,700 call sites (1,060 `SizedBox`
/// spacers plus `EdgeInsets`). The three biggest buckets were 8 (240),
/// 12 (179) and 10 (153). The steps keep the app's pre-2026-09-11 density;
/// a roomier grid was tried and read as too loose on a phone (F-67).
///
/// ```dart
/// const SizedBox(height: AppSpace.md)
/// Padding(padding: AppSpace.allLg, child: ...)
/// Column(children: [...]) // separated by AppSpace.gapSm
/// ```
class AppSpace {
  const AppSpace._();

  /// 2 — hairline separation. Absorbs 1, 3.
  static const double hair = 2;

  /// 4 — icon-to-label, inside a chip. Absorbs 5.
  static const double xs = 4;

  /// 8 — the default small gap. Absorbs 6, 9.
  static const double sm = 8;

  /// 10 — between related rows.
  static const double md = 10;

  /// 14 — card padding, between cards.
  static const double lg = 14;

  /// 20 — between sections.
  static const double xl = 20;

  /// 28 — around a screen's major blocks.
  static const double xxl = 28;

  /// 40 — empty-state breathing room.
  static const double xxxl = 40;

  // ── Ready-made insets ────────────────────────────────────────────────────
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// Standard screen gutter.
  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  /// Standard card interior.
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Standard list row.
  static const EdgeInsets row =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // ── Ready-made gaps ──────────────────────────────────────────────────────
  static const SizedBox gapHair = SizedBox(height: hair);
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);

  static const SizedBox wGapXs = SizedBox(width: xs);
  static const SizedBox wGapSm = SizedBox(width: sm);
  static const SizedBox wGapMd = SizedBox(width: md);
  static const SizedBox wGapLg = SizedBox(width: lg);
}
