import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/notifications/presentation/utils/open_notification.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_category_filter_bar.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:blocnet/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shown instead of the store's raw error text (an exception's toString).
const notificationsLoadErrorText =
    "Couldn't load notifications. Pull down to try again.";

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
      if (!mounted) return;
      context.read<NotificationsStore>().selectCategory(_selectedCategory);
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
        _maybeShowError(store.lastError);
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
                TextButton(
                  onPressed: store.markAllRead,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary400,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(
                    'Mark all read',
                    style: AppText.label(
                      AppColors.primary400,
                      weight: AppText.bold,
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
                onSelect: (categoryKey) {
                  if (_selectedCategory == categoryKey) return;
                  setState(() => _selectedCategory = categoryKey);
                  store.selectCategory(categoryKey);
                },
              ),
              if (store.isFetching) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _body(store)),
            ],
          ),
        );
      },
    );
  }

  void _maybeShowError(String? error) {
    if (error == null || error.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastShownError == error) return;
      _lastShownError = error;
      AppSnackbar.showError(context, notificationsLoadErrorText);
    });
  }

  Widget _body(NotificationsStore store) {
    final items = store.notifications;
    if (store.isFetching && items.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary400,
          strokeWidth: 2,
        ),
      );
    }
    final showSpinner = store.isFetchingMore;
    final categoryLabel = _selectedCategory == 'all'
        ? null
        : styleForNotificationCategory(_selectedCategory).label;
    // The empty state sits in the list too, so pull-to-refresh still works.
    return RefreshIndicator(
      color: AppColors.primary400,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () =>
          store.refreshNotifications(category: _selectedCategory),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.xs, AppSpace.lg, 96),
        itemCount: items.isEmpty ? 1 : items.length + (showSpinner ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          if (items.isEmpty) {
            return EmptyNotificationsState(categoryLabel: categoryLabel);
          }
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = items[index];
          return NotificationTile(
            item: item,
            onTap: () async {
              await store.markAsRead(item.id);
              if (!context.mounted) return;
              await openNotificationTarget(context, item);
            },
          );
        },
      ),
    );
  }

  String _normalizeCategory(String? category) {
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return 'all';
    final allowed = notificationCategoryFilters.map((f) => f.key).toSet();
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
}
