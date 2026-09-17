import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// "Moving across Blocnet": the gems with the most recent updates, each with
/// that update's title and time.
class MovingSection extends StatelessWidget {
  const MovingSection({
    super.key,
    required this.gems,
    required this.now,
    required this.onOpen,
  });

  final List<GemListing> gems;
  final DateTime now;
  final ValueChanged<GemListing> onOpen;

  @override
  Widget build(BuildContext context) {
    if (gems.isEmpty) return const SizedBox.shrink();
    return HomePanel(
      key: const ValueKey('moving-section'),
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomePanelHeader(
            icon: Icons.trending_up_rounded,
            label: 'MOVING ACROSS BLOCNET',
            iconColor: AppColors.primary500,
          ),
          AppSpace.gapXs,
          for (var i = 0; i < gems.length; i++)
            _Row(
              gem: gems[i],
              now: now,
              divider: i > 0,
              onTap: () => onOpen(gems[i]),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.gem,
    required this.now,
    required this.divider,
    required this.onTap,
  });

  final GemListing gem;
  final DateTime now;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final update = gem.newest!;
    return InkWell(
      key: ValueKey('moving-${gem.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          border: divider
              ? const Border(top: BorderSide(color: AppColors.borderSubtle))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gem.project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.rowTitle(AppColors.textPrimary),
                  ),
                  Text(
                    update.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.meta(AppColors.textMuted),
                  ),
                ],
              ),
            ),
            AppSpace.wGapSm,
            Text(
              shortAgo(update.createdAt, now),
              style: HubType.meta(AppColors.textFaint),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
