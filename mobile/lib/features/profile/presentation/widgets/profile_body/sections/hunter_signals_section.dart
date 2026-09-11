import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'HUNTER SIGNALS',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
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
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: visible.isEmpty
              ? const _EmptySignalsCard()
              : Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      _SignalCard(update: visible[i]),
                      if (i != visible.length - 1) const SizedBox(height: 10),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(
                  Icons.token_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gemName,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '\$${_deriveTicker(gemName)} · ${getTimeStamp(update.createdAt)}',
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: signalColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  signalLabel.toUpperCase(),
                  style: AppTypography.custom(
                    color: signalColor,
                    size: 9,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _signalBody(update),
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _SignalCount(
                icon: Icons.people_outline_rounded,
                count: update.project?.followersCount ?? 0,
              ),
              const SizedBox(width: 16),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add_outlined, size: 22, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No signals posted yet',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Publish updates to start building your hunter track record.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 11,
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
        Icon(icon, size: 16, color: AppColors.textFaint),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
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
