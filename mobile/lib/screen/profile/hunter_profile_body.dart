import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/user_profile_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

part 'hunter_profile_body_hero.part.dart';
part 'hunter_profile_body_content.part.dart';
part 'hunter_profile_body_shared.part.dart';

/// Profile body shown when the user is in Hunter space
/// (owner, admin, or hunter who has toggled to Hunter space).
class HunterProfileBody extends StatefulWidget {
  const HunterProfileBody({
    super.key,
    required this.auth,
    required this.onSignOut,
  });

  final AuthStore auth;
  final VoidCallback onSignOut;

  @override
  State<HunterProfileBody> createState() => _HunterProfileBodyState();
}

class _HunterProfileBodyState extends State<HunterProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProjectsStore>().fetchProjectsOnce();
      context.read<UpdatesStore>().fetchUpdatesOnce();
      final profileStore = context.read<UserProfileStore>();
      profileStore.fetchInitialOnce(userId: widget.auth.userId ?? '');
      profileStore.refreshFollowingProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final userId = auth.userId ?? '';
    final username = auth.username ?? auth.displayName ?? '';
    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? '').split('@').first;

    final projects = context.watch<ProjectsStore>().projects;
    final updates = context.watch<UpdatesStore>().updates;
    final followingCount =
        context.watch<UserProfileStore>().followingProfilesCount;

    final managedProjects = projects
        .where(
          (project) => _isCurrentHunterProject(
            project: project,
            userId: userId,
            username: username,
          ),
        )
        .toList();
    final hunterUpdates = updates
        .where(
          (update) => _isCurrentHunterUpdate(
            update: update,
            userId: userId,
            username: username,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final highSignals = hunterUpdates.where(
      (update) => update.priority.label.toLowerCase() == 'high',
    );
    final lowSignals = hunterUpdates.where(
      (update) => update.priority.label.toLowerCase() == 'low',
    );

    final qualityCount = hunterUpdates.where((update) {
      final label = update.priority.label.toLowerCase();
      return label == 'high' || label == 'mid' || label == 'medium';
    }).length;
    final successRate = hunterUpdates.isEmpty
        ? 0
        : ((qualityCount / hunterUpdates.length) * 100).round();

    final sentiment = _resolveSentiment(
      highCount: highSignals.length,
      lowCount: lowSignals.length,
      total: hunterUpdates.length,
    );

    final now = DateTime.now();
    final updatesLast7d = hunterUpdates
        .where((update) => now.difference(update.createdAt).inDays < 7)
        .length;
    final updatesLast30d = hunterUpdates
        .where((update) => now.difference(update.createdAt).inDays < 30)
        .length;
    final highUrgencyLast30d = hunterUpdates
        .where(
          (update) =>
              now.difference(update.createdAt).inDays < 30 &&
              update.priority.label.toLowerCase() == 'high',
        )
        .length;
    final highUrgencyShare30d =
        updatesLast30d == 0 ? 0.0 : (highUrgencyLast30d / updatesLast30d) * 100;
    final medianHoursBetweenUpdates = _medianHoursBetweenUpdates(hunterUpdates);
    final lastActiveAt =
        hunterUpdates.isEmpty ? null : hunterUpdates.first.createdAt;

    final followerCount = _resolveFollowerCount(
      projects: managedProjects,
      updates: hunterUpdates,
    );

    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () async {
        final projectsStore = context.read<ProjectsStore>();
        final updatesStore = context.read<UpdatesStore>();
        final userProfileStore = context.read<UserProfileStore>();
        await Future.wait([
          projectsStore.refreshProjects(),
          updatesStore.refreshUpdates(),
          userProfileStore.refreshAll(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HunterHero(
              displayName: displayName,
              avatarUrl: auth.avatarUrl,
              email: auth.email,
              bio: auth.bio,
              followersCount: followerCount,
              followingCount: followingCount,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _HunterStatCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.primary400,
                    label: 'Success Rate',
                    value: '$successRate%',
                    footnote: hunterUpdates.isEmpty
                        ? 'No signals yet'
                        : '${hunterUpdates.length} updates tracked',
                  ),
                  SizedBox(width: 10),
                  _HunterStatCard(
                    icon: Icons.thumb_up_alt_outlined,
                    iconColor: Color(0xFF4ADE80),
                    label: 'Sentiment',
                    value: sentiment.label,
                    valueSize: 16,
                    footnote: sentiment.footnote,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _HunterTrustChips(
                updatesLast7d: updatesLast7d,
                updatesLast30d: updatesLast30d,
                highUrgencyShare30d: highUrgencyShare30d,
                medianHoursBetweenUpdates: medianHoursBetweenUpdates,
                lastActiveAt: lastActiveAt,
              ),
            ),
            _CommunityVoiceSection(
              managedProjects: managedProjects,
              hunterUpdates: hunterUpdates,
              followersCount: followerCount,
            ),
            const SizedBox(height: 20),
            _HunterSignalsSection(updates: hunterUpdates),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HunterSectionLabel('Content'),
                  const SizedBox(height: 8),
                  _HunterTile(
                    icon: Icons.send_outlined,
                    title: 'Submit New Gem',
                    subtitle: 'Send a project for approval before publishing',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.submitProject),
                  ),
                  _HunterTile(
                    icon: Icons.folder_copy_outlined,
                    title: 'Manage My Gems',
                    subtitle: 'See projects you created or contribute to',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.manageProjects),
                  ),
                  _HunterTile(
                    icon: Icons.post_add_outlined,
                    title: 'Manage My Updates',
                    subtitle: 'Review and edit your hunter updates',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.manageUpdates),
                  ),
                  const SizedBox(height: 12),
                  const _HunterSectionLabel('More'),
                  const SizedBox(height: 8),
                  _HunterTile(
                    icon: Icons.history_edu_outlined,
                    title: 'Tip History (Received)',
                    subtitle: 'Review tips you received from supporters',
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.tipsHistory,
                      arguments: const {'direction': 'received'},
                    ),
                  ),
                  _HunterTile(
                    icon: Icons.redeem_outlined,
                    title: 'Referral Code',
                    subtitle: 'View and manage your referral code',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.referralCode),
                  ),
                  _HunterTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'View alerts and activity',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                  ),
                  _HunterTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Account preferences',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                  _HunterTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Help & Support',
                    subtitle: 'Get help with account and app issues',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.helpSupport),
                  ),
                  const SizedBox(height: 12),
                  const _HunterSectionLabel('Account'),
                  const SizedBox(height: 8),
                  _HunterTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    iconColor: AppColors.textMuted,
                    titleColor: AppColors.textSecondary,
                    onTap: widget.onSignOut,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SentimentSummary {
  const _SentimentSummary({
    required this.label,
    required this.footnote,
  });

  final String label;
  final String footnote;
}

