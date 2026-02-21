import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/notifications/data/models/digest_summary_model.dart';
import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
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

        final digest = store.digestSummary;
        final hasDigest = digest?.hasAnyInsight ?? false;
        final hasContent = store.notifications.isNotEmpty || hasDigest;

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: CustomAppBar(
            title: 'Alerts',
            backButton: true,
            showSearch: false,
            showFilter: false,
            actions: [
              if (store.unreadCount > 0)
                GestureDetector(
                  onTap: store.markAllRead,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Mark all read',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: store.isFetching && !hasContent
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.teal400,
                    strokeWidth: 2,
                  ),
                )
              : !hasContent
                  ? const _EmptyNotificationsState()
                  : RefreshIndicator(
                      color: AppColors.teal400,
                      backgroundColor: AppColors.bgSurface,
                      onRefresh: store.refreshNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemBuilder: (context, index) {
                          final hasDigestTile = hasDigest;

                          if (hasDigestTile && index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DigestTile(
                                digest: digest!,
                                onTap: () => _openDigestSheet(digest),
                              ),
                            );
                          }

                          final itemIndex = hasDigestTile ? index - 1 : index;
                          final item = store.notifications[itemIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _NotificationTile(
                              item: item,
                              onTap: () async {
                                await store.markAsRead(item.id);
                                if (!mounted) return;
                                await _openNotificationTarget(item);
                              },
                            ),
                          );
                        },
                        itemCount:
                            store.notifications.length + (hasDigest ? 1 : 0),
                      ),
                    ),
        );
      },
    );
  }

  Future<void> _openNotificationTarget(NotificationModel item) async {
    final type = item.type ?? '';
    final updateId = item.updateId ?? item.payload?['updateId']?.toString();

    if (type == 'project_update' || type == 'comment_received') {
      if (updateId == null || updateId.isEmpty) return;
      await _openUpdateDetails(updateId);
      return;
    }

    if (_isWalletType(type)) {
      _pushNamed(AppRoutes.walletTransactions);
      return;
    }

    if (type == 'community_liked' || type == 'community_bookmarked') {
      final postId = item.payload?['postId']?.toString();
      if (postId != null && postId.isNotEmpty) {
        _pushNamed(AppRoutes.communityDiscussion, arguments: postId);
      } else {
        _pushNamed(AppRoutes.main);
      }
      return;
    }

    if (type == 'profile_followed' || type == 'profile_unfollowed') {
      _pushNamed(AppRoutes.profile);
      return;
    }

    if (_isGovernanceType(type)) {
      if (type == 'project_invite_received' ||
          type == 'project_invite_responded' ||
          type == 'project_assignment_changed') {
        _pushNamed(AppRoutes.manageProjects);
      } else {
        _pushNamed(AppRoutes.profile);
      }
      return;
    }

    final deeplink = item.deeplink?.trim() ?? '';
    if (deeplink.startsWith('/wallet/transactions')) {
      _pushNamed(AppRoutes.walletTransactions);
      return;
    }
    if (deeplink.startsWith('/wallet')) {
      _pushNamed(AppRoutes.wallet);
      return;
    }
    if (deeplink.startsWith('/updates') && updateId != null) {
      await _openUpdateDetails(updateId);
      return;
    }

    _pushNamed(AppRoutes.main);
  }

  bool _isWalletType(String type) {
    return type.startsWith('wallet_') ||
        type == 'wallet_transfer_sent' ||
        type == 'wallet_transfer_received';
  }

  bool _isGovernanceType(String type) {
    return type == 'project_proposal_submitted' ||
        type == 'project_proposal_reviewed' ||
        type == 'admin_application_submitted' ||
        type == 'admin_application_reviewed' ||
        type == 'project_invite_received' ||
        type == 'project_invite_responded' ||
        type == 'project_assignment_changed' ||
        type == 'role_changed';
  }

  void _pushNamed(String route, {Object? arguments}) {
    if (!mounted) return;
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  Future<void> _openUpdateDetails(String updateId) async {
    final updatesStore = context.read<UpdatesStore>();
    final exists = updatesStore.updates.any((u) => u.id == updateId);

    if (!exists) {
      await updatesStore.refreshUpdates();
      if (!mounted) return;
    }

    final resolved = updatesStore.updates.any((u) => u.id == updateId);
    if (!resolved) {
      if (!mounted) return;
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

  Future<void> _openDigestSheet(DigestSummary digest) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your 7-day Intel Recap',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 18,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (digest.missedHighUrgency.isNotEmpty) ...[
                  const _DigestSectionLabel('Missed High Urgency'),
                  const SizedBox(height: 6),
                  ...digest.missedHighUrgency.take(3).map(
                        (entry) => _DigestLine(
                          title: entry.title,
                          subtitle: entry.projectName,
                        ),
                      ),
                  const SizedBox(height: 12),
                ],
                if (digest.activeProjects.isNotEmpty) ...[
                  const _DigestSectionLabel('Most Active Projects'),
                  const SizedBox(height: 6),
                  ...digest.activeProjects.take(3).map(
                        (entry) => _DigestLine(
                          title: entry.projectName,
                          subtitle:
                              '${entry.newCount} updates · ${entry.highCount} high',
                        ),
                      ),
                  const SizedBox(height: 12),
                ],
                if (digest.topCommunityPosts.isNotEmpty) ...[
                  const _DigestSectionLabel('Top Community Thread'),
                  const SizedBox(height: 6),
                  _DigestLine(
                    title: digest.topCommunityPosts.first.contentPreview,
                    subtitle:
                        '${digest.topCommunityPosts.first.likesCount} likes · ${digest.topCommunityPosts.first.commentsCount} comments',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DigestTile extends StatelessWidget {
  const _DigestTile({
    required this.digest,
    required this.onTap,
  });

  final DigestSummary digest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.summarize_outlined,
                color: AppColors.primary400, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your 7-day recap',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${digest.missedHighUrgency.length} missed high alerts · ${digest.activeProjects.length} active projects',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.primary400,
            ),
          ],
        ),
      ),
    );
  }
}

