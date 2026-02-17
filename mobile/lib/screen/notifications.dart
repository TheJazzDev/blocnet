import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsStore>(
        context,
        listen: false,
      ).fetchNotificationsOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsStore>(
      builder: (context, store, _) {
        if (store.lastError != null && store.lastError!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(store.lastError!)),
            );
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            backgroundColor: AppColors.bgBase,
            title: Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (store.unreadCount > 0)
                GestureDetector(
                  onTap: store.markAllRead,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: store.isFetching && store.notifications.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal400,
                    strokeWidth: 2,
                  ),
                )
              : store.notifications.isEmpty
                  ? const _EmptyNotificationsState()
                  : RefreshIndicator(
                      color: AppColors.teal400,
                      backgroundColor: AppColors.bgSurface,
                      onRefresh: store.refreshNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = store.notifications[index];
                          return _NotificationTile(
                            item: item,
                            onTap: () async {
                              await store.markAsRead(item.id);
                              if (!mounted) return;
                              await _openNotificationTarget(item);
                            },
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemCount: store.notifications.length,
                      ),
                    ),
        );
      },
    );
  }

  Future<void> _openNotificationTarget(NotificationModel item) async {
    final updateId = item.updateId;
    if (updateId == null || updateId.isEmpty) return;

    final updatesStore = context.read<UpdatesStore>();
    final exists = updatesStore.updates.any((u) => u.id == updateId);

    if (!exists) {
      await updatesStore.refreshUpdates();
      if (!mounted) return;
    }

    final resolved = updatesStore.updates.any((u) => u.id == updateId);
    if (!resolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update not found. It may have been removed.'),
        ),
      );
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: updateId);
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
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationModel item;
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.teal500.withValues(alpha: 0.06)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? AppColors.teal500.withValues(alpha: 0.3) : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnread ? AppColors.teal400 : Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeLabel(),
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 11,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: Icon(
                Symbols.notifications_off,
                size: 26,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Follow projects to receive urgency and update alerts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontFamily: 'Geist',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
