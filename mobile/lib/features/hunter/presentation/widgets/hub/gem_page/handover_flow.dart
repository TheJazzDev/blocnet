import 'package:blocnet/features/hunter/data/models/pending_handover_model.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_offer_sheet.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_pending_sheet.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/app_sheet.dart';
import 'package:blocnet/shared/widgets/username_suggest_field.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// What the gem page's warn button does: offer a handover, or — when one is
/// already pending — show it with a way to withdraw.
class HandoverFlow {
  const HandoverFlow._();

  static Future<void> open(
    BuildContext context, {
    required String projectId,
    required String gemName,
    required PendingHandover? pending,
    required DateTime now,
    ProfileSearch? search,
  }) {
    if (pending != null) {
      return _showPending(context, projectId, pending, now);
    }
    return _offer(context, projectId, gemName, search);
  }

  static Future<void> _offer(
    BuildContext context,
    String projectId,
    String gemName,
    ProfileSearch? search,
  ) async {
    final store = context.read<HunterBoardStore>();
    final toast = AppSnackbar.of(context);
    final username = await AppSheet.show<String>(
      context: context,
      showClose: false,
      builder: (_) => HandoverOfferSheet(
        projectId: projectId,
        gemName: gemName,
        search: search,
        ownUsername: store.board?.reliability.username,
      ),
    );
    if (username == null) return;
    toast.success(handoverOfferedMessage(username));
    await Future.wait([store.loadGem(projectId), store.loadBoard()]);
  }

  static Future<void> _showPending(
    BuildContext context,
    String projectId,
    PendingHandover pending,
    DateTime now,
  ) async {
    final store = context.read<HunterBoardStore>();
    final withdrawn = await AppSheet.show<bool>(
      context: context,
      showClose: false,
      builder: (_) => HandoverPendingSheet(
        projectId: projectId,
        pending: pending,
        now: now,
      ),
    );
    if (withdrawn == true) await store.loadGem(projectId);
  }
}
