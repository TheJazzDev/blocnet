import 'dart:math';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../shared/update_project_logo.dart';
import '../shared/update_project_title.dart';

class UpdateDetailsInfo extends StatelessWidget {
  const UpdateDetailsInfo({required this.post, super.key});

  final Update post;

  @override
  Widget build(BuildContext context) {
    final readMinutes = _estimateReadMinutes(post.content);
    final projectId = post.project?.id ?? post.projectId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project logo + name
        GestureDetector(
          onTap: () => _openProjectDetails(context, projectId),
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UpdateProjectLogo(logoUrl: post.project?.logo ?? '', size: 44),
              const SizedBox(width: 12),
              Flexible(
                child: UpdateProjectTitle(
                  projectTitle: post.project?.name ?? '',
                  margin: false,
                  applyOverflow: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Title
        Text(
          post.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        // Meta row
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaChip(
              icon: Symbols.person,
              label: post.admin?.name ?? 'Unknown',
              badge: post.admin?.primaryBadge,
              roleLabel: post.admin?.displayRoleLabel,
              onTap: () => _openAuthorProfile(context),
            ),
            _dot(),
            _MetaChip(
              icon: Symbols.calendar_today,
              label: formatDateWithSuffix(post.createdAt),
            ),
            _dot(),
            _MetaChip(
              icon: Symbols.schedule,
              label: '$readMinutes min read',
            ),
            if (post.lastEditedAt != null) ...[
              _dot(),
              _MetaChip(
                icon: Symbols.edit,
                label: 'Edited ${formatDateWithSuffix(post.lastEditedAt!)}',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textFaint,
      ),
    );
  }

  int _estimateReadMinutes(String content) {
    final words =
        content.trim().split(RegExp(r'\s+')).where((v) => v.isNotEmpty).length;
    if (words == 0) return 1;
    return max(1, (words / 220).ceil());
  }

  void _openProjectDetails(BuildContext context, String projectId) {
    if (projectId.trim().isEmpty) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectDetailsDialog(projectId: projectId);
      },
      transitionDuration: const Duration(milliseconds: 320),
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

  void _openAuthorProfile(BuildContext context) {
    final author = post.admin;
    if (author == null) return;
    PublicProfileScreen.showSheet(context, author);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.badge,
    this.roleLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final dynamic badge;
  final String? roleLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textFaint),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w400,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 4),
            BadgeIcon(
              badge: badge,
              size: BadgeSize.tiny,
            ),
          ],
          if (roleLabel != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (roleLabel == 'HUNTER'
                          ? const Color(0xFFC084FC)
                          : AppColors.primary400)
                      .withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: Text(
                roleLabel!,
                style: TextStyle(
                  color: roleLabel == 'HUNTER'
                      ? const Color(0xFFC084FC)
                      : AppColors.primary400,
                  fontSize: 9,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
