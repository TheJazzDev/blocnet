import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/levels/domain/level_tier.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_detail_sheet.dart';
import 'package:blocnet/features/levels/presentation/widgets/levels_page_states.dart';
import 'package:blocnet/features/levels/presentation/widgets/levels_progress_header.dart';
import 'package:blocnet/features/levels/presentation/widgets/tier_section.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/engagement/levels_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// All 15 levels grouped into their five tiers, with the user's own
/// progress pinned at the top. Respects the global list/card view mode.
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
      if (levelsStore.allLevels.isEmpty) {
        levelsStore.fetchAllLevels();
      }
      // Always refresh progress so the latest metrics are shown.
      levelsStore.fetchMyProgress();
    });
  }

  Future<void> _recalculate() async {
    final levelsStore = context.read<LevelsStore>();
    final ok = await levelsStore.recalculateMyLevel();
    if (!mounted || !ok || !levelsStore.levelChanged) return;

    final current = levelsStore.myProgress?.currentLevel;
    if (current == null) return;
    final tierColor = current.tierColor;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: tierColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          content: Text(
            'Level up! You are now Level ${current.level} · ${current.name}',
            style: AppTypography.custom(
              color: foregroundOn(tierColor),
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  void _openLevel(UserLevelModel level) {
    final levelsStore = context.read<LevelsStore>();
    final myProgress = levelsStore.myProgress;
    final currentLevelNumber = myProgress?.currentLevel.level ?? 0;

    LevelDetailSheet.show(
      context,
      level: level,
      isCurrent: level.level == currentLevelNumber,
      isLocked: level.level > currentLevelNumber,
      myProgress: myProgress,
    );
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
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
        actions: [_RefreshAction(onPressed: _recalculate)],
      ),
      body: Consumer<LevelsStore>(
        builder: (context, levelsStore, _) {
          final levels = levelsStore.allLevels;

          if (levels.isEmpty && levelsStore.isLoadingLevels) {
            return const LevelsLoadingState();
          }
          if (levels.isEmpty && levelsStore.levelsError != null) {
            return LevelsErrorState(
              message: levelsStore.levelsError!,
              onRetry: levelsStore.fetchAllLevels,
            );
          }
          if (levels.isEmpty) return const LevelsEmptyState();

          final myProgress = levelsStore.myProgress;
          final currentLevelNumber = myProgress?.currentLevel.level ?? 0;
          final mode = context.watch<FeedViewModeStore>().mode;
          final sections = groupLevelsByTier(levels);

          return RefreshIndicator(
            color: AppColors.primary500,
            onRefresh: () => Future.wait([
              levelsStore.fetchAllLevels(),
              levelsStore.fetchMyProgress(),
            ]),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.xl),
              itemCount: sections.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: LevelsProgressHeader(
                      progress: myProgress,
                      isLoading: levelsStore.isLoadingProgress,
                      error: levelsStore.progressError,
                      onRetry: levelsStore.fetchMyProgress,
                      onTap: myProgress == null
                          ? () {}
                          : () => _openLevel(myProgress.currentLevel),
                    ),
                  );
                }

                final section = sections[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: TierSection(
                    section: section,
                    currentLevelNumber: currentLevelNumber,
                    mode: mode,
                    onLevelTap: _openLevel,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// App bar refresh button that turns into a spinner while a level
/// recalculation is running.
class _RefreshAction extends StatelessWidget {
  const _RefreshAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.select<LevelsStore, bool>((s) => s.isRecalculating);

    if (busy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.refresh, color: AppColors.textPrimary),
      onPressed: onPressed,
      tooltip: 'Refresh progress',
    );
  }
}
