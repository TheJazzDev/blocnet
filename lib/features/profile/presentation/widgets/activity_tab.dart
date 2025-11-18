import 'package:flutter/material.dart';
import '../../data/models/activity_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityTab extends StatelessWidget {
  final List<UserActivity> activities;

  const ActivityTab({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No activity yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your activity will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getActivityColor(activity.type),
            child: Icon(
              _getActivityIcon(activity.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(activity.description),
          subtitle: Text(timeago.format(activity.timestamp)),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        );
      },
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.followedProject:
        return Icons.add_circle;
      case ActivityType.unfollowedProject:
        return Icons.remove_circle;
      case ActivityType.savedPost:
        return Icons.bookmark;
      case ActivityType.unsavedPost:
        return Icons.bookmark_border;
      case ActivityType.likedPost:
        return Icons.favorite;
      case ActivityType.commentedOnPost:
        return Icons.comment;
      case ActivityType.createdProject:
        return Icons.create;
      case ActivityType.createdPost:
        return Icons.post_add;
      case ActivityType.updatedProject:
        return Icons.edit;
      case ActivityType.updatedPost:
        return Icons.edit;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.followedProject:
        return Colors.green;
      case ActivityType.unfollowedProject:
        return Colors.grey;
      case ActivityType.savedPost:
        return Colors.blue;
      case ActivityType.unsavedPost:
        return Colors.grey;
      case ActivityType.likedPost:
        return Colors.red;
      case ActivityType.commentedOnPost:
        return Colors.orange;
      case ActivityType.createdProject:
        return Colors.purple;
      case ActivityType.createdPost:
        return Colors.teal;
      case ActivityType.updatedProject:
        return Colors.indigo;
      case ActivityType.updatedPost:
        return Colors.cyan;
    }
  }
}
