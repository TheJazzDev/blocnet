/// Referral models: the member's own summary, their friends, code checks.
library;

import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/shared/utils/user_level_parsing.dart';

class ReferrerSummary {
  const ReferrerSummary({
    required this.id,
    required this.username,
    required this.displayName,
    required this.code,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? code;

  factory ReferrerSummary.fromApi(Map<String, dynamic> json) {
    return ReferrerSummary(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      code: json['code']?.toString() ?? json['referralCode']?.toString(),
    );
  }
}

class ReferralSummaryModel {
  const ReferralSummaryModel({
    required this.code,
    required this.referredBy,
    required this.canBindUntil,
    required this.bindWindowOpen,
    required this.activeDirectReferrals,
    required this.totalDirectReferrals,
  });

  final String? code;
  final ReferrerSummary? referredBy;
  final DateTime? canBindUntil;
  final bool bindWindowOpen;
  final int activeDirectReferrals;
  final int totalDirectReferrals;

  bool get isBound => referredBy != null;

  factory ReferralSummaryModel.fromApi(Map<String, dynamic> json) {
    final referredByRaw = json['referredBy'];
    return ReferralSummaryModel(
      code: json['code']?.toString(),
      referredBy: referredByRaw is Map<String, dynamic>
          ? ReferrerSummary.fromApi(referredByRaw)
          : null,
      canBindUntil: DateTime.tryParse(json['canBindUntil']?.toString() ?? ''),
      bindWindowOpen: json['bindWindowOpen'] == true,
      activeDirectReferrals:
          int.tryParse(json['activeDirectReferrals']?.toString() ?? '') ?? 0,
      totalDirectReferrals:
          int.tryParse(json['totalDirectReferrals']?.toString() ?? '') ?? 0,
    );
  }
}

class DownlineMember {
  const DownlineMember({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.status,
    required this.isActive,
    required this.progressPct,
    required this.claimedTotalPoints,
    required this.referredAt,
    required this.lastActiveAt,
    this.currentLevel,
  });

  final String id;
  final String? email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final UserLevelModel? currentLevel;
  final String status;
  final bool isActive;
  final double progressPct;
  final int claimedTotalPoints;
  final DateTime? referredAt;
  final DateTime? lastActiveAt;

  factory DownlineMember.fromApi(Map<String, dynamic> json) {
    return DownlineMember(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      status: json['status']?.toString() ?? 'idle',
      isActive: json['isActive'] == true,
      progressPct: double.tryParse(json['progressPct']?.toString() ?? '') ?? 0,
      claimedTotalPoints:
          int.tryParse(json['claimedTotalPoints']?.toString() ?? '') ?? 0,
      referredAt: DateTime.tryParse(json['referredAt']?.toString() ?? ''),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? ''),
      currentLevel: parseCurrentLevel(json['currentLevel']),
    );
  }
}

class DownlineResponse {
  const DownlineResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<DownlineMember> data;
  final int total;
  final int limit;
  final int offset;

  factory DownlineResponse.fromApi(Map<String, dynamic> json) {
    final rows = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DownlineMember.fromApi)
        .toList();

    return DownlineResponse(
      data: rows,
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? rows.length,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}

class ReferralValidation {
  const ReferralValidation({
    required this.valid,
    required this.code,
    required this.referrerName,
  });

  final bool valid;
  final String code;
  final String? referrerName;

  factory ReferralValidation.fromApi(Map<String, dynamic> json) {
    final referrer = (json['referrer'] as Map?)?.cast<String, dynamic>();
    return ReferralValidation(
      valid: json['valid'] == true,
      code: json['code']?.toString() ?? '',
      referrerName: referrer?['displayName']?.toString(),
    );
  }
}
