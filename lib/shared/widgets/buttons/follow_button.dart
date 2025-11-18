import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/projects/presentation/providers/interactions_provider.dart';
import '../../../core/utils/helpers.dart';

class FollowButton extends StatelessWidget {
  final String projectId;
  final String projectName;
  final bool isFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.isFollowing,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final interactionsProvider = context.read<InteractionsProvider>();

    if (authProvider.currentUser == null) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: () async {
        try {
          await interactionsProvider.toggleFollowProject(
            userId: authProvider.currentUser!.id,
            projectId: projectId,
            projectName: projectName,
            isCurrentlyFollowing: isFollowing,
          );

          if (context.mounted) {
            Helpers.showSuccess(
              context,
              isFollowing ? 'Unfollowed $projectName' : 'Following $projectName',
            );
          }

          onFollowChanged?.call();
        } catch (e) {
          if (context.mounted) {
            Helpers.showError(context, 'Failed to update follow status');
          }
        }
      },
      icon: Icon(
        isFollowing ? Icons.check : Icons.add,
        size: 16,
      ),
      label: Text(isFollowing ? 'Following' : 'Follow'),
      style: OutlinedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey.shade200 : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(80, 32),
      ),
    );
  }
}
