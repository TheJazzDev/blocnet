import 'package:blocnet/features/gems/domain/gem_keeper.dart';
import 'package:blocnet/features/gems/presentation/widgets/gem_actions.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/follow_preference_bottom_sheet.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/services/projects/projects_store.dart';
import 'package:flutter/material.dart';

/// The live [GemActions]: stores, sheets and the gem page.
GemActions liveGemActions(BuildContext context, ProjectsStore store) {
  return GemActions(
    isFollowed: store.isProjectFollowed,
    onOpen: (gem) => showGemDetailsDialog(context, gem.id),
    onToggleFollow: (gem) => store.toggleFollowProject(gem.id),
    onPreferences: (gem) => showFollowPreferenceBottomSheet(
      context,
      projectId: gem.id,
      projectName: gem.project.name,
    ),
    onOpenKeeper: (keeper) => openKeeperProfile(context, keeper),
    onAsk: (gem) => askForUpdate(context, store, gem.id, gem.project.name),
  );
}

/// The hunter's public profile sheet.
Future<void> openKeeperProfile(BuildContext context, GemKeeper keeper) {
  return PublicProfileScreen.showSheet(context, keeper.toAdmin());
}

/// Asks a gem's hunter for an update and says how many are waiting.
Future<void> askForUpdate(
  BuildContext context,
  ProjectsStore store,
  String projectId,
  String gemName,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final waiting = await store.requestUpdateOn(projectId);
  if (!context.mounted || messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        waiting == null
            ? 'Already asked this week.'
            : waiting == 1
                ? 'Asked. 1 member waiting on $gemName.'
                : 'Asked. $waiting members waiting on $gemName.',
      ),
    ),
  );
}
