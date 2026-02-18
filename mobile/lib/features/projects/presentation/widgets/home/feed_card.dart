import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    final author = post.admin!;
    final project = post.project!;
    final previewText = post.description.trim().isEmpty
        ? post.content.trim()
        : post.description.trim();

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + author + timestamp + more ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.bgElevated,
                  backgroundImage: author.imageUrl.isNotEmpty
                      ? NetworkImage(author.imageUrl)
                      : null,
                  child: author.imageUrl.isEmpty
                      ? Icon(Icons.person, size: 16, color: AppColors.textMuted)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        getTimeStamp(post.createdAt),
                        style: GoogleFonts.inter(
                          color: AppColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textFaint,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Project chip ──
            _ProjectChip(project: project),

            const SizedBox(height: 10),

            // ── Secondary tags ──
            if (post.secondaryTags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.secondaryTags.take(3).map((tag) {
                  return _TagPill(label: tag.name);
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // ── Update text ──
            Text(
              previewText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // ── Action row: like · comment · share | bookmark ──
            const _ActionRow(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Project chip — shows project icon, name, and primary tag
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: project.logo.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      project.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: AppColors.primary400,
                      ),
                    ),
                  )
                : Icon(
                    Icons.layers_outlined,
                    size: 14,
                    color: AppColors.primary400,
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  project.primaryTag.name,
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row — like · comment · share | bookmark
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
          onTap: () {},
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: null,
          onTap: () {},
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.share_outlined,
          label: null,
          onTap: () {},
        ),
        const Spacer(),
        _ActionButton(
          icon: Icons.bookmark_border_rounded,
          label: null,
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
    this.label,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textFaint),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: GoogleFonts.inter(
                color: AppColors.textFaint,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
