import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/pages/quest_detail_page.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_card.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_list_tab.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/quests_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadQuests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    final auth = context.read<AuthStore>();
    final store = context.read<QuestsStore>();
    store.ensureUserScope(auth.userId);
    store.clearError();
    await Future.wait([
      store.loadAllQuests(force: true),
      store.loadMyQuests(force: true),
    ]);
  }

  void _open(QuestModel quest, [UserQuestModel? userQuest]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestDetailPage(quest: quest, userQuest: userQuest),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Quests',
            backButton: true,
            showSearch: false,
            showFilter: false,
          ),
          Consumer<QuestsStore>(
            builder: (context, store, _) => TabBar(
              controller: _tabController,
              labelColor: AppColors.primary400,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle:
                  AppText.label(AppColors.primary400, weight: AppText.bold),
              unselectedLabelStyle: AppText.label(AppColors.textMuted),
              indicatorColor: AppColors.primary400,
              dividerColor: AppColors.borderSubtle,
              tabs: [
                _countTab('Open', store.notStartedCount),
                _countTab(
                  'Active',
                  store.inProgressCount + store.pendingVerificationCount,
                ),
                _countTab('Done', store.completedCount),
              ],
            ),
          ),
          Expanded(
            child: Consumer<QuestsStore>(
              builder: (context, store, _) {
                final nothingLoaded =
                    store.allQuests.isEmpty && store.myQuests.isEmpty;
                if (nothingLoaded &&
                    (store.isLoadingAll || store.isLoadingMy)) {
                  return const SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    child: SkeletonList(
                      items: 6,
                      itemHeight: 96,
                      padding: AppSpace.allLg,
                    ),
                  );
                }
                if (nothingLoaded && store.lastError != null) {
                  return Center(
                    child: AppEmptyState.error(
                      title: 'Could not load quests',
                      message: progressErrorText(
                        store.lastError,
                        fallback: 'Check your connection and try again.',
                      ),
                      onAction: _loadQuests,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: store.refresh,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _openTab(store),
                      _activeTab(store),
                      _doneTab(store),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _countTab(String label, int count) {
    return Tab(
      height: 40,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(count > 0 ? '$label · $count' : label),
      ),
    );
  }

  Widget _openTab(QuestsStore store) {
    return QuestListTab(
      emptyIcon: Icons.explore_off_outlined,
      emptyTitle: 'No open quests',
      emptyMessage: 'New quests show up here.',
      cards: [
        for (final quest in store.getAvailableQuests())
          QuestCard(
            quest: quest,
            status: QuestStatus.notStarted,
            onTap: () => _open(quest),
          ),
      ],
    );
  }

  Widget _activeTab(QuestsStore store) {
    final active = [
      ...store.getInProgressQuests(),
      ...store.getPendingQuests(),
    ];
    return QuestListTab(
      emptyIcon: Icons.pending_actions_outlined,
      emptyTitle: 'Nothing in progress',
      emptyMessage: 'Open a quest to start it.',
      cards: [
        for (final userQuest in active)
          QuestCard(
            quest: userQuest.quest,
            status: userQuest.status,
            onTap: () => _open(userQuest.quest, userQuest),
          ),
      ],
    );
  }

  Widget _doneTab(QuestsStore store) {
    return QuestListTab(
      emptyIcon: Icons.check_circle_outline_rounded,
      emptyTitle: 'No finished quests yet',
      cards: [
        for (final userQuest in store.getCompletedQuests())
          QuestCard(
            quest: userQuest.quest,
            status: userQuest.status,
            completedAt: userQuest.completedAt,
            onTap: () => _open(userQuest.quest, userQuest),
          ),
      ],
    );
  }
}
