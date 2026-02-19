import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    required this.admin,
    this.asSheet = false,
  });

  final Admin admin;
  final bool asSheet;

  static Future<void> showSheet(BuildContext context, Admin admin) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: PublicProfileScreen(admin: admin, asSheet: true),
      ),
    );
  }

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UsersApiRepository _usersRepository = UsersApiRepository();
  bool _isFollowing = false;
  bool _isSubmittingFollow = false;

  Future<void> _toggleFollow() async {
    if (_isSubmittingFollow) return;
    setState(() => _isSubmittingFollow = true);

    try {
      if (_isFollowing) {
        await _usersRepository.unfollowProfile(widget.admin.id);
      } else {
        await _usersRepository.followProfile(widget.admin.id);
      }
      if (!mounted) return;
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update follow status')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final username = admin.username.trim().isNotEmpty
        ? admin.username
        : '@${admin.name.toLowerCase().replaceAll(' ', '_')}';
    final role = _resolveRole(admin);

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: widget.asSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.zero,
      ),
      child: SafeArea(
        top: !widget.asSheet,
        child: Column(
          children: [
            if (widget.asSheet)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Public Profile',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<UpdatesStore>(
                builder: (context, updatesStore, _) {
                  final posts = updatesStore.posts
                      .where((p) => p.admin?.id == admin.id)
                      .toList();
                  final projectCount =
                      posts.map((post) => post.projectId).toSet().length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: AppColors.bgElevated,
                          backgroundImage: admin.imageUrl.isNotEmpty
                              ? NetworkImage(admin.imageUrl)
                              : null,
                          child: admin.imageUrl.isEmpty
                              ? Text(
                                  admin.name.isNotEmpty
                                      ? admin.name[0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.primary400,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          admin.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'HUNTER'
                                ? const Color(0xFFC084FC)
                                    .withValues(alpha: 0.15)
                                : AppColors.primary500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: role == 'HUNTER'
                                  ? const Color(0xFFC084FC)
                                      .withValues(alpha: 0.55)
                                  : AppColors.primary400
                                      .withValues(alpha: 0.55),
                            ),
                          ),
                          child: Text(
                            role,
                            style: GoogleFonts.inter(
                              color: role == 'HUNTER'
                                  ? const Color(0xFFC084FC)
                                  : AppColors.primary400,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StatCard(
                                value: '${admin.followers}',
                                label: 'Followers'),
                            const SizedBox(width: 8),
                            _StatCard(value: '${posts.length}', label: 'Posts'),
                            const SizedBox(width: 8),
                            _StatCard(
                                value: '$projectCount', label: 'Projects'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmittingFollow ? null : _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? AppColors.bgElevated
                                  : AppColors.primary500,
                              foregroundColor: _isFollowing
                                  ? AppColors.textPrimary
                                  : Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmittingFollow
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: _isFollowing
                                          ? AppColors.textPrimary
                                          : Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SectionLabel('Recent Activity'),
                        const SizedBox(height: 8),
                        if (posts.isEmpty)
                          _EmptyActivityCard()
                        else
                          ...posts.take(4).map(
                                (post) => _ActivityCard(
                                  title: post.title,
                                  subtitle: post.project?.name ?? 'Project',
                                  time: getTimeStamp(post.createdAt),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.asSheet) return content;
    return Scaffold(backgroundColor: AppColors.bgBase, body: content);
  }

  String _resolveRole(Admin admin) {
    final raw = '${admin.username} ${admin.name}'.toLowerCase();
    if (raw.contains('hunter')) return 'HUNTER';
    if (raw.contains('admin')) return 'ADMIN';
    return 'USER';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.textFaint,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'No public posts available yet.',
        style: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}
