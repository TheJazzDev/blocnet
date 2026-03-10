import 'package:blocnet/features/moderation/data/models/community_report_model.dart';
import 'package:blocnet/features/moderation/data/models/profile_summary.dart';

enum CommunityAppealStatus {
  pending,
  underReview,
  approved,
  rejected,
}

enum CommunityAppealDecision {
  overturn,
  uphold,
  partial,
}

class CommunityAppeal {
  final String id;
  final String reportId;
  final String appealerId;
  final String reason;
  final CommunityAppealStatus status;
  final String? reviewedById;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final CommunityAppealDecision? decision;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects (optional, populated when included)
  final CommunityReport? report;
  final ProfileSummary? appealer;
  final ProfileSummary? reviewedBy;

  const CommunityAppeal({
    required this.id,
    required this.reportId,
    required this.appealerId,
    required this.reason,
    required this.status,
    this.reviewedById,
    this.reviewedAt,
    this.reviewNotes,
    this.decision,
    required this.createdAt,
    required this.updatedAt,
    this.report,
    this.appealer,
    this.reviewedBy,
  });

  factory CommunityAppeal.fromApi(Map<String, dynamic> json) {
    return CommunityAppeal(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      appealerId: json['appealerId'] as String,
      reason: json['reason'] as String,
      status: _parseStatus(json['status']?.toString()),
      reviewedById: json['reviewedById'] as String?,
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      reviewNotes: json['reviewNotes'] as String?,
      decision: json['decision'] != null ? _parseDecision(json['decision']?.toString()) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      report: json['report'] != null ? CommunityReport.fromApi(json['report'] as Map<String, dynamic>) : null,
      appealer: json['appealer'] != null ? ProfileSummary.fromApi(json['appealer'] as Map<String, dynamic>) : null,
      reviewedBy: json['reviewedBy'] != null ? ProfileSummary.fromApi(json['reviewedBy'] as Map<String, dynamic>) : null,
    );
  }

  static CommunityAppealStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'under_review':
        return CommunityAppealStatus.underReview;
      case 'approved':
        return CommunityAppealStatus.approved;
      case 'rejected':
        return CommunityAppealStatus.rejected;
      default:
        return CommunityAppealStatus.pending;
    }
  }

  static CommunityAppealDecision? _parseDecision(String? value) {
    switch (value?.toLowerCase()) {
      case 'overturn':
        return CommunityAppealDecision.overturn;
      case 'uphold':
        return CommunityAppealDecision.uphold;
      case 'partial':
        return CommunityAppealDecision.partial;
      default:
        return null;
    }
  }

  String get statusLabel {
    switch (status) {
      case CommunityAppealStatus.pending:
        return 'Pending';
      case CommunityAppealStatus.underReview:
        return 'Under Review';
      case CommunityAppealStatus.approved:
        return 'Approved';
      case CommunityAppealStatus.rejected:
        return 'Rejected';
    }
  }

  String? get decisionLabel {
    if (decision == null) return null;
    switch (decision!) {
      case CommunityAppealDecision.overturn:
        return 'Overturned';
      case CommunityAppealDecision.uphold:
        return 'Upheld';
      case CommunityAppealDecision.partial:
        return 'Partial';
    }
  }
}
