import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

/// A single feed card showing a hunter update in the home screen.
class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.post});

  final Update post;

  void _openDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      pageBuilder: (context, _, __) => UpdateDetailsDialog(id: post.id),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
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

  @override
  Widget build(BuildContext context) {
    final author = post.admin!;
    final project = post.project!;
    final priorityColor = post.priority.color;
    final roleLabel = author.displayRoleLabel;
    final roleColor =
        roleLabel == 'HUNTER' ? const Color(0xFFC084FC) : AppColors.primary400;
    final previewText = post.description.trim().isEmpty
        ? post.content.trim()
        : post.description.trim();

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Stack(
        children: [
          // Subtle glow effect on left side based on priority
          Positioned(
            left: -20,
            top: 20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    priorityColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main card content
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgSurface,
                  AppColors.bgSurface.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: priorityColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: avatar + author + timestamp + priority pill ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _openAuthorProfile(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              priorityColor.withValues(alpha: 0.3),
                              priorityColor.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.bgElevated,
                          backgroundImage: author.imageUrl.isNotEmpty
                              ? NetworkImage(author.imageUrl)
                              : null,
                          child: author.imageUrl.isEmpty
                              ? Icon(Icons.person,
                                  size: 18, color: AppColors.textMuted)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => _openAuthorProfile(context),
                                  behavior: HitTestBehavior.opaque,
                                  child: Text(
                                    author.name,
                                    style: AppTypography.custom(
                                      color: AppColors.textPrimary,
                                      size: 14,
                                      weight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (author.primaryBadge != null) ...[
                                const SizedBox(width: 6),
                                BadgeIcon(
                                  badge: author.primaryBadge!,
                                  size: BadgeSize.small,
                                  showTooltip: false,
                                ),
                              ],
                              if (roleLabel != null) ...[
                                const SizedBox(width: 6),
                                _FeedRoleChip(
                                  label: roleLabel,
                                  color: roleColor,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            getTimeStamp(post.createdAt),
                            style: AppTypography.custom(
                              color: AppColors.textFaint,
                              size: 11,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            post.priority.label.toUpperCase(),
                            style: AppTypography.custom(
                              color: priorityColor,
                              size: 9,
                              weight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Project chip with gradient ──
                _ModernProjectChip(project: project),

                const SizedBox(height: 12),

                // ── Secondary tags ──
                if (post.secondaryTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.secondaryTags.take(3).map((tag) {
                      return _TagPill(label: tag.name);
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Update text ──
                Text(
                  previewText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 13,
                    weight: FontWeight.w400,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Action row: like · comment · share | bookmark ──
                const _ActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedRoleChip extends StatelessWidget {
  const _FeedRoleChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.8),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern project chip with gradient and enhanced visuals
// ─────────────────────────────────────────────────────────────────────────────

class _ModernProjectChip extends StatelessWidget {
  const _ModernProjectChip({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated.withValues(alpha: 0.9),
            AppColors.bgElevated.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary500.withValues(alpha: 0.25),
                  AppColors.primary500.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: project.logo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      project.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.layers_outlined,
                        size: 16,
                        color: AppColors.primary400,
                      ),
                    ),
                  )
                : Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: AppColors.primary400,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 10,
                      color: AppColors.textFaint,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.primaryTag.name,
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: AppColors.textFaint,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag pill
// ─────────────────────────────────────────────────────────────────────────────

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  Color _colorForLabel(String lbl) {
    final lower = lbl.toLowerCase();
    if (lower.contains('alpha') || lower.contains('launch')) {
      return AppColors.tagAlpha;
    }
    if (lower.contains('partner')) {
      return AppColors.tagPartnership;
    }
    if (lower.contains('warning') || lower.contains('rug')) {
      return AppColors.tagWarning;
    }
    if (lower.contains('airdrop')) {
      return AppColors.tagAirdrop;
    }
    return AppColors.tagGeneral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern action row with subtle backgrounds
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.favorite_border_rounded,
          label: null,
          color: AppColors.error500,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: null,
          color: AppColors.primary400,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.share_outlined,
          label: null,
          color: AppColors.teal400,
          onTap: () {},
        ),
        const Spacer(),
        _ActionButton(
          icon: Icons.bookmark_border_rounded,
          label: null,
          color: AppColors.textMuted,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.label,
  });

  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: AppTypography.custom(
                  color: color,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
