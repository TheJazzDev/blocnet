/// A hunter invite from `GET /project-invites/mine`
/// (backend `ProjectHunterInvite` with its `project` summary).
class ProjectInviteModel {
  const ProjectInviteModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectSlug,
    required this.status,
    required this.createdAt,
    this.note,
    this.reviewedAt,
    this.primaryTag,
    this.followersCount,
    this.updatesCount,
    this.lastUpdateAt,
    this.inviterUsername,
    this.inviterDisplayName,
  });

  final String id;
  final String projectId;
  final String projectName;
  final String projectSlug;

  /// `pending` | `accepted` | `rejected` | `cancelled` (backend
  /// `InviteStatus`).
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  /// The gem's chain, when the project summary carries it.
  final String? primaryTag;

  /// What the hunter would be taking on. Null on an older backend.
  final int? followersCount;
  final int? updatesCount;
  final DateTime? lastUpdateAt;

  /// Who sent the invite.
  final String? inviterUsername;
  final String? inviterDisplayName;

  bool get isPending => status == 'pending';

  factory ProjectInviteModel.fromApi(Map<String, dynamic> json) {
    final project = json['project'];
    final projectMap = project is Map
        ? project.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final note = json['note']?.toString().trim();
    final inviter = json['inviter'];
    final inviterMap = inviter is Map
        ? inviter.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};

    return ProjectInviteModel(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? projectMap['id'] ?? '').toString(),
      projectName: (projectMap['name'] ?? 'Untitled Gem').toString(),
      projectSlug: (projectMap['slug'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      note: note == null || note.isEmpty ? null : note,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      primaryTag: _tagName(projectMap['primaryTag']),
      followersCount: _intOrNull(projectMap['followersCount']),
      updatesCount: _intOrNull(projectMap['updatesCount']),
      lastUpdateAt:
          DateTime.tryParse(projectMap['lastUpdateAt']?.toString() ?? ''),
      inviterUsername: _textOrNull(inviterMap['username']),
      inviterDisplayName: _textOrNull(inviterMap['displayName']),
    );
  }

  static int? _intOrNull(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static String? _textOrNull(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  /// The tag arrives either as a name or as `{ name }`.
  static String? _tagName(Object? raw) {
    if (raw is Map) return _textOrNull(raw['name']);
    return _textOrNull(raw);
  }

  ProjectInviteModel copyWith({String? status, DateTime? reviewedAt}) {
    return ProjectInviteModel(
      id: id,
      projectId: projectId,
      projectName: projectName,
      projectSlug: projectSlug,
      status: status ?? this.status,
      note: note,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      primaryTag: primaryTag,
      followersCount: followersCount,
      updatesCount: updatesCount,
      lastUpdateAt: lastUpdateAt,
      inviterUsername: inviterUsername,
      inviterDisplayName: inviterDisplayName,
    );
  }
}
