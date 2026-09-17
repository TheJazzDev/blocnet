import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

enum _BoardAction { notifications, unfollow }

/// A board row's overflow: notification settings and Unfollow.
class BoardRowMenu extends StatelessWidget {
  const BoardRowMenu({super.key, required this.gem, required this.actions});

  final GemListing gem;
  final GemActions actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_BoardAction>(
      key: ValueKey('board-menu-${gem.id}'),
      tooltip: 'More',
      color: AppColors.bgElevated,
      icon: Icon(
        Icons.more_vert_rounded,
        size: AppIcon.md,
        color: AppColors.textMuted,
      ),
      onSelected: (action) => switch (action) {
        _BoardAction.notifications => actions.onPreferences(gem),
        _BoardAction.unfollow => actions.onToggleFollow(gem),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _BoardAction.notifications,
          child: Text('Notifications',
              style: HubType.body(AppColors.textPrimary)),
        ),
        PopupMenuItem(
          value: _BoardAction.unfollow,
          child: Text('Unfollow', style: HubType.body(AppColors.textPrimary)),
        ),
      ],
    );
  }
}
