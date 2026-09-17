import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gem_tags.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_button.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// The gem itself: name, tags, what it is, the numbers, and Follow.
class GemSummaryCard extends StatelessWidget {
  const GemSummaryCard({
    super.key,
    required this.gem,
    required this.isFollowed,
    required this.now,
    required this.onToggleFollow,
    required this.onPreferences,
  });

  final GemListing gem;
  final bool isFollowed;
  final DateTime now;
  final VoidCallback onToggleFollow;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    final project = gem.project;
    final last = gem.lastUpdateAt;
    final meta = [
      '${groupedCount(project.followersCount)} following',
      counted(gem.updatesCount, 'update'),
      last == null ? 'No updates yet' : 'Last update ${shortAgo(last, now)}',
    ].join(' · ');

    return HomePanel(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GemMonogram(
                name: project.name,
                tag: project.primaryTag.name,
                size: GemMonogramSize.large,
              ),
              AppSpace.wGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(AppColors.textPrimary),
                    ),
                    AppSpace.gapXs,
                    GemTags(project: project, maxSecondary: 3),
                  ],
                ),
              ),
            ],
          ),
          if (project.description.trim().isNotEmpty) ...[
            AppSpace.gapMd,
            Text(
              project.description.trim(),
              style: HubType.body(AppColors.textSecondary),
            ),
          ],
          AppSpace.gapMd,
          Text(
            'Listed ${dayMonth(project.createdAt)} · $meta',
            style: HubType.meta(AppColors.textFaint),
          ),
          AppSpace.gapLg,
          _FollowRow(
            isFollowed: isFollowed,
            onToggle: onToggleFollow,
            onPreferences: onPreferences,
          ),
        ],
      ),
    );
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({
    required this.isFollowed,
    required this.onToggle,
    required this.onPreferences,
  });

  final bool isFollowed;
  final VoidCallback onToggle;
  final VoidCallback onPreferences;

  @override
  Widget build(BuildContext context) {
    if (!isFollowed) {
      return GemsButton(
        key: const ValueKey('gem-page-follow'),
        label: 'Follow',
        icon: Icons.add_rounded,
        expand: true,
        onTap: onToggle,
      );
    }
    return Row(
      children: [
        Expanded(
          child: GemsButton(
            key: const ValueKey('gem-page-follow'),
            label: 'Following',
            icon: Icons.check_rounded,
            filled: false,
            expand: true,
            onTap: onToggle,
          ),
        ),
        AppSpace.wGapSm,
        GemsButton(
          key: const ValueKey('gem-page-prefs'),
          label: 'Alerts',
          icon: Icons.notifications_none_rounded,
          filled: false,
          onTap: onPreferences,
        ),
      ],
    );
  }
}
