import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/blocked_users/blocked_user_row.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/public_profile/public_profile_block_dialog.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
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

    final confirmed = await confirmPublicProfileBlock(context, isBlocked: true);
    if (!confirmed || !mounted) return;

    setState(() => _pendingUnblockIds.add(user.blockedId));
    final success =
        await context.read<BlocksStore>().unblockUser(user.blockedId);
    if (!mounted) return;
    setState(() => _pendingUnblockIds.remove(user.blockedId));

    if (!success) {
      AppSnackbar.showError(context, 'Could not unblock this user');
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
          final users = store.blockedUsers;
          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: store.fetchBlockedUsers,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
              children: [
                SectionLabel(
                  'Blocked',
                  icon: Icons.block_outlined,
                  trailing: users.isEmpty
                      ? null
                      : Text(
                          '${users.length}',
                          style: AppText.caption(AppColors.textFaint,
                              weight: AppText.bold),
                        ),
                ),
                AppSpace.gapSm,
                _content(store, users),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _content(BlocksStore store, List<BlockedUser> users) {
    if (store.isLoading && users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary400,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (store.error != null && users.isEmpty) {
      return ProfileRowGroup(
        children: [
          ProfileInlineState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load blocked users',
            actionLabel: 'Retry',
            onAction: store.fetchBlockedUsers,
          ),
        ],
      );
    }
    if (users.isEmpty) {
      return const ProfileRowGroup(
        children: [
          ProfileInlineState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No one blocked',
            hint: 'Block from a member’s profile.',
          ),
        ],
      );
    }
    return ProfileRowGroup(
      children: [
        for (final user in users)
          BlockedUserRow(
            key: ValueKey(user.blockedId),
            user: user,
            isPending: _pendingUnblockIds.contains(user.blockedId),
            onUnblock: () => _unblockUser(user),
          ),
      ],
    );
  }
}
