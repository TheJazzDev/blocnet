import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/auth/presentation/widgets/spaces/space_meta.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/cross_space_notification_sheet.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_category_filter_bar.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/notifications/notification_navigator.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

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
              if (store.unreadCount > 0)
                GestureDetector(
                  onTap: store.markAllRead,
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSpace.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: AppText.captionSize,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              NotificationCategoryFilterBar(
                selectedKey: _selectedCategory,
                options: notificationCategoryFilters,
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
                        ? const EmptyNotificationsState()
                        : RefreshIndicator(
                            color: AppColors.teal400,
                            backgroundColor: AppColors.bgSurface,
                            onRefresh: () => store.refreshNotifications(
                              category: _selectedCategory,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpace.lg, AppSpace.sm, AppSpace.lg, 96),
                              itemBuilder: (context, index) {
                                final itemCount = store.notifications.length;
                                if (index >= itemCount) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: AppSpace.lg),
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
                                return NotificationRowWrapper(
                                  mode: viewMode,
                                  showDivider: !isLastItem,
                                  child: NotificationTile(
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

  Future<void> _openNotificationTarget(NotificationModel item) async {
    final auth = context.read<AuthStore>();
    final target = NotificationSpaceTarget.crossSpaceFor(
      type: item.type,
      deeplink: item.deeplink,
      activeSpace: auth.activeSpace,
      hasHunterSpace: auth.hasHunterSpace,
      hasModerationSpace: auth.hasModerationSpace,
    );
    final postId = item.payload?['postId']?.toString();

    if (target != null) {
      final switchSpace = await showCrossSpaceNotificationSheet(
        context,
        item: item,
        target: target,
        currentSpaceLabel: SpaceMeta.currentFor(auth).label,
      );
      if (!switchSpace || !mounted) return;
      await NotificationNavigator.switchSpaceAndOpen(
        context,
        target: target,
        type: item.type,
        updateId: item.updateId,
        postId: postId,
        deeplink: item.deeplink,
        payload: item.payload,
      );
      return;
    }

    await NotificationNavigator.handleNotificationPayload(
      context,
      type: item.type,
      updateId: item.updateId,
      postId: postId,
      deeplink: item.deeplink,
      payload: item.payload,
    );
  }
}
