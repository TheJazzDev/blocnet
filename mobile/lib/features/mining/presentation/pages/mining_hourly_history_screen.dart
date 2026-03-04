import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_hourly_history_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Hourly History',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<MiningStore>(
        builder: (context, store, _) {
          final entries = store.snapshot?.hourlyHistory ?? const [];
          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => store.loadSnapshot(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Last 48 hourly checkpoints from your mining sessions.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                MiningHourlyHistoryCard(
                  entries: entries,
                  isLoading: store.isLoadingSnapshot,
                  maxEntries: 48,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
