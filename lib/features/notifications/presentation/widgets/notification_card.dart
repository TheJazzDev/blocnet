import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      child: Container(
        color: notification.isRead ? null : Colors.blue.withOpacity(0.1),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                timeago.format(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: onTap,
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newPost:
        return Icons.post_add;
      case NotificationType.postUpdate:
        return Icons.edit;
      case NotificationType.commentReply:
        return Icons.comment;
      case NotificationType.projectUpdate:
        return Icons.update;
      case NotificationType.urgentPost:
        return Icons.priority_high;
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.liked:
        return Icons.favorite;
      case NotificationType.mentioned:
        return Icons.alternate_email;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newPost:
        return Colors.blue;
      case NotificationType.postUpdate:
        return Colors.orange;
      case NotificationType.commentReply:
        return Colors.green;
      case NotificationType.projectUpdate:
        return Colors.purple;
      case NotificationType.urgentPost:
        return Colors.red;
      case NotificationType.newFollower:
        return Colors.teal;
      case NotificationType.liked:
        return Colors.pink;
      case NotificationType.mentioned:
        return Colors.indigo;
    }
  }
}
