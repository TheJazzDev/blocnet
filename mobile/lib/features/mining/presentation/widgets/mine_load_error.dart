import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_format.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_cycle_parts.dart';
import 'package:flutter/material.dart';

/// Couldn't load: no invented idle card, only what is known.
class MineLoadError extends StatelessWidget {
  const MineLoadError({
    super.key,
    required this.onRetry,
    this.lastBalance,
    this.isRetrying = false,
  });

  final VoidCallback onRetry;

  /// Cached on this device; hidden when unknown.
  final int? lastBalance;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final balance = lastBalance;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2F2F35), width: 2),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: AppIcon.lg,
              color: MinePalette.faint,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            "Can't reach Blocnet",
            textAlign: TextAlign.center,
            style: AppText.title(MinePalette.white),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Your cycle keeps running. Try again in a moment.',
            textAlign: TextAlign.center,
            style: AppText.body(MinePalette.muted),
          ),
          const SizedBox(height: AppSpace.lg),
          MinePrimaryButton(
            key: const ValueKey('mine-retry'),
            label: 'Retry',
            icon: Icons.refresh_rounded,
            busy: isRetrying,
            onPressed: onRetry,
          ),
          if (balance != null) ...[
            const SizedBox(height: AppSpace.lg),
            Text.rich(
              TextSpan(
                text: 'Last balance ',
                children: [
                  TextSpan(
                    text: '${MineFormat.points(balance)} BNP',
                    style: const TextStyle(
                      color: MinePalette.body,
                      fontWeight: AppText.semibold,
                    ),
                  ),
                ],
              ),
              style: AppText.label(MinePalette.faint),
            ),
          ],
        ],
      ),
    );
  }
}
