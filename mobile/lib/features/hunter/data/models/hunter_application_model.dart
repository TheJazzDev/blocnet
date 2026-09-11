/// A role application row from `POST /admin-applications`
/// (backend `AdminApplication`, `targetRole: 'hunter'`).
class HunterApplicationModel {
  const HunterApplicationModel({
    required this.id,
    required this.targetRole,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String targetRole;

  /// `pending` | `approved` | `rejected` (backend `ApplicationStatus`).
  final String status;
  final String reason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory HunterApplicationModel.fromApi(Map<String, dynamic> json) {
    return HunterApplicationModel(
      id: (json['id'] ?? '').toString(),
      targetRole: (json['targetRole'] ?? 'hunter').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
    );
  }
}
