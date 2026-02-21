enum FollowAlertLevel {
  highOnly,
  highAndMid,
  all,
}

extension FollowAlertLevelX on FollowAlertLevel {
  String get wireValue {
    switch (this) {
      case FollowAlertLevel.highOnly:
        return 'high';
      case FollowAlertLevel.highAndMid:
        return 'medium';
      case FollowAlertLevel.all:
        return 'low';
    }
  }

  String get label {
    switch (this) {
      case FollowAlertLevel.highOnly:
        return 'High only';
      case FollowAlertLevel.highAndMid:
        return 'High + Medium';
      case FollowAlertLevel.all:
        return 'All';
    }
  }
}

FollowAlertLevel followAlertLevelFromWire(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'high':
      return FollowAlertLevel.highOnly;
    case 'medium':
      return FollowAlertLevel.highAndMid;
    case 'low':
    default:
      return FollowAlertLevel.all;
  }
}

class FollowPreference {
  const FollowPreference({
    required this.alertLevel,
    required this.mutedUntil,
  });

  final FollowAlertLevel alertLevel;
  final DateTime? mutedUntil;

  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now().toUtc());

  FollowPreference copyWith({
    FollowAlertLevel? alertLevel,
    DateTime? mutedUntil,
    bool clearMute = false,
  }) {
    return FollowPreference(
      alertLevel: alertLevel ?? this.alertLevel,
      mutedUntil: clearMute ? null : (mutedUntil ?? this.mutedUntil),
    );
  }

  factory FollowPreference.fromApi(Map<String, dynamic> json) {
    final mutedRaw = json['mutedUntil']?.toString();
    return FollowPreference(
      alertLevel: followAlertLevelFromWire(json['alertMinUrgency']?.toString()),
      mutedUntil: mutedRaw == null ? null : DateTime.tryParse(mutedRaw),
    );
  }
}
