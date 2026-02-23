import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/presentation/widgets/downline_list.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MiningDownlineScreen extends StatefulWidget {
  const MiningDownlineScreen({super.key});

  @override
  State<MiningDownlineScreen> createState() => _MiningDownlineScreenState();
}

class _MiningDownlineScreenState extends State<MiningDownlineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().loadDownline(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Referral Downline',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<MiningStore>(
        builder: (context, store, _) {
          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => store.loadDownline(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'People who joined using your referral code.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                DownlineList(
                  items: store.downline,
                  isLoading: store.isLoadingDownline,
                  maxItems: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
