import 'package:flutter/material.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../../../core/utils/helpers.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;

  const ProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            backgroundColor: Colors.grey.shade300,
            child: user.photoURL == null
                ? Text(
                    Helpers.getInitials(user.displayName ?? user.email),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              user.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                'Following',
                user.followedProjectIds.length,
              ),
              _buildStatColumn(
                'Saved',
                user.savedPostIds.length,
              ),
              if (user.isAdmin)
                _buildStatColumn(
                  'Projects',
                  user.adminProjectIds.length,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
