import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/blocks_store.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final Set<String> _pendingUnblockIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BlocksStore>().fetchBlockedUsers();
    });
  }

  Future<void> _unblockUser(BlockedUser user) async {
    if (_pendingUnblockIds.contains(user.blockedId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Unblock user?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will start seeing their posts and comments again.',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 13,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Unblock',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _pendingUnblockIds.add(user.blockedId));
    final success =
        await context.read<BlocksStore>().unblockUser(user.blockedId);
    if (!mounted) return;
    setState(() => _pendingUnblockIds.remove(user.blockedId));

    if (!success) {
      final error =
          context.read<BlocksStore>().error ?? 'Failed to unblock user';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Blocked Users',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<BlocksStore>(
        builder: (context, store, _) {
          final blockedUsers = store.blockedUsers;

          if (store.isLoading && blockedUsers.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary400,
                strokeWidth: 2,
              ),
            );
          }

          if (store.error != null && blockedUsers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.error!,
                      textAlign: TextAlign.center,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 13,
                        weight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: store.fetchBlockedUsers,
                      child: Text(
                        'Retry',
                        style: AppTypography.custom(
                          color: AppColors.primary400,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (blockedUsers.isEmpty) {
            return Center(
              child: Text(
                'No blocked users',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 14,
                  weight: FontWeight.w500,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: store.fetchBlockedUsers,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: blockedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                final name =
                    (user.blocked.displayName?.trim().isNotEmpty ?? false)
                        ? user.blocked.displayName!.trim()
                        : (user.blocked.username?.trim().isNotEmpty ?? false)
                            ? user.blocked.username!.trim()
                            : 'User';
                final username =
                    (user.blocked.username?.trim().isNotEmpty ?? false)
                        ? '@${user.blocked.username!.trim()}'
                        : null;
                final isPending = _pendingUnblockIds.contains(user.blockedId);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        radius: 19,
                        imageUrl: user.blocked.avatarUrl,
                        fallback: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: AppTypography.custom(
                            color: AppColors.primary400,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.custom(
                                color: AppColors.textPrimary,
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (username != null)
                              Text(
                                username,
                                style: AppTypography.custom(
                                  color: AppColors.textMuted,
                                  size: 12,
                                  weight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: isPending ? null : () => _unblockUser(user),
                        child: Text(
                          isPending ? '...' : 'Unblock',
                          style: AppTypography.custom(
                            color: AppColors.primary400,
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