_SentimentSummary _resolveSentiment({
  required int highCount,
  required int lowCount,
  required int total,
}) {
  if (total == 0) {
    return const _SentimentSummary(
      label: 'Neutral',
      footnote: 'No reviews yet',
    );
  }

  final net = highCount - lowCount;
  if (net > 0) {
    return _SentimentSummary(
      label: 'Positive',
      footnote: '$highCount high-priority calls',
    );
  }

  if (net < 0) {
    return _SentimentSummary(
      label: 'Cautious',
      footnote: '$lowCount low-priority calls',
    );
  }

  return _SentimentSummary(
    label: 'Balanced',
    footnote: '$total mixed signals',
  );
}

bool _isCurrentHunterUpdate({
  required Update update,
  required String userId,
  required String username,
}) {
  if (userId.isNotEmpty &&
      (update.adminId == userId || update.admin?.id == userId)) {
    return true;
  }

  final updateIdentity = update.admin?.username ?? update.admin?.name ?? '';
  final normalizedUpdate = _normalizeIdentity(updateIdentity);
  final normalizedCurrent = _normalizeIdentity(username);
  return normalizedCurrent.isNotEmpty && normalizedUpdate == normalizedCurrent;
}

bool _isCurrentHunterProject({
  required Project project,
  required String userId,
  required String username,
}) {
  if (userId.isNotEmpty &&
      (project.adminId == userId || project.admin?.id == userId)) {
    return true;
  }

  final projectIdentity = project.admin?.username ?? project.admin?.name ?? '';
  final normalizedProject = _normalizeIdentity(projectIdentity);
  final normalizedCurrent = _normalizeIdentity(username);
  return normalizedCurrent.isNotEmpty && normalizedProject == normalizedCurrent;
}

String _normalizeIdentity(String value) {
  return value.replaceAll('@', '').trim().toLowerCase();
}

int _resolveFollowerCount({
  required List<Project> projects,
  required List<Update> updates,
}) {
  final projectFollowers = projects.fold<int>(
    0,
    (sum, project) => sum + project.followersCount,
  );
  final directFollowers = updates.fold<int>(
    0,
    (maxFollowers, update) {
      final followers = update.admin?.followers ?? 0;
      if (followers > maxFollowers) {
        return followers;
      }
      return maxFollowers;
    },
  );

  return directFollowers > projectFollowers
      ? directFollowers
      : projectFollowers;
}

double? _medianHoursBetweenUpdates(List<Update> updates) {
  if (updates.length < 2) return null;

  final sorted = List<Update>.from(updates)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final intervals = <double>[];

  for (var i = 0; i < sorted.length - 1; i += 1) {
    final hours =
        sorted[i].createdAt.difference(sorted[i + 1].createdAt).inMinutes / 60;
    if (hours >= 0) {
      intervals.add(hours);
    }
  }

  if (intervals.isEmpty) return null;
  intervals.sort((a, b) => a.compareTo(b));
  if (intervals.length % 2 == 1) {
    return intervals[intervals.length ~/ 2];
  }

  final right = intervals.length ~/ 2;
  return (intervals[right - 1] + intervals[right]) / 2;
}
