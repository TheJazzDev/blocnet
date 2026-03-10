import 'package:blocnet/features/moderation/data/models/profile_summary.dart';

enum CommunityReportStatus {
  pending,
  underReview,
  approved,
  rejected,
}

enum CommunityReportTargetType {
  post,
  comment,
  user,
}

class CommunityReport {
  final String id;
  final String reporterId;
  final CommunityReportTargetType targetType;
  final String targetId;
  final String? targetUserId;
  final String category;
  final String? details;
  final CommunityReportStatus status;
  final String? reviewedById;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects (optional, populated when included)
  final ProfileSummary? reporter;
  final ProfileSummary? targetUser;
  final ProfileSummary? reviewedBy;

  const CommunityReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    this.targetUserId,
    required this.category,
    this.details,
    required this.status,
    this.reviewedById,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
    required this.updatedAt,
    this.reporter,
    this.targetUser,
    this.reviewedBy,
  });

  factory CommunityReport.fromApi(Map<String, dynamic> json) {
    return CommunityReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      targetType: _parseTargetType(json['targetType']?.toString()),
      targetId: json['targetId'] as String,
      targetUserId: json['targetUserId'] as String?,
      category: json['category'] as String,
      details: json['details'] as String?,
      status: _parseStatus(json['status']?.toString()),
      reviewedById: json['reviewedById'] as String?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      reviewNotes: json['reviewNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      reporter: json['reporter'] != null ? ProfileSummary.fromApi(json['reporter'] as Map<String, dynamic>) : null,
      targetUser: json['targetUser'] != null ? ProfileSummary.fromApi(json['targetUser'] as Map<String, dynamic>) : null,
      reviewedBy: json['reviewedBy'] != null ? ProfileSummary.fromApi(json['reviewedBy'] as Map<String, dynamic>) : null,
    );
  }

  static CommunityReportStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'under_review':
        return CommunityReportStatus.underReview;
      case 'approved':
        return CommunityReportStatus.approved;
      case 'rejected':
        return CommunityReportStatus.rejected;
      default:
        return CommunityReportStatus.pending;
    }
  }

  static CommunityReportTargetType _parseTargetType(String? value) {
    switch (value?.toLowerCase()) {
      case 'comment':
        return CommunityReportTargetType.comment;
      case 'user':
        return CommunityReportTargetType.user;
      default:
        return CommunityReportTargetType.post;
    }
  }

  String get statusLabel {
    switch (status) {
      case CommunityReportStatus.pending:
        return 'Pending';
      case CommunityReportStatus.underReview:
        return 'Under Review';
      case CommunityReportStatus.approved:
        return 'Approved';
      case CommunityReportStatus.rejected:
        return 'Rejected';
    }
  }

  String get targetTypeLabel {
    switch (targetType) {
      case CommunityReportTargetType.post:
        return 'Post';
      case CommunityReportTargetType.comment:
        return 'Comment';
      case CommunityReportTargetType.user:
        return 'User';
    }
  }
}
