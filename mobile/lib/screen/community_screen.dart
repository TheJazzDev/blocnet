import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProjectsStore>().fetchProjectsOnce();
      context.read<UpdatesStore>().fetchUpdatesOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.communityCreatePost),
        backgroundColor: AppColors.primary500,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: Consumer<UpdatesStore>(
        builder: (context, store, _) {
          final posts = store.posts
              .where((post) => post.project != null && post.admin != null)
              .toList();

          if (posts.isEmpty) {
            return const Center(
              child: Text('No community updates yet.'),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const _CommunityTabs(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _CommunityFeedList(
                        posts: _filterPosts(posts, _CommunityTab.general),
                        bottomPad: bottomPad,
                      ),
                      _CommunityFeedList(
                        posts: _filterPosts(posts, _CommunityTab.marketTalk),
                        bottomPad: bottomPad,
                      ),
                      _CommunityFeedList(
                        posts: _filterPosts(posts, _CommunityTab.introductions),
                        bottomPad: bottomPad,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Update> _filterPosts(List<Update> posts, _CommunityTab tab) {
    switch (tab) {
      case _CommunityTab.general:
        return posts;
      case _CommunityTab.marketTalk:
        return posts.where((post) {
          final text =
              '${post.title} ${post.content} ${post.description}'.toLowerCase();
          return text.contains('market') ||
              text.contains('price') ||
              text.contains('token') ||
              text.contains('chart') ||
              text.contains('trend');
        }).toList();
      case _CommunityTab.introductions:
        return posts.where((post) {
          final text =
              '${post.title} ${post.content} ${post.description}'.toLowerCase();
          return text.contains('introduce') ||
              text.contains('hello') ||
              text.contains('new here') ||
              text.contains('welcome');
        }).toList();
    }
  }
}

enum _CommunityTab { general, marketTalk, introductions }

class _CommunityTabs extends StatelessWidget {
  const _CommunityTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: TabBar(
        labelColor: AppColors.primary400,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary400,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'General'),
          Tab(text: 'Market Talk'),
          Tab(text: 'Introductions'),
        ],
      ),
    );
  }
}

class _CommunityFeedList extends StatelessWidget {
  const _CommunityFeedList({
    required this.posts,
    required this.bottomPad,
  });

  final List<Update> posts;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'No posts in this section yet.',
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _CommunityCard(
        post: posts[index],
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.communityDiscussion,
          arguments: posts[index].id,
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.post,
    required this.onTap,
  });

  final Update post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final admin = post.admin;
    final displayName =
        admin?.name.trim().isNotEmpty == true ? admin!.name : 'Blocnet User';
    final role = _resolveRole(post);
    final roleColor =
        role == 'ADMIN' ? AppColors.primary400 : const Color(0xFFC084FC);
    final content = post.content.trim().isNotEmpty
        ? post.content.trim()
        : post.description.trim();
    final likes = 20 + (post.title.length * 3) % 180;
    final comments = 3 + (post.description.length % 40);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(adminName: displayName, imageUrl: admin?.imageUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _RoleChip(label: role, color: roleColor),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        content,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 11),
            Row(
              children: [
                Icon(Icons.thumb_up_alt_rounded,
                    size: 20, color: AppColors.primary400),
                const SizedBox(width: 7),
                Text(
                  '$likes',
                  style: GoogleFonts.inter(
                    color: AppColors.primary400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 18),
                Icon(Icons.mode_comment_outlined,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 7),
                Text(
                  '$comments',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.share_outlined,
                    size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _resolveRole(Update post) {
    final raw = (post.admin?.username ?? post.admin?.name ?? '').toLowerCase();
    if (raw.contains('hunter')) return 'HUNTER';
    return 'ADMIN';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.adminName, required this.imageUrl});

  final String adminName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasNetworkImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.bgElevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasNetworkImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    final firstChar = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'B';
    return Center(
      child: Text(
        firstChar,
        style: GoogleFonts.inter(
          color: AppColors.primary400,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.9), width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
