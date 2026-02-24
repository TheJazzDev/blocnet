import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/pages/quest_detail_page.dart';
import 'package:blocnet/services/quests_store.dart';
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
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    final store = context.read<QuestsStore>();
    await Future.wait([
      store.loadAllQuests(),
      store.loadMyQuests(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<QuestsStore>(
        builder: (context, store, child) {
          if (store.isLoadingAll || store.isLoadingMy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (store.lastError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
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
            child: Column(
              children: [
                _buildStatsBar(store),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableTab(store),
                      _buildInProgressTab(store),
                      _buildCompletedTab(store),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(QuestsStore store) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Available',
            store.notStartedCount.toString(),
            Icons.explore,
            Colors.blue,
          ),
          _buildStatItem(
            'In Progress',
            store.inProgressCount.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
          _buildStatItem(
            'Completed',
            store.completedCount.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailableTab(QuestsStore store) {
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
          quest: quest,
          status: QuestStatus.notStarted,
          onTap: () => _navigateToQuestDetail(quest),
        );
      },
    );
  }

  Widget _buildInProgressTab(QuestsStore store) {
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
              'Start a quest from the Available tab!',
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
          quest: userQuest.quest,
          status: userQuest.status,
          progress: userQuest.progress,
          onTap: () => _navigateToQuestDetail(userQuest.quest, userQuest),
        );
      },
    );
  }

  Widget _buildCompletedTab(QuestsStore store) {
    final quests = store.getCompletedQuests();

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade600),
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
          quest: userQuest.quest,
          status: userQuest.status,
          completedAt: userQuest.completedAt,
          onTap: () => _navigateToQuestDetail(userQuest.quest, userQuest),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Quests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...BadgeCategory.values.map((cat) => FilterChip(
                        label: Text(cat.displayName),
                        selected: _selectedCategory == cat,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Type', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedType == null,
                    onSelected: (_) {
                      setState(() => _selectedType = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...QuestType.values.map((type) => FilterChip(
                        label: Text(type.displayName),
                        selected: _selectedType == type,
                        onSelected: (_) {
                          setState(() => _selectedType = type);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
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
    required this.quest,
    required this.status,
    this.progress,
    this.completedAt,
    this.onTap,
  });

  final QuestModel quest;
  final QuestStatus status;
  final int? progress;
  final DateTime? completedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(status.color).withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(quest.type.icon, fontFamily: 'MaterialIcons'),
                      color: Color(status.color),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            BadgeCategoryChip(
                              category: quest.category,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                            _QuestStatusChip(status: status, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quest.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade300,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        size: 16,
                        color: Colors.amber.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${quest.rewardPoints} points',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (completedAt != null)
                    Text(
                      'Completed ${_formatDate(completedAt!)}',
                      style: TextStyle(
                        fontSize: 11,
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
        color: Color(status.color).withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(status.color).withValues(alpha:0.5),
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
