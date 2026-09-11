import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';

/// Display-only aggregates derived from the projects and updates the
/// current user hunts. Pure functions so the hunter sections stay thin.
class HunterProfileMetrics {
  const HunterProfileMetrics({
    required this.managedProjects,
    required this.hunterUpdates,
    required this.successRate,
    required this.sentiment,
    required this.updatesLast7d,
    required this.updatesLast30d,
    required this.highUrgencyShare30d,
    required this.medianHoursBetweenUpdates,
    required this.lastActiveAt,
    required this.followerCount,
  });

  final List<Project> managedProjects;

  /// Newest first.
  final List<Update> hunterUpdates;
  final int successRate;
  final HunterSentiment sentiment;
  final int updatesLast7d;
  final int updatesLast30d;
  final double highUrgencyShare30d;
  final double? medianHoursBetweenUpdates;
  final DateTime? lastActiveAt;
  final int followerCount;

  static HunterProfileMetrics compute({
    required List<Project> projects,
    required List<Update> updates,
    required String userId,
    required String username,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final managedProjects = projects
        .where((p) => isCurrentHunterProject(
              project: p,
              userId: userId,
              username: username,
            ))
        .toList();
    final hunterUpdates = updates
        .where((u) => isCurrentHunterUpdate(
              update: u,
              userId: userId,
              username: username,
            ))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    String label(Update u) => u.priority.label.toLowerCase();
    bool isHigh(Update u) => label(u) == 'high';
    bool isQuality(Update u) {
      final l = label(u);
      return l == 'high' || l == 'mid' || l == 'medium';
    }

    final highCount = hunterUpdates.where(isHigh).length;
    final lowCount = hunterUpdates.where((u) => label(u) == 'low').length;
    final qualityCount = hunterUpdates.where(isQuality).length;
    final successRate = hunterUpdates.isEmpty
        ? 0
        : ((qualityCount / hunterUpdates.length) * 100).round();

    final last7d = hunterUpdates
        .where((u) => clock.difference(u.createdAt).inDays < 7)
        .length;
    final last30d = hunterUpdates
        .where((u) => clock.difference(u.createdAt).inDays < 30)
        .toList();
    final high30d = last30d.where(isHigh).length;
    final highShare30d =
        last30d.isEmpty ? 0.0 : (high30d / last30d.length) * 100;

    return HunterProfileMetrics(
      managedProjects: managedProjects,
      hunterUpdates: hunterUpdates,
      successRate: successRate,
      sentiment: HunterSentiment.resolve(
        highCount: highCount,
        lowCount: lowCount,
        total: hunterUpdates.length,
      ),
      updatesLast7d: last7d,
      updatesLast30d: last30d.length,
      highUrgencyShare30d: highShare30d,
      medianHoursBetweenUpdates: medianHoursBetween(hunterUpdates),
      lastActiveAt:
          hunterUpdates.isEmpty ? null : hunterUpdates.first.createdAt,
      followerCount: resolveFollowerCount(
        projects: managedProjects,
        updates: hunterUpdates,
      ),
    );
  }

  static bool isCurrentHunterUpdate({
    required Update update,
    required String userId,
    required String username,
  }) {
    if (userId.isNotEmpty &&
        (update.adminId == userId || update.admin?.id == userId)) {
      return true;
    }
    final identity = update.admin?.username ?? update.admin?.name ?? '';
    final normalizedCurrent = _normalizeIdentity(username);
    return normalizedCurrent.isNotEmpty &&
        _normalizeIdentity(identity) == normalizedCurrent;
  }

  static bool isCurrentHunterProject({
    required Project project,
    required String userId,
    required String username,
  }) {
    if (userId.isNotEmpty &&
        (project.adminId == userId || project.admin?.id == userId)) {
      return true;
    }
    final identity = project.admin?.username ?? project.admin?.name ?? '';
    final normalizedCurrent = _normalizeIdentity(username);
    return normalizedCurrent.isNotEmpty &&
        _normalizeIdentity(identity) == normalizedCurrent;
  }

  static int resolveFollowerCount({
    required List<Project> projects,
    required List<Update> updates,
  }) {
    final projectFollowers =
        projects.fold<int>(0, (sum, p) => sum + p.followersCount);
    final directFollowers = updates.fold<int>(0, (max, u) {
      final followers = u.admin?.followers ?? 0;
      return followers > max ? followers : max;
    });
    return directFollowers > projectFollowers
        ? directFollowers
        : projectFollowers;
  }

  /// Median gap in hours between consecutive updates, newest first.
  static double? medianHoursBetween(List<Update> updates) {
    if (updates.length < 2) return null;
    final sorted = List<Update>.from(updates)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final intervals = <double>[];
    for (var i = 0; i < sorted.length - 1; i += 1) {
      final hours =
          sorted[i].createdAt.difference(sorted[i + 1].createdAt).inMinutes /
              60;
      if (hours >= 0) intervals.add(hours);
    }
    if (intervals.isEmpty) return null;
    intervals.sort();
    final mid = intervals.length ~/ 2;
    if (intervals.length.isOdd) return intervals[mid];
    return (intervals[mid - 1] + intervals[mid]) / 2;
  }

  static String compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  static String _normalizeIdentity(String value) =>
      value.replaceAll('@', '').trim().toLowerCase();
}

class HunterSentiment {
  const HunterSentiment({required this.label, required this.footnote});

  final String label;
  final String footnote;

  static HunterSentiment resolve({
    required int highCount,
    required int lowCount,
    required int total,
  }) {
    if (total == 0) {
      return const HunterSentiment(label: 'Neutral', footnote: 'No reviews yet');
    }
    final net = highCount - lowCount;
    if (net > 0) {
      return HunterSentiment(
        label: 'Positive',
        footnote: '$highCount high-priority calls',
      );
    }
    if (net < 0) {
      return HunterSentiment(
        label: 'Cautious',
        footnote: '$lowCount low-priority calls',
      );
    }
    return HunterSentiment(label: 'Balanced', footnote: '$total mixed signals');
  }
}
