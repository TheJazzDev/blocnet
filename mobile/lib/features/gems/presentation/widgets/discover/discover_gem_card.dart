import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/discover/keeper_line.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gem_activity_line.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gem_follow_button.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gem_tags.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:flutter/material.dart';

/// One gem on Discover: what it is, whether it is alive, and who keeps it
/// and how reliably.
class DiscoverGemCard extends StatelessWidget {
  const DiscoverGemCard({
    super.key,
    required this.gem,
    required this.actions,
    required this.now,
  });

  final GemListing gem;
  final GemActions actions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final project = gem.project;
    final followed = actions.isFollowed(project.id);
    final description = project.description.trim();
    final deadline = gem.nextDeadline?.deadlineAt;
    final keeper = gem.keeper;

    return Container(
      key: ValueKey('gem-card-${project.id}'),
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.md,
          onTap: () => actions.onOpen(gem),
          child: Padding(
            padding: AppSpace.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GemMonogram(
                        name: project.name, tag: project.primaryTag.name),
                    AppSpace.wGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HubType.rowTitle(AppColors.textPrimary),
                          ),
                          AppSpace.gapXs,
                          GemTags(project: project),
                        ],
                      ),
                    ),
                    AppSpace.wGapSm,
                    GemFollowButton(
                      isFollowed: followed,
                      onToggle: () => actions.onToggleFollow(gem),
                      onPreferences: () => actions.onPreferences(gem),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  AppSpace.gapSm,
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: HubType.body(AppColors.textMuted, height: 1.4),
                  ),
                ],
                AppSpace.gapMd,
                GemActivityLine(gem: gem, now: now),
                if (deadline != null)
                  FeedDeadlineLine(deadlineAt: deadline, now: now),
                AppSpace.gapXs,
                Text(
                  '${counted(gem.updatesCount, 'update')} · '
                  '${groupedCount(project.followersCount)} following',
                  style: HubType.meta(AppColors.textFaint),
                ),
                if (keeper != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Divider(height: 1, color: AppColors.borderSubtle),
                  ),
                  KeeperLine(
                    keeper: keeper,
                    onTap: () => actions.onOpenKeeper(keeper),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
