import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable row of the hunter's managed project cards.
class ManagedProjectsRow extends StatelessWidget {
  const ManagedProjectsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = context.watch<ProjectsStore>().projects;

    if (projects.isEmpty) {
      return _EmptyManagedProjects();
    }

    // Show up to 5 managed projects
    final managed = projects.take(5).toList();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: managed.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _ManagedProjectCard(project: managed[i]),
      ),
    );
  }
}

class _ManagedProjectCard extends StatelessWidget {
  const _ManagedProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final name = project.name.trim().isNotEmpty ? project.name : 'Unnamed';
    final ticker = _deriveTicker(name);
    final status = _resolveStatus(project);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProjectIcon(name: name),
              const Spacer(),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ticker.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '\$$ticker',
              style: GoogleFonts.inter(
                color: AppColors.primary400,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          _ActionButton(status: status),
        ],
      ),
    );
  }

  String _deriveTicker(String name) {
    final words = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    // Prefer acronym for multi-word names, otherwise first 4 letters.
    if (words.length > 1) {
      final acronym = words.map((w) => w[0]).join().toUpperCase();
      return acronym.length > 5 ? acronym.substring(0, 5) : acronym;
    }

    final compact = words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (compact.isEmpty) return '';
    return compact.toUpperCase().substring(0, compact.length.clamp(0, 4));
  }

  String _resolveStatus(Project project) {
    // Derive status from available model fields only.
    final hasUpdates = (project.posts?.isNotEmpty ?? false);
    if (hasUpdates) return 'Live';
    if (project.followersCount > 0) return 'Pending';
    return 'Processing';
  }
}

class _ProjectIcon extends StatelessWidget {
  const _ProjectIcon({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.primary400,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Live':
        color = AppColors.successColor;
      case 'Pending':
        color = AppColors.warning500;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status == 'Live' ? 'Post Update' : 'View';
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary500.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary500.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.primary400,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyManagedProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined,
              size: 28, color: AppColors.textFaint),
          const SizedBox(height: 8),
          Text(
            'No projects yet',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submit a gem to start managing projects',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textFaint,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
