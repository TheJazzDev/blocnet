import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/pages/quest_detail_page.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/engagement/quests_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BadgeCategory? _selectedCategory;
  QuestType? _selectedType;

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

  @override
  Widget build(BuildContext context) {
    final viewMode = context.watch<FeedViewModeStore>().mode;
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
          Container(
            color: AppColors.bgBase,
            child: Consumer<QuestsStore>(
              builder: (context, store, _) => TabBar(
                controller: _tabController,
                labelColor: AppColors.primary400,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                indicatorColor: AppColors.primary400,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                tabs: [
                  _buildCountTab(
                    label: 'Available',
                    count: store.notStartedCount,
                    icon: Icons.explore,
                  ),
                  _buildCountTab(
                    label: 'In Progress',
                    count:
                        store.inProgressCount + store.pendingVerificationCount,
                    icon: Icons.pending_actions,
                  ),
                  _buildCountTab(
                    label: 'Completed',
                    count: store.completedCount,
                    icon: Icons.check_circle,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<QuestsStore>(
              builder: (context, store, child) {
                if (store.isLoadingAll || store.isLoadingMy) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (store.lastError != null &&
                    store.allQuests.isEmpty &&
                    store.myQuests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          store.lastError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadQuests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => store.refresh(),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableTab(store, viewMode),
                      _buildInProgressTab(store, viewMode),
                      _buildCompletedTab(store, viewMode),
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

  Widget _buildCountTab({
    required String label,
    required int count,
    required IconData icon,
  }) {
    return Tab(
      height: 40,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13),
            const SizedBox(width: 4),
            Text('$label ($count)'),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab(QuestsStore store, FeedViewMode viewMode) {
    var quests = store.getAvailableQuests();

    // Apply filters
    if (_selectedCategory != null) {
      quests = quests.where((q) => q.category == _selectedCategory).toList();
    }
    if (_selectedType != null) {
      quests = quests.where((q) => q.type == _selectedType).toList();
    }

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No available quests',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new quests!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        return _QuestCard(
          mode: viewMode,
          quest: quest,
          status: QuestStatus.notStarted,
          onTap: () => _navigateToQuestDetail(quest),
        );
      },
    );
  }

  Widget _buildInProgressTab(QuestsStore store, FeedViewMode viewMode) {
    var quests = store.getInProgressQuests();
    quests.addAll(store.getPendingQuests());

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No quests in progress',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'Open an available quest and verify when ready.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final userQuest = quests[index];
        return _QuestCard(
          mode: viewMode,
          quest: userQuest.quest,
          status: userQuest.status,
          progress: userQuest.progress,
          onTap: () => _navigateToQuestDetail(userQuest.quest, userQuest),
        );
      },
    );
  }

  Widget _buildCompletedTab(QuestsStore store, FeedViewMode viewMode) {
    final quests = store.getCompletedQuests();

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No completed quests yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quests to earn rewards!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final userQuest = quests[index];
        return _QuestCard(
          mode: viewMode,
          quest: userQuest.quest,
          status: userQuest.status,
          completedAt: userQuest.completedAt,
          onTap: () => _navigateToQuestDetail(userQuest.quest, userQuest),
        );
      },
    );
  }

  void _navigateToQuestDetail(QuestModel quest, [UserQuestModel? userQuest]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestDetailPage(
          quest: quest,
          userQuest: userQuest,
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.mode,
    required this.quest,
    required this.status,
    this.progress,
    this.completedAt,
    this.onTap,
  });

  final FeedViewMode mode;
  final QuestModel quest;
  final QuestStatus status;
  final int? progress;
  final DateTime? completedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCardMode = mode == FeedViewMode.card;
    final hasFooterMeta =
        completedAt != null || status != QuestStatus.notStarted;

    if (!isCardMode) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(status.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    quest.type.iconData,
                    color: Color(status.color),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            quest.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuestPointsPill(
                          points: quest.rewardPoints,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      quest.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        BadgeCategoryChip(
                          category: quest.category,
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                        _QuestStatusChip(status: status, compact: true),
                        const Spacer(),
                        if (completedAt != null)
                          Text(
                            _formatDate(completedAt!),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, hasFooterMeta ? 14 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(status.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        quest.type.iconData,
                        color: Color(status.color),
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            BadgeCategoryChip(
                              category: quest.category,
                              compact: true,
                            ),
                            const SizedBox(width: 6),
                            _QuestStatusChip(status: status, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _QuestPointsPill(points: quest.rewardPoints),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                quest.description,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasFooterMeta) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    if (completedAt != null)
                      Text(
                        'Completed ${_formatDate(completedAt!)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      )
                    else if (status != QuestStatus.notStarted)
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}

class _QuestPointsPill extends StatelessWidget {
  const _QuestPointsPill({
    required this.points,
    this.compact = false,
  });

  final int points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade400.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.amber.shade400.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            size: compact ? 11 : 12,
            color: Colors.amber.shade400,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            '$points BNP',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: Colors.amber.shade400,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestStatusChip extends StatelessWidget {
  const _QuestStatusChip({
    required this.status,
    this.compact = false,
  });

  final QuestStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(status.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(status.color).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: Color(status.color),
        ),
      ),
    );
  }
}
