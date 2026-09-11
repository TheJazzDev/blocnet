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

  bool get isPending => status == 'pending';

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
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      note: note == null || note.isEmpty ? null : note,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
    );
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
    );
  }
}
