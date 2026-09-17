import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_history.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/history/mine_history_rows.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sub_header.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The last 48 hourly checkpoints, grouped by cycle.
class MiningHourlyHistoryScreen extends StatefulWidget {
  const MiningHourlyHistoryScreen({super.key});

  @override
  State<MiningHourlyHistoryScreen> createState() =>
      _MiningHourlyHistoryScreenState();
}

class _MiningHourlyHistoryScreenState extends State<MiningHourlyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().loadSnapshot(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MiningStore>();
    final snapshot = store.snapshot;
    final groups = MineHistory.group(
      snapshot?.hourlyHistory ?? const [],
      currentSessionId:
          snapshot?.session.isRunning == true ? snapshot?.session.id : null,
    );

    return Scaffold(
      backgroundColor: MinePalette.ground,
      appBar: const MineSubHeader(title: 'Hourly history'),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () => store.loadSnapshot(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpace.xxl),
          children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.xxl),
                child: Center(
                  child: store.isLoadingSnapshot
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(
                          'No hours mined yet.',
                          style: AppText.label(MinePalette.muted),
                        ),
                ),
              ),
            for (final group in groups) ...[
              MineHistoryHeader(group: group),
              for (final hour in group.hours) MineHistoryHourRow(hour: hour),
            ],
          ],
        ),
      ),
    );
  }
}
