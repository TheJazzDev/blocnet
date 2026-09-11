import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class ManageUpdatesScreen extends StatefulWidget {
  const ManageUpdatesScreen({super.key});

  @override
  State<ManageUpdatesScreen> createState() => _ManageUpdatesScreenState();
}

class _ManageUpdatesScreenState extends State<ManageUpdatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatesStore>().fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final mode = context.watch<FeedViewModeStore>().mode;
    final isCardMode = mode == FeedViewMode.card;

    if (!auth.canCreateUpdate) {
      return Scaffold(
        backgroundColor: AppColors.bgBase,
        appBar: _appBar(context),
        body: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Text(
            'Your current role does not allow managing updates.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Consumer<UpdatesStore>(
      builder: (context, store, _) {
        final userId = auth.userId ?? '';
        final own = store.updates.where((u) => u.adminId == userId).toList();

        // Calculate stats
        final totalUpdates = own.length;
        final totalLikes = own.fold<int>(0, (sum, u) => sum + u.likesCount);
        final totalComments = own.fold<int>(0, (sum, u) => sum + u.commentsCount);

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: _appBar(context),
          body: store.isFetching && store.updates.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal400,
                    strokeWidth: 2,
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.teal400,
                  backgroundColor: AppColors.bgSurface,
                  onRefresh: store.refreshUpdates,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                    children: [
                      if (store.lastError != null && store.lastError!.isNotEmpty) ...[
                        Text(
                          store.lastError!,
                          style: AppTypography.custom(
                            color: AppColors.error500,
                            size: AppText.bodySize,
                            weight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],

                      // Stats Overview
                      if (own.isNotEmpty) ...[
                        _StatsOverview(
                          totalUpdates: totalUpdates,
                          totalLikes: totalLikes,
                          totalComments: totalComments,
                        ),
                        const SizedBox(height: AppSpace.xl),
                      ],

                      // Empty State
                      if (own.isEmpty)
                        _EmptyState()
                      else ...[
                        // Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Updates',
                              style: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: AppText.subtitleSize,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$totalUpdates ${totalUpdates == 1 ? 'update' : 'updates'}',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: AppText.labelSize,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),

                        // Updates List
                        ...own.asMap().entries.map(
                          (entry) => _UpdateTile(
                            mode: mode,
                            showDivider: !isCardMode && entry.key != own.length - 1,
                            update: entry.value,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return CustomAppBar(
      title: 'My Updates',
      showSearch: false,
      showFilter: false,
      showSpaceSwitcher: false,
    );
  }
}

// ─── Stats Overview ───────────────────────────────────────────────────────────

class _StatsOverview extends StatelessWidget {
  const _StatsOverview({
    required this.totalUpdates,
    required this.totalLikes,
    required this.totalComments,
  });

  final int totalUpdates;
  final int totalLikes;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.campaign_rounded,
              label: 'Updates',
              value: totalUpdates.toString(),
              color: AppColors.teal400,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.favorite_border,
              label: 'Likes',
              value: _formatNumber(totalLikes),
              color: AppColors.primary400,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.comment_outlined,
              label: 'Comments',
              value: _formatNumber(totalComments),
              color: AppColors.teal300,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppIcon.md,
          color: color,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.hair),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.captionSize,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.teal400.withValues(alpha: 0.2),
                  AppColors.teal400.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.teal400.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.campaign_rounded,
              size: AppIcon.xl,
              color: AppColors.teal400,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'No Updates Yet',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.subtitleSize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'You haven\'t created any updates yet.\nHead to Hunter Hub to create your first update.',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.hunterHub),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.teal400, AppColors.teal500],
                ),
                borderRadius: BorderRadius.circular(AppRadius.mdValue),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal400.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    size: AppIcon.md,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'Go to Hunter Hub',
                    style: AppTypography.custom(
                      color: Colors.white,
                      size: AppText.bodySize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Update Tile ──────────────────────────────────────────────────────────────

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({
    required this.update,
    required this.mode,
    this.showDivider = false,
  });

  final Update update;
  final FeedViewMode mode;
  final bool showDivider;

  void _openDetails(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: update.id);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCardMode = mode == FeedViewMode.card;
    final priorityColor = update.priority.color;

    final tile = GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: EdgeInsets.only(bottom: isCardMode ? 12 : 0),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: isCardMode
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.bgSurface,
                    AppColors.bgSurface.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lgValue),
                border: Border.all(
                  color: priorityColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: priorityColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCardMode)
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          priorityColor.withValues(alpha: 0.2),
                          priorityColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      size: AppIcon.md,
                      color: priorityColor,
                    ),
                  )
                else
                  Icon(
                    Icons.campaign_rounded,
                    size: AppIcon.md,
                    color: priorityColor,
                  ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              update.title,
                              style: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: AppText.bodySize,
                                weight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.sm, vertical: AppSpace.hair),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.smValue),
                              border: Border.all(
                                color: priorityColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpace.xs),
                                Text(
                                  update.priority.label.toUpperCase(),
                                  style: AppTypography.custom(
                                    color: priorityColor,
                                    size: AppText.captionSize,
                                    weight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: AppIcon.xs,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Expanded(
                            child: Text(
                              update.project?.name ?? 'Gem',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: AppText.labelSize,
                                weight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        update.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: AppText.bodySize,
                          weight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCardMode) ...[
                  const SizedBox(width: AppSpace.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppIcon.md,
                    color: AppColors.textFaint,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.md),
            // Engagement metrics
            Row(
              children: [
                _MetricChip(
                  icon: Icons.favorite_border,
                  value: update.likesCount,
                  color: AppColors.primary400,
                ),
                const SizedBox(width: AppSpace.sm),
                _MetricChip(
                  icon: Icons.comment_outlined,
                  value: update.commentsCount,
                  color: AppColors.teal300,
                ),
                const Spacer(),
                Text(
                  _formatDate(update.createdAt),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.captionSize,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isCardMode) return tile;

    return Column(
      children: [
        tile,
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Divider(
              height: 1,
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.smValue),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppIcon.xs,
            color: color,
          ),
          const SizedBox(width: AppSpace.xs),
          Text(
            value.toString(),
            style: AppTypography.custom(
              color: color,
              size: AppText.captionSize,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
