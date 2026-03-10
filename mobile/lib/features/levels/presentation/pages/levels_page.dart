import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_detail_sheet.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Page showing all 15 levels with user's progress
class LevelsPage extends StatefulWidget {
  const LevelsPage({super.key});

  @override
  State<LevelsPage> createState() => _LevelsPageState();
}

class _LevelsPageState extends State<LevelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final levelsStore = context.read<LevelsStore>();
      // Always fetch levels if empty
      if (levelsStore.allLevels.isEmpty) {
        levelsStore.fetchAllLevels();
      }
      // Always fetch progress to ensure latest points are displayed
      levelsStore.fetchMyProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Levels',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<LevelsStore>(
        builder: (context, levelsStore, _) {
          if (levelsStore.isLoadingLevels) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary500),
            );
          }

          if (levelsStore.levelsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      levelsStore.levelsError!,
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => levelsStore.fetchAllLevels(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final levels = levelsStore.allLevels;
          final myProgress = levelsStore.myProgress;
          final currentLevelNumber = myProgress?.currentLevel.level ?? 0;
          final layoutMode = context.watch<FeedViewModeStore>().mode;

          if (levels.isEmpty) {
            return Center(
              child: Text(
                'No levels available',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary500,
            onRefresh: () async {
              await Future.wait([
                levelsStore.fetchAllLevels(),
                levelsStore.fetchMyProgress(),
              ]);
            },
            child: layoutMode == FeedViewMode.list
                ? _buildListView(levels, currentLevelNumber, myProgress)
                : _buildCardView(levels, currentLevelNumber, myProgress),
          );
        },
      ),
    );
  }

  void _showLevelDetail(
    BuildContext context,
    UserLevelModel level,
    bool isCurrent,
    bool isLocked,
    UserLevelProgressModel? myProgress,
  ) {
    LevelDetailSheet.show(
      context,
      level: level,
      isCurrent: isCurrent,
      isLocked: isLocked,
      myProgress: myProgress,
    );
  }

  Widget _buildListView(
    List<UserLevelModel> levels,
    int currentLevelNumber,
    UserLevelProgressModel? myProgress,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final isCurrent = level.level == currentLevelNumber;
        final isLocked = level.level > currentLevelNumber;

        return _LevelListItem(
          level: level,
          isCurrent: isCurrent,
          isLocked: isLocked,
          myProgress: myProgress,
          useCardStyle: false,
          onTap: () => _showLevelDetail(
            context,
            level,
            isCurrent,
            isLocked,
            myProgress,
          ),
        );
      },
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: AppColors.borderSubtle.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildCardView(
    List<UserLevelModel> levels,
    int currentLevelNumber,
    UserLevelProgressModel? myProgress,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final isCurrent = level.level == currentLevelNumber;
        final isLocked = level.level > currentLevelNumber;

        return _LevelCardItem(
          level: level,
          isCurrent: isCurrent,
          isLocked: isLocked,
          myProgress: myProgress,
          showDivider: false,
          onTap: () => _showLevelDetail(
            context,
            level,
            isCurrent,
            isLocked,
            myProgress,
          ),
        );
      },
    );
  }
}

class _LevelListItem extends StatelessWidget {
  const _LevelListItem({
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.myProgress,
    required this.onTap,
    this.useCardStyle = true,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final UserLevelProgressModel? myProgress;
  final VoidCallback onTap;
  final bool useCardStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: useCardStyle
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: useCardStyle
              ? (isCurrent
                  ? AppColors.primary500.withValues(alpha: 0.08)
                  : AppColors.bgSurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(useCardStyle ? 12 : 0),
          border: useCardStyle && isCurrent
              ? Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Opacity(
                opacity: isLocked ? 0.4 : 1.0,
                child: LevelBadge(
                  level: level,
                  size: LevelBadgeSize.medium,
                  showName: false,
                  showLevelNumber: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            level.name,
                            style: AppTypography.custom(
                              color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CURRENT',
                              style: AppTypography.custom(
                                color: Colors.white,
                                size: 9,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${level.level}',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    if (!isLocked || isCurrent) ...[
                      const SizedBox(height: 6),
                      Text(
                        level.description,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 10,
                          weight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCardItem extends StatelessWidget {
  const _LevelCardItem({
    required this.level,
    required this.isCurrent,
    required this.isLocked,
    required this.myProgress,
    required this.onTap,
    this.showDivider = true,
  });

  final UserLevelModel level;
  final bool isCurrent;
  final bool isLocked;
  final UserLevelProgressModel? myProgress;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary500.withValues(alpha: 0.08)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrent
              ? Border.all(color: AppColors.primary500.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CURRENT',
                      style: AppTypography.custom(
                        color: Colors.white,
                        size: 9,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Opacity(
                opacity: isLocked ? 0.4 : 1.0,
                child: LevelBadge(
                  level: level,
                  size: LevelBadgeSize.large,
                  showName: false,
                  showLevelNumber: false,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                level.name,
                style: AppTypography.custom(
                  color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Level ${level.level}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
              if (showDivider) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: AppColors.borderSubtle.withValues(alpha: 0.8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
