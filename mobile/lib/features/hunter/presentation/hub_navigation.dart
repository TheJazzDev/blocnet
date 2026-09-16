import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_gem_screen.dart';
import 'package:blocnet/features/projects/presentation/pages/create_update_args.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Where the Hub sends a hunter, and what it refreshes when they come back.
class HubNavigation {
  const HubNavigation._();

  /// Opens the composer — empty, with [projectId] pre-selected, or editing
  /// [updateId]. A publish or save refreshes the board (and that gem's page),
  /// which is what clears the wait on screen.
  static Future<void> openComposer(
    BuildContext context, {
    String? projectId,
    String? updateId,
  }) async {
    final store = context.read<HunterBoardStore>();
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.createUpdate,
      arguments: CreateUpdateArgs(projectId: projectId, updateId: updateId),
    );
    if (result != true) return;
    await Future.wait([
      store.loadBoard(),
      if (projectId != null) store.loadGem(projectId),
    ]);
  }

  /// Opens a gem's page.
  static Future<void> openGem(BuildContext context, HunterBoardGem gem) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HunterGemScreen(initialGem: gem),
      ),
    );
  }

  /// Submits a gem; the submission then shows as in review.
  static Future<void> openSubmit(BuildContext context) async {
    final store = context.read<HunterBoardStore>();
    await Navigator.of(context).pushNamed(AppRoutes.submitProject);
    await store.loadPendingProposals();
  }

  /// My updates.
  static Future<void> openHistory(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.manageUpdates);
  }
}
