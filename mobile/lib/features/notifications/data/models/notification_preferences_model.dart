class NotificationPreferenceCategoryCatalog {
  const NotificationPreferenceCategoryCatalog({
    required this.key,
    required this.label,
    required this.types,
  });

  final String key;
  final String label;
  final List<String> types;

  factory NotificationPreferenceCategoryCatalog.fromApi(
    Map<String, dynamic> json,
  ) {
    final rawTypes = json['types'];
    return NotificationPreferenceCategoryCatalog(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      types: rawTypes is List
          ? rawTypes.map((entry) => entry.toString()).toList()
          : const [],
    );
  }
}

class NotificationPreferencesCatalog {
  const NotificationPreferencesCatalog({
    required this.categories,
    required this.criticalTypes,
  });

  final List<NotificationPreferenceCategoryCatalog> categories;
  final List<String> criticalTypes;

  factory NotificationPreferencesCatalog.fromApi(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final rawCriticalTypes = json['criticalTypes'];

    return NotificationPreferencesCatalog(
      categories: rawCategories is List
          ? rawCategories
              .whereType<Map<String, dynamic>>()
              .map(NotificationPreferenceCategoryCatalog.fromApi)
              .toList()
          : const [],
      criticalTypes: rawCriticalTypes is List
          ? rawCriticalTypes.map((entry) => entry.toString()).toList()
          : const [],
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.masterEnabled,
    required this.digestEmailEnabled,
    required this.digestCadence,
    required this.digestHourLocal,
    required this.digestMinuteLocal,
    required this.timezone,
    required this.categories,
    required this.typeOverrides,
    required this.criticalTypes,
  });

  final bool masterEnabled;
  final bool digestEmailEnabled;
  final String digestCadence;
  final int digestHourLocal;
  final int digestMinuteLocal;
  final String timezone;
  final Map<String, bool> categories;
  final Map<String, bool> typeOverrides;
  final List<String> criticalTypes;

  bool isCategoryEnabled(String categoryKey) => categories[categoryKey] ?? true;

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? digestEmailEnabled,
    String? digestCadence,
    int? digestHourLocal,
    int? digestMinuteLocal,
    String? timezone,
    Map<String, bool>? categories,
    Map<String, bool>? typeOverrides,
    List<String>? criticalTypes,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      digestEmailEnabled: digestEmailEnabled ?? this.digestEmailEnabled,
      digestCadence: digestCadence ?? this.digestCadence,
      digestHourLocal: digestHourLocal ?? this.digestHourLocal,
      digestMinuteLocal: digestMinuteLocal ?? this.digestMinuteLocal,
      timezone: timezone ?? this.timezone,
      categories: categories ?? this.categories,
      typeOverrides: typeOverrides ?? this.typeOverrides,
      criticalTypes: criticalTypes ?? this.criticalTypes,
    );
  }

  factory NotificationPreferences.fromApi(Map<String, dynamic> json) {
    final categories = <String, bool>{};
    final typeOverrides = <String, bool>{};

    final rawCategories = json['categories'];
    if (rawCategories is Map) {
      for (final entry in rawCategories.entries) {
        categories[entry.key.toString()] = entry.value == true;
      }
    }

    final rawTypeOverrides = json['typeOverrides'];
    if (rawTypeOverrides is Map) {
      for (final entry in rawTypeOverrides.entries) {
        typeOverrides[entry.key.toString()] = entry.value == true;
      }
    }

    final rawCriticalTypes = json['criticalTypes'];

    return NotificationPreferences(
      masterEnabled: json['masterEnabled'] != false,
      digestEmailEnabled: json['digestEmailEnabled'] != false,
      digestCadence: (json['digestCadence'] ?? 'daily').toString(),
      digestHourLocal:
          int.tryParse(json['digestHourLocal']?.toString() ?? '') ?? 8,
      digestMinuteLocal:
          int.tryParse(json['digestMinuteLocal']?.toString() ?? '') ?? 0,
      timezone: (json['timezone'] ?? 'UTC').toString(),
      categories: categories,
      typeOverrides: typeOverrides,
      criticalTypes: rawCriticalTypes is List
          ? rawCriticalTypes.map((entry) => entry.toString()).toList()
          : const [],
    );
  }
}
