import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
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
                            onTap: () => store.markAsRead(item.id),
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
              'Follow projects to receive urgency updates and post alerts.',
            ),
          ],
        ),
      ),
    );
  }
}
