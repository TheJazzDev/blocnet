import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/notifications/notification_navigator.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

enum _CrossSpaceSurface {
  community,
  hunterHub,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.initialCategory,
  });

  final String? initialCategory;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _lastShownError;
  late String _selectedCategory;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _normalizeCategory(widget.initialCategory);
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<NotificationsStore>(context, listen: false);
      store.selectCategory(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsStore>(
      builder: (context, store, _) {
        if (store.lastError != null && store.lastError!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_lastShownError == store.lastError) return;
            _lastShownError = store.lastError;
            AppSnackbar.showError(context, store.lastError!);
          });
        }

        final digest = store.digestSummary;
        final hasInsights = digest?.hasAnyInsight ?? false;
        final hasContent = store.notifications.isNotEmpty;
        final viewMode = context.watch<FeedViewModeStore>().mode;

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: CustomAppBar(
            title: 'Notifications',
            backButton: true,
            showSearch: false,
            showFilter: false,
            showNotificationBell: false,
            actions: [
              if (hasInsights)
                GestureDetector(
                  onTap: () => _openInsights(digest),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Insights',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (store.unreadCount > 0)
                GestureDetector(
                  onTap: store.markAllRead,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              _NotificationCategoryFilterBar(
                selectedKey: _selectedCategory,
                options: _buildCategoryFilters(),
                onSelect: (categoryKey) async {
                  if (_selectedCategory == categoryKey) return;
                  setState(() {
                    _selectedCategory = categoryKey;
                  });
                  store.selectCategory(categoryKey);
                },
              ),
              if (store.isFetching) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: store.isFetching && !hasContent
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.teal400,
                          strokeWidth: 2,
                        ),
                      )
                    : !hasContent
                        ? const _EmptyNotificationsState()
                        : RefreshIndicator(
                            color: AppColors.teal400,
                            backgroundColor: AppColors.bgSurface,
                            onRefresh: () => store.refreshNotifications(
                              category: _selectedCategory,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                              itemBuilder: (context, index) {
                                final itemCount = store.notifications.length;
                                if (index >= itemCount) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final isLastItem = index == itemCount - 1;
                                final item = store.notifications[index];
                                return _NotificationRowWrapper(
                                  mode: viewMode,
                                  showDivider: !isLastItem,
                                  child: _NotificationTile(
                                    item: item,
                                    mode: viewMode,
                                    onTap: () async {
                                      await store.markAsRead(item.id);
                                      if (!mounted) return;
                                      await _openNotificationTarget(item);
                                    },
                                  ),
                                );
                              },
                              itemCount: store.notifications.length +
                                  (store.isFetchingMore ? 1 : 0),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _normalizeCategory(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'all';
    const allowed = {
      'all',
      'updates',
      'social',
      'governance',
      'wallet',
      'mining_referrals',
      'rewards',
      'system',
    };
    return allowed.contains(normalized) ? normalized : 'all';
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels < threshold) return;
    context.read<NotificationsStore>().loadMoreNotifications(
          category: _selectedCategory,
        );
  }

  List<_NotificationCategoryFilter> _buildCategoryFilters() {
    return [
      _NotificationCategoryFilter(
        key: 'all',
        label: 'All',
        color: AppColors.textSecondary,
      ),
      _NotificationCategoryFilter(
        key: 'updates',
        label: 'Updates',
        color: AppColors.teal400,
      ),
      _NotificationCategoryFilter(
        key: 'social',
        label: 'Social',
        color: AppColors.primary400,
      ),
      _NotificationCategoryFilter(
        key: 'governance',
        label: 'Governance',
        color: AppColors.warning500,
      ),
      _NotificationCategoryFilter(
        key: 'wallet',
        label: 'Wallet',
        color: AppColors.successColor,
      ),
      _NotificationCategoryFilter(
        key: 'mining_referrals',
        label: 'Mining & Referrals',
        color: AppColors.secondary500,
      ),
      _NotificationCategoryFilter(
        key: 'rewards',
        label: 'Rewards',
        color: AppColors.tagAirdrop,
      ),
      _NotificationCategoryFilter(
        key: 'system',
        label: 'System',
        color: AppColors.tagPartnership,
      ),
    ];
  }

  Future<void> _openNotificationTarget(NotificationModel item) async {
    final auth = context.read<AuthStore>();
    final crossSpaceSurface = _resolveCrossSpaceSurface(
      item: item,
      isHunterSpace: auth.isInHunterSpace,
    );
    if (crossSpaceSurface != null) {
      await _openCrossSpacePreview(
        item: item,
        targetSurface: crossSpaceSurface,
        currentSpaceLabel: auth.isInHunterSpace ? 'Hunter' : 'User',
      );
      return;
    }

    await NotificationNavigator.handleNotificationPayload(
      context,
      type: item.type,
      updateId: item.updateId,
      postId: item.payload?['postId']?.toString(),
      deeplink: item.deeplink,
      payload: item.payload,
    );
  }

  _CrossSpaceSurface? _resolveCrossSpaceSurface({
    required NotificationModel item,
    required bool isHunterSpace,
  }) {
    final type = item.type?.trim().toLowerCase() ?? '';
    final deeplinkPath =
        NotificationTargetResolver.parseDeeplink(item.deeplink).path;
    final targetsCommunity =
        type.startsWith('community_') || deeplinkPath.startsWith('/community');
    final targetsHunterHub = NotificationTargetResolver.isHunterHubType(type) ||
        deeplinkPath.startsWith('/hunter-hub') ||
        deeplinkPath.startsWith('/manage-updates') ||
        deeplinkPath.startsWith('/manage-projects');

    if (isHunterSpace && targetsCommunity) {
      return _CrossSpaceSurface.community;
    }
    if (!isHunterSpace && targetsHunterHub) {
      return _CrossSpaceSurface.hunterHub;
    }
    return null;
  }

  Future<void> _openCrossSpacePreview({
    required NotificationModel item,
    required _CrossSpaceSurface targetSurface,
    required String currentSpaceLabel,
  }) async {
    final destination = targetSurface == _CrossSpaceSurface.community
        ? 'User Community'
        : 'Hunter Hub';
    final helperText = targetSurface == _CrossSpaceSurface.community
        ? 'This alert belongs to Community in User space.'
        : 'This alert belongs to Hunter Hub in Hunter space.';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                destination,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 17,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.body,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  '$helperText You are in $currentSpaceLabel space, so this opens as an inline preview only.',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInsights(DigestSummary? digest) {
    if (!mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.notificationInsights,
      arguments: {'digest': digest},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationVisualStyle {
  const _NotificationVisualStyle({
    required this.icon,
    required this.color,
    required this.label,
    required this.categoryKey,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String categoryKey;
}

class _NotificationCategoryFilter {
  const _NotificationCategoryFilter({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}

String _categoryForNotificationType(String? type) {
  return NotificationTargetResolver.categoryForType(type);
}

_NotificationVisualStyle _styleForNotificationType(String? type) {
  final categoryKey = _categoryForNotificationType(type);
  switch (categoryKey) {
    case 'updates':
      return _NotificationVisualStyle(
        icon: Icons.campaign_outlined,
        color: AppColors.teal400,
        label: 'Updates',
        categoryKey: categoryKey,
      );
    case 'social':
      return _NotificationVisualStyle(
        icon: Icons.people_alt_outlined,
        color: AppColors.primary400,
        label: 'Social',
        categoryKey: categoryKey,
      );
    case 'governance':
      return _NotificationVisualStyle(
        icon: Icons.gavel_outlined,
        color: AppColors.warning500,
        label: 'Governance',
        categoryKey: categoryKey,
      );
    case 'wallet':
      return _NotificationVisualStyle(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successColor,
        label: 'Wallet',
        categoryKey: categoryKey,
      );
    case 'mining_referrals':
      return _NotificationVisualStyle(
        icon: Icons.bolt_rounded,
        color: AppColors.secondary500,
        label: 'Mining & Referrals',
        categoryKey: categoryKey,
      );
    case 'rewards':
      return _NotificationVisualStyle(
        icon: Icons.workspace_premium_outlined,
        color: AppColors.tagAirdrop,
        label: 'Rewards',
        categoryKey: categoryKey,
      );
    default:
      return _NotificationVisualStyle(
        icon: Icons.settings_suggest_outlined,
        color: AppColors.tagPartnership,
        label: 'System',
        categoryKey: categoryKey,
      );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.mode,
    required this.onTap,
  });

  final NotificationModel item;
  final FeedViewMode mode;
  final VoidCallback onTap;

  String _timeLabel() {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final style = _styleForNotificationType(item.type);

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary500.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isUnread
              ? style.color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(mode == FeedViewMode.card ? 10 : 8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: mode == FeedViewMode.card ? 10 : 12,
            horizontal: mode == FeedViewMode.card ? 10 : 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? style.color : Colors.transparent,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: style.color.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  style.icon,
                  size: 15,
                  color: style.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.custom(
                        color: isUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        size: 12.5,
                        weight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: AppTypography.custom(
                        color: isUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        size: 11.5,
                        weight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        style.label,
                        style: AppTypography.custom(
                          color: style.color,
                          size: 10,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeLabel(),
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10.5,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRowWrapper extends StatelessWidget {
  const _NotificationRowWrapper({
    required this.mode,
    required this.showDivider,
    required this.child,
  });

  final FeedViewMode mode;
  final bool showDivider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (mode == FeedViewMode.card) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: showDivider ? 6 : 2),
      child: child,
    );
  }
}

class _NotificationCategoryFilterBar extends StatelessWidget {
  const _NotificationCategoryFilterBar({
    required this.selectedKey,
    required this.options,
    required this.onSelect,
  });

  final String selectedKey;
  final List<_NotificationCategoryFilter> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.key == selectedKey;
          return GestureDetector(
            onTap: () => onSelect(option.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.color.withValues(alpha: 0.18)
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? option.color.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                option.label,
                style: AppTypography.custom(
                  color: isSelected ? option.color : AppColors.textMuted,
                  size: 11,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: options.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Symbols.notifications_off,
                size: 24,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No notifications yet',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Follow gems to receive priority and update alerts.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
