import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable row of top hunters (admin avatars) at the top of the feed.
class TopHuntersRow extends StatelessWidget {
  const TopHuntersRow({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<UpdatesStore>().posts;

    // Collect unique admins from posts (in order of appearance)
    final seen = <String>{};
    final admins = <Admin>[];
    for (final post in posts) {
      final admin = post.admin;
      if (admin != null && seen.add(admin.id)) {
        admins.add(admin);
        if (admins.length >= 8) break;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOP HUNTERS',
                style: GoogleFonts.inter(
                  color: AppColors.textFaint,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                'View All',
                style: GoogleFonts.inter(
                  color: AppColors.teal400,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "My Updates" — create button
                const _HunterAvatar.create(),
                const SizedBox(width: 16),
                // Real hunters
                ...admins.map((admin) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: _HunterAvatar(
                        imageUrl: admin.imageUrl,
                        name: admin.name,
                        hasRing: true,
                        onTap: () =>
                            PublicProfileScreen.showSheet(context, admin),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HunterAvatar extends StatelessWidget {
  const _HunterAvatar({
    required this.imageUrl,
    required this.name,
    this.hasRing = false,
    this.onTap,
  }) : isCreate = false;

  const _HunterAvatar.create()
      : imageUrl = '',
        name = 'My Updates',
        hasRing = false,
        isCreate = true,
        onTap = null;

  final String imageUrl;
  final String name;
  final bool hasRing;
  final bool isCreate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            if (isCreate)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderMuted,
                    width: 1.5,
                  ),
                  color: AppColors.bgElevated,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.teal400,
                  size: 20,
                ),
              )
            else if (hasRing)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal400, AppColors.primary500],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgBase,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: _buildAvatarCircle(),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderMuted, width: 1),
                ),
                padding: const EdgeInsets.all(2),
                child: _buildAvatarCircle(),
              ),
            const SizedBox(height: 5),
            Text(
              isCreate ? 'My Updates' : name,
              style: GoogleFonts.inter(
                color: isCreate ? AppColors.teal400 : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    return CircleAvatar(
      backgroundColor: AppColors.bgElevated,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Icon(Icons.person, size: 16, color: AppColors.textMuted)
          : null,
    );
  }
}
