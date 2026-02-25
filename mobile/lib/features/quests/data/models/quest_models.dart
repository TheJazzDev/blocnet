import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:flutter/material.dart';

Map<String, dynamic> _asStringKeyMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

class QuestModel {
  const QuestModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.rewardPoints,
    this.rewardBadgeId,
    this.targetUrl,
    this.targetAction,
    required this.verificationMethod,
    this.requiredProof,
    required this.isActive,
    required this.sortOrder,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final QuestType type;
  final BadgeCategory category;
  final int rewardPoints;
  final String? rewardBadgeId;
  final String? targetUrl;
  final String? targetAction;
  final String verificationMethod;
  final String? requiredProof;
  final bool isActive;
  final int sortOrder;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory QuestModel.fromApi(Map<String, dynamic> json) {
    final categoryRaw = json['category']?.toString().trim().toLowerCase() ?? '';
    return QuestModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: _questTypeFromApi(json['type']),
      category: BadgeCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == categoryRaw,
        orElse: () => BadgeCategory.engagement,
      ),
      rewardPoints: int.tryParse(json['rewardPoints']?.toString() ?? '') ?? 0,
      rewardBadgeId: json['rewardBadgeId']?.toString(),
      targetUrl: json['targetUrl']?.toString(),
      targetAction: json['targetAction']?.toString(),
      verificationMethod: json['verificationMethod']?.toString() ?? 'manual',
      requiredProof: json['requiredProof']?.toString(),
      isActive: json['isActive'] == true,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get requiresManualVerification => verificationMethod == 'manual';
  bool get isAutoVerified => verificationMethod == 'auto';
}

enum QuestType {
  externalLink,
  internalAction,
  socialMedia,
}

extension QuestTypeExtension on QuestType {
  String get displayName {
    switch (this) {
      case QuestType.externalLink:
        return 'External Link';
      case QuestType.internalAction:
        return 'Action';
      case QuestType.socialMedia:
        return 'Social Media';
    }
  }

  IconData get iconData {
    switch (this) {
      case QuestType.externalLink:
        return Icons.link;
      case QuestType.internalAction:
        return Icons.check_circle;
      case QuestType.socialMedia:
        return Icons.share;
    }
  }
}

enum QuestStatus {
  notStarted,
  inProgress,
  pendingVerification,
  completed,
}

extension QuestStatusExtension on QuestStatus {
  String get displayName {
    switch (this) {
      case QuestStatus.notStarted:
        return 'Not Started';
      case QuestStatus.inProgress:
        return 'In Progress';
      case QuestStatus.pendingVerification:
        return 'Pending Verification';
      case QuestStatus.completed:
        return 'Completed';
    }
  }

  int get color {
    switch (this) {
      case QuestStatus.notStarted:
        return 0xFF9E9E9E; // Gray
      case QuestStatus.inProgress:
        return 0xFF2196F3; // Blue
      case QuestStatus.pendingVerification:
        return 0xFFFF9800; // Orange
      case QuestStatus.completed:
        return 0xFF4CAF50; // Green
    }
  }
}

class UserQuestModel {
  const UserQuestModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.status,
    required this.progress,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.quest,
  });

  final String id;
  final String userId;
  final String questId;
  final QuestStatus status;
  final int progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final QuestModel quest;

  factory UserQuestModel.fromApi(Map<String, dynamic> json) {
    final questMap = _asStringKeyMap(json['quest']);
    return UserQuestModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      questId: json['questId']?.toString() ?? '',
      status: _questStatusFromApi(json['status']),
      progress: int.tryParse(json['progress']?.toString() ?? '') ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      quest: QuestModel.fromApi(questMap),
    );
  }
}

class UserQuestsResponse {
  const UserQuestsResponse({
    required this.quests,
    required this.totalCount,
    required this.completedCount,
    required this.inProgressCount,
  });

  final List<UserQuestModel> quests;
  final int totalCount;
  final int completedCount;
  final int inProgressCount;

  factory UserQuestsResponse.fromApi(Map<String, dynamic> json) {
    final rawQuests = json['quests'];
    final questsList = rawQuests is List ? rawQuests : const [];
    return UserQuestsResponse(
      quests: questsList
          .whereType<Map>()
          .map((entry) => UserQuestModel.fromApi(_asStringKeyMap(entry)))
          .toList(),
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      completedCount:
          int.tryParse(json['completedCount']?.toString() ?? '') ?? 0,
      inProgressCount:
          int.tryParse(json['inProgressCount']?.toString() ?? '') ?? 0,
    );
  }
}

class QuestSubmissionModel {
  const QuestSubmissionModel({
    required this.id,
    required this.userQuestId,
    required this.userId,
    this.proofUrl,
    this.proofText,
    this.screenshot,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    required this.submittedAt,
  });

  final String id;
  final String userQuestId;
  final String userId;
  final String? proofUrl;
  final String? proofText;
  final String? screenshot;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime submittedAt;

  factory QuestSubmissionModel.fromApi(Map<String, dynamic> json) {
    return QuestSubmissionModel(
      id: json['id']?.toString() ?? '',
      userQuestId: json['userQuestId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      proofUrl: json['proofUrl']?.toString(),
      proofText: json['proofText']?.toString(),
      screenshot: json['screenshot']?.toString(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      verifiedBy: json['verifiedBy']?.toString(),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

QuestType _questTypeFromApi(Object? raw) {
  switch ((raw ?? '').toString()) {
    case 'external_link':
      return QuestType.externalLink;
    case 'social_media':
      return QuestType.socialMedia;
    case 'internal_action':
    default:
      return QuestType.internalAction;
  }
}

QuestStatus _questStatusFromApi(Object? raw) {
  switch ((raw ?? '').toString()) {
    case 'in_progress':
      return QuestStatus.inProgress;
    case 'pending_verification':
      return QuestStatus.pendingVerification;
    case 'completed':
      return QuestStatus.completed;
    case 'not_started':
    default:
      return QuestStatus.notStarted;
  }
}
