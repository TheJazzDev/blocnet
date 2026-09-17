import 'package:blocnet/features/hunter/data/models/pending_handover_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_sheet_frame.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// *Handover pending* — who it was offered to, when, and a way to withdraw
/// it. Pops with `true` once the backend has withdrawn it.
class HandoverPendingSheet extends StatefulWidget {
  const HandoverPendingSheet({
    super.key,
    required this.projectId,
    required this.pending,
    required this.now,
  });

  final String projectId;
  final PendingHandover pending;
  final DateTime now;

  /// `Waiting for @maya to answer · offered 3 days ago`.
  static String waitingLine(PendingHandover pending, DateTime now) =>
      'Waiting for @${pending.hunter.username} to answer · offered '
      '${daysAgoSince(pending.createdAt, now)}';

  @override
  State<HandoverPendingSheet> createState() => _HandoverPendingSheetState();
}

class _HandoverPendingSheetState extends State<HandoverPendingSheet> {
  bool _sent = false;

  Future<void> _withdraw(HunterBoardStore store) async {
    setState(() => _sent = true);
    final done = await store.cancelHandover(widget.projectId);
    if (!mounted || !done) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterBoardStore>();
    final error = _sent ? store.handoverErrorFor(widget.projectId) : null;

    return HandoverSheetFrame(
      key: const ValueKey('handover-pending-sheet'),
      title: 'Handover pending',
      body: HandoverPendingSheet.waitingLine(widget.pending, widget.now),
      children: [
        if (error != null) ...[
          HandoverSheetError(message: error),
          const SizedBox(height: 12),
        ],
        AppButton(
          key: const ValueKey('handover-withdraw'),
          label: 'Withdraw handover',
          variant: AppButtonVariant.tinted,
          isLoading: store.isHandoverBusy(widget.projectId),
          onPressed: () => _withdraw(store),
          color: HubTone.quiet,
          size: AppButtonSize.compact,
        ),
      ],
    );
  }
}
