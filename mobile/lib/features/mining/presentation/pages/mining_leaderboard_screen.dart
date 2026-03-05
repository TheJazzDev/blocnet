import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/presentation/widgets/mining_leaderboard_list.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MiningLeaderboardScreen extends StatefulWidget {
  const MiningLeaderboardScreen({super.key});

  @override
  State<MiningLeaderboardScreen> createState() =>
      _MiningLeaderboardScreenState();
}

class _MiningLeaderboardScreenState extends State<MiningLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().loadLeaderboard(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Mining Leaderboard',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<MiningStore>(
        builder: (context, store, _) {
          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => store.loadLeaderboard(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                MiningLeaderboardList(
                  items: store.leaderboard,
                  isLoading: store.isLoadingLeaderboard,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