class _DigestSectionLabel extends StatelessWidget {
  const _DigestSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.custom(
        color: AppColors.textFaint,
        size: 10,
        weight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _DigestLine extends StatelessWidget {
  const _DigestLine({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationVisualStyle {
  const _NotificationVisualStyle({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

_NotificationVisualStyle _styleForNotificationType(String? type) {
  switch (type) {
    case 'project_update':
    case 'comment_received':
      return _NotificationVisualStyle(
        icon: Icons.campaign_outlined,
        color: AppColors.teal400,
        label: 'Update',
      );
    case 'profile_followed':
    case 'profile_unfollowed':
    case 'community_liked':
    case 'community_bookmarked':
      return _NotificationVisualStyle(
        icon: Icons.people_alt_outlined,
        color: AppColors.primary400,
        label: 'Social',
      );
    case 'project_proposal_submitted':
    case 'project_proposal_reviewed':
    case 'admin_application_submitted':
    case 'admin_application_reviewed':
    case 'project_invite_received':
    case 'project_invite_responded':
    case 'project_assignment_changed':
    case 'role_changed':
      return _NotificationVisualStyle(
        icon: Icons.gavel_outlined,
        color: AppColors.warning500,
        label: 'Governance',
      );
    case 'wallet_transfer_sent':
    case 'wallet_transfer_received':
    case 'wallet_deposit_credited':
    case 'wallet_withdrawal_requested':
    case 'wallet_withdrawal_approved':
    case 'wallet_withdrawal_rejected':
    case 'wallet_withdrawal_broadcasted':
    case 'wallet_withdrawal_confirmed':
    case 'wallet_withdrawal_reverted':
    case 'wallet_kyc_reviewed':
    case 'wallet_provision_ready':
    case 'wallet_provision_failed':
      return _NotificationVisualStyle(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successColor,
        label: 'Wallet',
      );
    default:
      return _NotificationVisualStyle(
        icon: Icons.notifications_none_rounded,
        color: AppColors.textMuted,
        label: 'System',
      );
  }
}

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
    final style = _styleForNotificationType(item.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.teal500.withValues(alpha: 0.06)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppColors.teal500.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnread ? AppColors.teal400 : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: style.color.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                style.icon,
                size: 16,
                color: style.color,
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
                    style: AppTypography.custom(
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 12,
                      weight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: style.color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      style.label,
                      style: AppTypography.custom(
                        color: style.color,
                        size: 10,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeLabel(),
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 11,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Symbols.notifications_off,
                size: 24,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No alerts yet',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Follow gems to receive priority and update alerts.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
