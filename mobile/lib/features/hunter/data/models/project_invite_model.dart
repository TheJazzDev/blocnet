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
    this.kind = kindCoOwn,
    this.note,
    this.reviewedAt,
  });

  /// Backend `ProjectInviteKind`.
  static const String kindCoOwn = 'co_own';
  static const String kindHandover = 'handover';

  final String id;
  final String projectId;
  final String projectName;
  final String projectSlug;

  /// `co_own`: join the gem's owners. `handover`: the inviting hunter's
  /// ownership becomes the invited hunter's on accept.
  final String kind;

  /// `pending` | `accepted` | `rejected` | `cancelled` (backend
  /// `InviteStatus`).
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isHandover => kind == kindHandover;

  factory ProjectInviteModel.fromApi(Map<String, dynamic> json) {
    final project = json['project'];
    final projectMap = project is Map
        ? project.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final note = json['note']?.toString().trim();

    return ProjectInviteModel(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? projectMap['id'] ?? '').toString(),
      projectName: (projectMap['name'] ?? 'Untitled Gem').toString(),
      projectSlug: (projectMap['slug'] ?? '').toString(),
      kind: _parseKind(json['kind']),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      note: note == null || note.isEmpty ? null : note,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
    );
  }

  /// Unknown or missing kinds read as co-own, the only kind older backends
  /// send.
  static String _parseKind(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return value == kindHandover ? kindHandover : kindCoOwn;
  }

  ProjectInviteModel copyWith({String? status, DateTime? reviewedAt}) {
    return ProjectInviteModel(
      id: id,
      projectId: projectId,
      projectName: projectName,
      projectSlug: projectSlug,
      kind: kind,
      status: status ?? this.status,
      note: note,
      createdAt: createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
