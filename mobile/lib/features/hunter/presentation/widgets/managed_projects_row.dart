import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

/// Horizontal scrollable row of the hunter's managed project cards.
class ManagedProjectsRow extends StatelessWidget {
  const ManagedProjectsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final projects = context.watch<ProjectsStore>().projects;
    final userId = auth.userId ?? '';
    final username = auth.username ?? auth.displayName ?? '';
    final managed = projects
        .where(
          (project) => _isCurrentHunterProject(
            project: project,
            userId: userId,
            username: username,
          ),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (managed.isEmpty) {
      return _EmptyManagedProjects();
    }

    final visibleProjects = managed.take(5).toList(growable: false);

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleProjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) =>
            _ManagedProjectCard(project: visibleProjects[i]),
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
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 13,
              weight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ticker.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '\$$ticker',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 10,
                weight: FontWeight.w500,
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
    final normalized = project.status.trim().toLowerCase();
    switch (normalized) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'hidden':
        return 'Hidden';
      case 'archived':
        return 'Archived';
      default:
        return 'Active';
    }
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
          style: AppTypography.custom(
            color: AppColors.primary400,
            size: 13,
            weight: FontWeight.w700,
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
    final color = switch (status) {
      'Active' => AppColors.successColor,
      'Paused' => AppColors.warning500,
      'Hidden' => AppColors.textMuted,
      'Archived' => AppColors.textMuted,
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: AppTypography.custom(
          color: color,
          size: 9,
          weight: FontWeight.w600,
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
    final label = switch (status) {
      'Active' => 'Manage',
      'Paused' => 'Review',
      'Hidden' => 'View',
      'Archived' => 'View',
      _ => 'Manage',
    };
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageProjects),
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
            style: AppTypography.custom(
              color: AppColors.primary400,
              size: 11,
              weight: FontWeight.w600,
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
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 13,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submit a gem to start managing projects',
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 11,
              weight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
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

  final projectUsername = project.admin?.username ?? project.admin?.name ?? '';
  return _normalizeIdentity(projectUsername) == _normalizeIdentity(username) &&
      _normalizeIdentity(username).isNotEmpty;
}

String _normalizeIdentity(String value) {
  return value.replaceAll('@', '').trim().toLowerCase();
}
