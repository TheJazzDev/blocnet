import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The hunter's two most recent updates ("signals") with a View All link.
class HunterSignalsSection extends StatelessWidget {
  const HunterSignalsSection({super.key, required this.updates});

  /// Newest first.
  final List<Update> updates;

  @override
  Widget build(BuildContext context) {
    final visible = updates.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Row(
            children: [
              Text(
                'HUNTER SIGNALS',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.manageUpdates),
                child: Text(
                  'View All',
                  style: AppTypography.custom(
                    color: AppColors.primary400,
                    size: AppText.captionSize,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: visible.isEmpty
              ? const _EmptySignalsCard()
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      _SignalCard(update: visible[i]),
                      if (i != visible.length - 1)
                        const SizedBox(height: AppSpace.md),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.update});

  final Update update;

  @override
  Widget build(BuildContext context) {
    final gemName = update.project?.name.trim().isNotEmpty == true
        ? update.project!.name.trim()
        : 'Untitled Gem';
    final priority = update.priority.label.toLowerCase();
    final signalLabel = _signalLabel(priority);
    final signalColor = _signalColor(priority);

    return AppSurface(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  Icons.token_outlined,
                  size: AppIcon.md,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gemName,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.labelSize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${_deriveTicker(gemName)} · ${getTimeStamp(update.createdAt)}',
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: AppText.captionSize,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  border:
                      Border.all(color: signalColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  signalLabel.toUpperCase(),
                  style: AppTypography.custom(
                    color: signalColor,
                    size: AppText.captionSize,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            _signalBody(update),
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _SignalCount(
                icon: Icons.people_outline_rounded,
                count: update.project?.followersCount ?? 0,
              ),
              const SizedBox(width: AppSpace.lg),
              _SignalCount(
                icon: Icons.sell_outlined,
                count: update.secondaryTags.length,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySignalsCard extends StatelessWidget {
  const _EmptySignalsCard();

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Icon(Icons.post_add_outlined,
              size: AppIcon.lg, color: AppColors.textFaint),
          const SizedBox(height: AppSpace.sm),
          Text(
            'No signals posted yet',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Publish updates to start building your hunter track record.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCount extends StatelessWidget {
  const _SignalCount({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIcon.sm, color: AppColors.textFaint),
        const SizedBox(width: AppSpace.xs),
        Text(
          '$count',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: AppText.captionSize,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

String _signalLabel(String priority) {
  if (priority == 'high') return 'Bullish';
  if (priority == 'mid' || priority == 'medium') return 'Watch';
  return 'Info';
}

Color _signalColor(String priority) {
  if (priority == 'high') return const Color(0xFF4ADE80);
  if (priority == 'mid' || priority == 'medium') return const Color(0xFFFBBF24);
  return AppColors.primary400;
}

String _deriveTicker(String name) {
  final words = name
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList();
  if (words.isEmpty) return 'BNT';
  if (words.length > 1) {
    final ticker = words.map((word) => word[0]).join().toUpperCase();
    return ticker.length > 5 ? ticker.substring(0, 5) : ticker;
  }
  final normalized = words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (normalized.isEmpty) return 'BNT';
  final length = normalized.length > 5 ? 5 : normalized.length;
  return normalized.substring(0, length).toUpperCase();
}

String _signalBody(Update update) {
  final source = update.content.trim().isNotEmpty
      ? update.content
      : update.description.trim();
  final normalized = source.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) {
    return 'No additional details provided for this signal.';
  }
  if (normalized.length > 180) return '${normalized.substring(0, 180)}...';
  return normalized;
}
