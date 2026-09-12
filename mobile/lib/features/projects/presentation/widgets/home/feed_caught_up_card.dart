import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// Shown when nothing a member follows needs them.
///
/// This is the product keeping its promise, and it used to look like a failure:
/// a grey panel with the words *"You are fully caught up"* set in the same
/// weight as any other label. Round six asks for it to feel earned, and to
/// carry the receipt — what was checked, across how many gems, and how recently
/// — because reassurance that shows its work is what lets someone stop
/// checking.
///
/// Every number here is one the app actually knows. There is deliberately no
/// "unread" count: nothing tracks per-update reads, so claiming one would be
/// inventing a figure to fill a slot.
class FeedCaughtUpCard extends StatelessWidget {
  const FeedCaughtUpCard({
    super.key,
    required this.accent,
    required this.gemsFollowed,
    required this.updatesTracked,
    required this.sweptAt,
  });

  final Color accent;

  /// How many gems the member follows. Zero is handled by the day-one feed
  /// instead, so this card is never shown for an empty board.
  final int gemsFollowed;

  /// Updates currently on the member's board across those gems.
  final int updatesTracked;

  /// When the radar last swept. Null when the summary has not arrived.
  final DateTime? sweptAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.xl,
        horizontal: AppSpace.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(AppColors.bgSurface, accent, 0.10)!,
            Color.lerp(AppColors.bgBase, accent, 0.04)!,
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          // A ring rather than a filled badge: the shape says "complete"
          // without shouting, and it is the one accent object on the card.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.28), width: 2),
            ),
            child: Icon(
              Icons.check_rounded,
              size: AppIcon.xl,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            "You're all caught up",
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.headlineSize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.only(top: AppSpace.lg),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.14)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(value: '$gemsFollowed', label: 'gems'),
                _Stat(value: '$updatesTracked', label: 'updates'),
                _Stat(
                  value: sweptAt == null ? '—' : getTimeStamp(sweptAt!),
                  label: 'last sweep',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final gems = gemsFollowed == 1 ? 'gem' : 'gems';
    return 'Nothing needs you across the $gemsFollowed $gems on your board. '
        'A hunter is keeping each one current.';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: AppSpace.hair),
        Text(
          label.toUpperCase(),
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: AppText.captionSize,
            weight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
