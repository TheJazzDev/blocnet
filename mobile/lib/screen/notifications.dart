import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
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
          appBar: AppBar(
            title: const Text('Notifications'),
            centerTitle: true,
            backgroundColor: AppColors.darkGrey50,
            actions: [
              IconButton(
                onPressed: store.unreadCount == 0 ? null : store.markAllRead,
                icon: Icon(Symbols.mop, color: AppColors.darkGrey500),
              ),
            ],
          ),
          body: store.isFetching && store.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : store.notifications.isEmpty
                  ? const _EmptyNotificationsState()
                  : RefreshIndicator(
                      onRefresh: store.refreshNotifications,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = store.notifications[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await store.markAsRead(item.id);
                              if (!mounted) return;
                              await _openNotificationTarget(item);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isRead
                                    ? AppColors.darkGrey100
                                    : AppColors.darkGrey75,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: item.isRead
                                      ? AppColors.darkGrey200
                                      : AppColors.primary500,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: item.isRead
                                          ? AppColors.darkGrey400
                                          : AppColors.primary500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        StyledBodyText700(item.title, size: 14),
                                        const SizedBox(height: 4),
                                        StyledBodyText500(item.body),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StyledBodyText500(
                                    _formatTimeLabel(item),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: store.notifications.length,
                      ),
                    ),
        );
      },
    );
  }

  String _formatTimeLabel(NotificationModel item) {
    final now = DateTime.now();
    final difference = now.difference(item.createdAt);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  Future<void> _openNotificationTarget(NotificationModel item) async {
    final updateId = item.updateId;
    if (updateId == null || updateId.isEmpty) {
      return;
    }

    final updatesStore = context.read<UpdatesStore>();
    final exists = updatesStore.updates.any((update) => update.id == updateId);

    if (!exists) {
      await updatesStore.refreshUpdates();
      if (!mounted) return;
    }

    final resolved =
        updatesStore.updates.any((update) => update.id == updateId);
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
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: updateId);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Symbols.notifications_off, size: 40),
            SizedBox(height: 12),
            StyledBodyText700('No notifications yet'),
            SizedBox(height: 6),
            StyledBodyText500(
              'Follow projects to receive urgency and update alerts.',
            ),
          ],
        ),
      ),
    );
  }
}
