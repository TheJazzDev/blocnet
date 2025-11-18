import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final notificationsProvider = context.read<NotificationsProvider>();

    if (authProvider.currentUser != null) {
      notificationsProvider.initialize(authProvider.currentUser!.id);
      notificationsProvider.listenToNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notificationsProvider = context.watch<NotificationsProvider>();

    if (authProvider.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('Please sign in to view notifications'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationsProvider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                notificationsProvider
                    .markAllAsRead(authProvider.currentUser!.id);
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: notificationsProvider.notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Follow projects to get notified about updates',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh is handled by stream
              },
              child: ListView.builder(
                itemCount: notificationsProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notification =
                      notificationsProvider.notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () {
                      notificationsProvider.markAsRead(notification.id);
                      // TODO: Navigate to relevant screen
                    },
                    onDismiss: () {
                      notificationsProvider.deleteNotification(notification.id);
                    },
                  );
                },
              ),
            ),
    );
  }
}
