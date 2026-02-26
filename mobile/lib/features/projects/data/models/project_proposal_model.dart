class ProjectProposalModel {
  ProjectProposalModel({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.symbol,
    this.websiteUrl,
    this.reason,
    this.reviewNote,
    this.reviewerId,
    this.reviewedAt,
    this.createdProjectId,
  });

  final String id;
  final String name;
  final String status;
  final DateTime createdAt;
  final String? symbol;
  final String? websiteUrl;
  final String? reason;
  final String? reviewNote;
  final String? reviewerId;
  final DateTime? reviewedAt;
  final String? createdProjectId;

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  String get statusLabel {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  factory ProjectProposalModel.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    final reviewedAtRaw = json['reviewedAt']?.toString();

    return ProjectProposalModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Proposal',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now(),
      symbol: json['symbol']?.toString(),
      websiteUrl: json['websiteUrl']?.toString(),
      reason: json['reason']?.toString(),
      reviewNote: json['reviewNote']?.toString(),
      reviewerId: json['reviewerId']?.toString(),
      reviewedAt: DateTime.tryParse(reviewedAtRaw ?? ''),
      createdProjectId: json['createdProjectId']?.toString(),
    );
  }
}
